extends RefCounted
class_name BattleModuleRegistry

const BattleStepResult = preload("res://scripts/core/battle/battle_step_result.gd")
const BattleTiming = preload("res://scripts/core/battle/battle_timing.gd")

var _entries: Array[Dictionary] = []
var _next_registration_order: int = 0


func register(module: RefCounted) -> bool:
	if module == null:
		return false
	if not module.has_method("supports") or not module.has_method("priority") or not module.has_method("execute"):
		return false
	for entry in _entries:
		if entry["module"] == module:
			return false
	_entries.append({"module": module, "order": _next_registration_order})
	_next_registration_order += 1
	return true


func unregister(module: RefCounted) -> bool:
	for index in range(_entries.size()):
		if _entries[index]["module"] == module:
			_entries.remove_at(index)
			return true
	return false


func clear() -> void:
	_entries.clear()


func modules_for(timing: String) -> Array[RefCounted]:
	if not BattleTiming.is_known(timing):
		return []
	var selected_entries: Array[Dictionary] = []
	for entry in _entries:
		var module: RefCounted = entry["module"]
		if not bool(module.call("supports", timing)):
			continue
		selected_entries.append({
			"module": module,
			"priority": int(module.call("priority", timing)),
			"order": int(entry["order"])
		})
	selected_entries.sort_custom(Callable(self, "_entry_precedes"))
	var modules: Array[RefCounted] = []
	for entry in selected_entries:
		modules.append(entry["module"])
	return modules


func dispatch(timing: String, context: RefCounted) -> RefCounted:
	if not BattleTiming.is_known(timing):
		return BattleStepResult.new(BattleStepResult.ERROR, "unknown battle timing", "unknown_timing", {"timing": timing})
	var last_result: RefCounted = BattleStepResult.new(BattleStepResult.CONTINUE)
	for module in modules_for(timing):
		var result: Variant = module.call("execute", timing, context)
		if result == null:
			continue
		if not result is RefCounted:
			return BattleStepResult.new(BattleStepResult.ERROR, "battle module returned an invalid result", "invalid_result", {"timing": timing})
		var result_kind: String = String(result.get("kind"))
		if result_kind not in [BattleStepResult.CONTINUE, BattleStepResult.SKIP, BattleStepResult.CANCEL_ACTION, BattleStepResult.END_BATTLE, BattleStepResult.ERROR]:
			return BattleStepResult.new(BattleStepResult.ERROR, "battle module returned an unknown result", "unknown_result", {"timing": timing, "kind": result_kind})
		last_result = result
		if result_kind != BattleStepResult.CONTINUE:
			return result
	return last_result


func _entry_precedes(left: Dictionary, right: Dictionary) -> bool:
	var left_priority: int = int(left["priority"])
	var right_priority: int = int(right["priority"])
	if left_priority == right_priority:
		return int(left["order"]) < int(right["order"])
	return left_priority < right_priority
