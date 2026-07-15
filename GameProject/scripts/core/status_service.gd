extends RefCounted
class_name StatusService

const ConditionEvaluator = preload("res://scripts/core/condition_evaluator.gd")
const TriggerService = preload("res://scripts/core/trigger_service.gd")

const STAT_ATTACK := "attack"
const STAT_DAMAGE_TAKEN := "damage_taken"
const STAT_DEFENSE := "defense"
const STAT_BLOCK_POWER := "block_power"
const STAT_DODGE := "dodge"
const STAT_HEAL := "heal"
const STAT_MAX_HP := "max_hp"
const STAT_ACTION_COST := "action_cost"
const STAT_ARMOR := "armor"
const STAT_EXTRA_HITS := "extra_hits"
const STAT_ENERGY_COST := "energy_cost"
const STAT_COOLDOWN := "cooldown"
const STAT_RESIST_PREFIX := "resist_"

const EFFECT_FLAT := "flat"
const EFFECT_PERCENT := "percent"
const EFFECT_MULTIPLY := "multiply"

var trigger_service := TriggerService.new()
var condition_evaluator := ConditionEvaluator.new()


func _init() -> void:
	trigger_service.status_service = self


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
	return condition_evaluator.evaluate(target, condition, context)


func fire_trigger(target: Dictionary, event: String, context: Dictionary) -> void:
	trigger_service.fire_trigger(target, event, context)


func _clear_by_kind(target: Dictionary, kind: String) -> void:
	if not target.has("statuses"):
		return
	var statuses: Array = target["statuses"]
	for i in range(statuses.size() - 1, -1, -1):
		if String(statuses[i].get("kind", "")) == kind:
			statuses.remove_at(i)
