extends RefCounted
class_name StatusService

const ConditionEvaluator = preload("res://scripts/core/condition_evaluator.gd")
const TriggerEvents = preload("res://scripts/core/trigger_events.gd")
const Combatant = preload("res://scripts/core/combatant.gd")

const STAT_ATTACK := "attack"
const STAT_DAMAGE_TAKEN := "damage_taken"
const STAT_DEFENSE := "defense"
const STAT_BLOCK_POWER := "block_power"
const STAT_DODGE := "dodge"
const STAT_HEAL := "heal"
const STAT_MAX_HP := "max_hp"
const STAT_ACTION_COST := "action_cost"
const STAT_RESIST_PREFIX := "resist_"

const EFFECT_FLAT := "flat"
const EFFECT_PERCENT := "percent"
const EFFECT_MULTIPLY := "multiply"


func add_status(target: Dictionary, status: Dictionary) -> void:
	if not target.has("statuses"):
		target["statuses"] = []
	var statuses: Array = target["statuses"]
	var status_id := String(status.get("id", ""))
	var stack_mode := String(status.get("stack", "replace"))
	if stack_mode == "replace":
		for i in range(statuses.size() - 1, -1, -1):
			if String(statuses[i].get("id", "")) == status_id:
				statuses.remove_at(i)
	statuses.append(status.duplicate(true))


func remove_status(target: Dictionary, status_id: String) -> void:
	if not target.has("statuses"):
		return
	var statuses: Array = target["statuses"]
	for i in range(statuses.size() - 1, -1, -1):
		if String(statuses[i].get("id", "")) == status_id:
			statuses.remove_at(i)


func clear_buffs(target: Dictionary) -> void:
	_clear_by_kind(target, "buff")


func clear_debuffs(target: Dictionary) -> void:
	_clear_by_kind(target, "debuff")


func tick_statuses(target: Dictionary) -> void:
	if not target.has("statuses"):
		return
	var statuses: Array = target["statuses"]
	for i in range(statuses.size() - 1, -1, -1):
		var duration := int(statuses[i].get("duration", -1))
		if duration < 0:
			continue
		if duration <= 1:
			statuses.remove_at(i)
		else:
			statuses[i]["duration"] = duration - 1


func resolve_stat(target: Dictionary, base_value: float, stat_key: String, context: Dictionary = {}) -> float:
	if not target.has("statuses"):
		return base_value
	var flat_sum := 0.0
	var percent_product := 1.0
	var multiply_product := 1.0
	for status in target["statuses"]:
		for effect in status.get("effects", []):
			if String(effect.get("stat", "")) != stat_key:
				continue
			match String(effect.get("type", "")):
				EFFECT_FLAT:
					flat_sum += float(effect.get("value", 0.0))
				EFFECT_PERCENT:
					percent_product *= 1.0 + float(effect.get("value", 0.0))
				EFFECT_MULTIPLY:
					multiply_product *= float(effect.get("value", 1.0))
		for cond_effect in status.get("conditional_effects", []):
			if not evaluate_condition(target, cond_effect.get("condition", {}), context):
				continue
			for effect in cond_effect.get("effects", []):
				if String(effect.get("stat", "")) != stat_key:
					continue
				match String(effect.get("type", "")):
					EFFECT_FLAT:
						flat_sum += float(effect.get("value", 0.0))
					EFFECT_PERCENT:
						percent_product *= 1.0 + float(effect.get("value", 0.0))
					EFFECT_MULTIPLY:
						multiply_product *= float(effect.get("value", 1.0))
	return (base_value + flat_sum) * percent_product * multiply_product

func evaluate_condition(target: Dictionary, condition: Dictionary, context: Dictionary) -> bool:
	return ConditionEvaluator.new().evaluate(target, condition, context)


func fire_trigger(target: Dictionary, event: String, context: Dictionary) -> void:
	if not target.has("statuses"):
		return
	var statuses: Array = target["statuses"]
	for status in statuses:
		for trigger in status.get("triggers", []):
			if String(trigger.get("event", "")) != event:
				continue
			if trigger.has("condition"):
				if not evaluate_condition(target, trigger["condition"], context):
					continue
			for action in trigger.get("actions", []):
				_execute_action(target, action, context)


func _execute_action(target: Dictionary, action: Dictionary, context: Dictionary) -> void:
	var action_type := String(action.get("type", ""))
	var battle_log: Array[String] = context.get("battle_log", [])
	var session = context.get("session")
	match action_type:
		TriggerEvents.ACTION_DOT:
			var dot_value := _resolve_action_value(action, context)
			if dot_value > 0 and session != null:
				target["hp"] = maxi(0, int(target.get("hp", 0)) - dot_value)
				battle_log.append("%s 受到 %d 点持续伤害。" % [String(target.get("name", "")), dot_value])
		TriggerEvents.ACTION_HOT:
			var hot_value := _resolve_action_value(action, context)
			if hot_value > 0:
				target["hp"] = mini(int(target.get("max_hp", target.get("hp", 1))), int(target.get("hp", 0)) + hot_value)
				battle_log.append("%s 恢复 %d 点生命。" % [String(target.get("name", "")), hot_value])
		TriggerEvents.ACTION_REFLECT:
			var reflect_value := _resolve_action_value(action, context)
			var source: Dictionary = context.get("source", {})
			if reflect_value > 0 and not source.is_empty():
				source["hp"] = maxi(0, int(source.get("hp", 0)) - reflect_value)
				battle_log.append("%s 反弹 %d 点伤害。" % [String(target.get("name", "")), reflect_value])
		TriggerEvents.ACTION_LIFESTEAL:
			var lifesteal_value := _resolve_action_value(action, context)
			if lifesteal_value > 0:
				target["hp"] = mini(int(target.get("max_hp", target.get("hp", 1))), int(target.get("hp", 0)) + lifesteal_value)
				battle_log.append("%s 吸取 %d 点生命。" % [String(target.get("name", "")), lifesteal_value])
		TriggerEvents.ACTION_GAIN_BLOCK:
			var block_value := _resolve_action_value(action, context)
			if block_value > 0:
				target["block"] = int(target.get("block", 0)) + block_value
				battle_log.append("%s 获得 %d 点格挡。" % [String(target.get("name", "")), block_value])
		TriggerEvents.ACTION_GAIN_DODGE:
			var dodge_value := maxi(1, int(action.get("value", 1)))
			target["dodge_layers"] = int(target.get("dodge_layers", 0)) + dodge_value
			battle_log.append("%s 获得 %d 层躲避。" % [String(target.get("name", "")), dodge_value])
		TriggerEvents.ACTION_HEAL:
			var heal_value := _resolve_action_value(action, context)
			if heal_value > 0:
				target["hp"] = mini(int(target.get("max_hp", target.get("hp", 1))), int(target.get("hp", 0)) + heal_value)
				battle_log.append("%s 恢复 %d 点生命。" % [String(target.get("name", "")), heal_value])
		TriggerEvents.ACTION_APPLY_STATUS:
			var status_to_apply: Dictionary = action.get("status", {})
			if not status_to_apply.is_empty():
				add_status(target, status_to_apply)
		TriggerEvents.ACTION_REMOVE_STATUS:
			var remove_id := String(action.get("status_id", ""))
			if remove_id != "":
				remove_status(target, remove_id)
		TriggerEvents.ACTION_EXTRA_DAMAGE:
			var extra_value := _resolve_action_value(action, context)
			if extra_value > 0 and session != null:
				var dmg_type := String(action.get("damage_type", "physical"))
				var result := Combatant.apply_damage(target, extra_value, dmg_type)
				battle_log.append("%s 受到 %d 点额外伤害。" % [String(target.get("name", "")), int(result["damage"])])
		TriggerEvents.ACTION_COUNTER_ALL:
			var threshold := int(action.get("threshold", 2))
			if session != null and int(session.dodge_streak) >= threshold:
				session.dodge_streak = 0
				var dmg_value := _resolve_action_value(action, context)
				if dmg_value > 0:
					for enemy in session.enemies:
						if int(enemy.get("hp", 0)) <= 0:
							continue
						var result := Combatant.apply_damage(enemy, dmg_value, "physical")
						battle_log.append("%s 受到 %d 点表演伤害。" % [String(enemy.get("name", "")), int(result["damage"])])
		TriggerEvents.ACTION_INCREMENT_COUNTER:
			var counter_name := String(action.get("counter", ""))
			var max_val := int(action.get("max", 999))
			if counter_name != "" and session != null:
				var current := int(session.get_counter(counter_name))
				session.set_counter(counter_name, mini(current + 1, max_val))
		TriggerEvents.ACTION_RESET_COUNTER:
			var counter_name := String(action.get("counter", ""))
			if counter_name != "" and session != null:
				session.set_counter(counter_name, 0)


func _resolve_action_value(action: Dictionary, context: Dictionary) -> int:
	if action.has("value"):
		return maxi(0, int(action.get("value", 0)))
	var source_stat := String(action.get("source_stat", ""))
	var source_ratio := float(action.get("source_ratio", 0.0))
	var source: Dictionary = context.get("source", {})
	if source_stat != "" and source_ratio > 0.0 and not source.is_empty():
		return maxi(1, int(round(float(source.get(source_stat, 0)) * source_ratio)))
	var target_stat := String(action.get("target_stat", ""))
	var target_ratio := float(action.get("target_ratio", 0.0))
	var ctx_target: Dictionary = context.get("target", {})
	if target_stat != "" and target_ratio > 0.0 and not ctx_target.is_empty():
		return maxi(1, int(round(float(ctx_target.get(target_stat, 0)) * target_ratio)))
	return 0


func _clear_by_kind(target: Dictionary, kind: String) -> void:
	if not target.has("statuses"):
		return
	var statuses: Array = target["statuses"]
	for i in range(statuses.size() - 1, -1, -1):
		if String(statuses[i].get("kind", "")) == kind:
			statuses.remove_at(i)