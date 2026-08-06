extends RefCounted
class_name EffectDispatcher

const BattleStepResult = preload("res://scripts/core/battle/battle_step_result.gd")

var _executors: Dictionary = {}


func register(action_type: String, executor: RefCounted) -> bool:
	if action_type == "" or executor == null or not executor.has_method("execute"):
		return false
	if _executors.has(action_type):
		return false
	_executors[action_type] = executor
	return true


func unregister(action_type: String) -> bool:
	if not _executors.has(action_type):
		return false
	_executors.erase(action_type)
	return true


func has_executor(action_type: String) -> bool:
	return _executors.has(action_type)


func action_types() -> Array[String]:
	var result: Array[String] = []
	for action_type in _executors.keys():
		result.append(String(action_type))
	result.sort()
	return result


func dispatch(action: Dictionary, context: RefCounted) -> RefCounted:
	var action_type: String = String(action.get("type", ""))
	if action_type == "":
		return BattleStepResult.new(BattleStepResult.ERROR, "action type is missing", "missing_action_type")
	if not _executors.has(action_type):
		return BattleStepResult.new(BattleStepResult.ERROR, "action executor is not registered", "unknown_action_type", {"action_type": action_type})
	var executor: RefCounted = _executors[action_type]
	var result: Variant = executor.call("execute", action.duplicate(true), context)
	if result == null or not result is RefCounted:
		return BattleStepResult.new(BattleStepResult.ERROR, "effect executor returned an invalid result", "invalid_effect_result", {"action_type": action_type})
	var result_kind: String = String(result.get("kind"))
	if result_kind not in [BattleStepResult.CONTINUE, BattleStepResult.SKIP, BattleStepResult.CANCEL_ACTION, BattleStepResult.END_BATTLE, BattleStepResult.ERROR]:
		return BattleStepResult.new(BattleStepResult.ERROR, "effect executor returned an unknown result", "unknown_effect_result", {"action_type": action_type, "kind": result_kind})
	return result
