extends RefCounted
class_name SkillEffectModule

const BattleStepResult = preload("res://scripts/core/battle/battle_step_result.gd")
const ConditionEvaluator = preload("res://scripts/core/condition_evaluator.gd")
const SkillActionService = preload("res://scripts/core/skill_action_service.gd")

var dispatcher: RefCounted
var condition_evaluator: RefCounted


func _init(initial_dispatcher: RefCounted, initial_condition_evaluator: RefCounted = null) -> void:
	dispatcher = initial_dispatcher
	condition_evaluator = initial_condition_evaluator if initial_condition_evaluator != null else ConditionEvaluator.new()


func execute_skill(skill: Dictionary, context: RefCounted) -> RefCounted:
	if skill.is_empty():
		return BattleStepResult.new(BattleStepResult.ERROR, "skill definition is empty", "empty_skill")
	if context == null:
		return BattleStepResult.new(BattleStepResult.ERROR, "skill context is missing", "missing_skill_context")
	if context.has_method("set_skill"):
		context.call("set_skill", skill)
	for action in SkillActionService.actions(skill):
		if not _conditions_met(action, context):
			continue
		if context.has_method("set_action"):
			context.call("set_action", action)
		var result: RefCounted = dispatcher.call("dispatch", action, context)
		if String(result.get("kind")) != BattleStepResult.CONTINUE:
			return result
	return BattleStepResult.new(BattleStepResult.CONTINUE)


func _conditions_met(action: Dictionary, context: RefCounted) -> bool:
	var raw_conditions: Variant = action.get("conditions", [])
	var conditions: Array = raw_conditions if typeof(raw_conditions) == TYPE_ARRAY else []
	if conditions.is_empty() and action.has("condition"):
		conditions = [action.get("condition", {})]
	if conditions.is_empty():
		return true
	var actor: Dictionary = context.get("actor")
	var condition_context: Dictionary = _condition_context(context)
	for condition in conditions:
		if typeof(condition) != TYPE_DICTIONARY:
			return false
		if not bool(condition_evaluator.call("evaluate", actor, condition, condition_context)):
			return false
	return true


func _condition_context(context: RefCounted) -> Dictionary:
	var condition_context: Dictionary = {}
	var intent: Dictionary = context.get("intent")
	var metadata: Dictionary = intent.get("metadata", {})
	condition_context.merge(metadata.duplicate(true), true)
	condition_context["source"] = context.get("actor")
	var target_selection: Dictionary = context.get("target_selection")
	condition_context["target"] = target_selection.get("unit", {})
	return condition_context
