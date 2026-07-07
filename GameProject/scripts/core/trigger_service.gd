extends RefCounted
class_name TriggerService

const TriggerEvents = preload("res://scripts/core/trigger_events.gd")
const Combatant = preload("res://scripts/core/combatant.gd")

var status_service = null


func fire_trigger(target: Dictionary, event: String, context: Dictionary) -> void:
	if not target.has("statuses"):
		return
	var statuses: Array = target["statuses"]
	for status in statuses:
		for trigger in status.get("triggers", []):
			if String(trigger.get("event", "")) != event:
				continue
			if trigger.has("condition"):
				if not status_service.evaluate_condition(target, trigger["condition"], context):
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
			if not status_to_apply.is_empty() and status_service != null:
				status_service.add_status(target, status_to_apply)
		TriggerEvents.ACTION_REMOVE_STATUS:
			var remove_id := String(action.get("status_id", ""))
			if remove_id != "" and status_service != null:
				status_service.remove_status(target, remove_id)
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
		TriggerEvents.ACTION_RANGER_PURSUIT:
			if session != null:
				var hit_count := int(session.get_counter("ranger_hit_count"))
				if hit_count > 0 and not context.get("target", {}).is_empty():
					var enemy_target: Dictionary = context.get("target", {})
					if int(enemy_target.get("hp", 0)) > 0:
						var result := Combatant.apply_damage(enemy_target, hit_count, "true")
						battle_log.append("追击：追加 %d 点伤害。" % int(result["damage"]))


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