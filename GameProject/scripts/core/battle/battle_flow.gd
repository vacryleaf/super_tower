extends RefCounted
class_name BattleFlow

const BattleModuleRegistry = preload("res://scripts/core/battle/battle_module_registry.gd")
const BattleStepResult = preload("res://scripts/core/battle/battle_step_result.gd")
const BattleTiming = preload("res://scripts/core/battle/battle_timing.gd")

var module_registry: RefCounted
var nested_actions: Array[RefCounted] = []


func _init(registry: RefCounted = null) -> void:
	module_registry = registry if registry != null else BattleModuleRegistry.new()


func register_module(module: RefCounted) -> bool:
	return bool(module_registry.call("register", module))


func unregister_module(module: RefCounted) -> bool:
	return bool(module_registry.call("unregister", module))


func dispatch_timing(timing: String, context: RefCounted) -> RefCounted:
	return module_registry.call("dispatch", timing, context)


func start_battle(context: RefCounted) -> RefCounted:
	return _dispatch_sequence([BattleTiming.BATTLE_PREPARE, BattleTiming.BATTLE_START], context)


func run_round(context: RefCounted) -> RefCounted:
	return _dispatch_sequence([
		BattleTiming.ROUND_START_BEFORE,
		BattleTiming.ROUND_START,
		BattleTiming.ROUND_START_AFTER,
		BattleTiming.ROUND_END_BEFORE,
		BattleTiming.ROUND_END
	], context)


func submit_action(action_context: RefCounted, battle_context: RefCounted = null) -> RefCounted:
	var flow_context: RefCounted = battle_context if battle_context != null else action_context
	return _dispatch_sequence([
		BattleTiming.ACTION_BEFORE,
		BattleTiming.ACTION_VALIDATE,
		BattleTiming.ACTION_START,
		BattleTiming.ACTION_EXECUTE,
		BattleTiming.ACTION_AFTER,
		BattleTiming.TURN_END
	], flow_context)


func execute_skill(action_context: RefCounted) -> RefCounted:
	return _dispatch_sequence([
		BattleTiming.SKILL_BEFORE,
		BattleTiming.SKILL_EFFECT_BEFORE,
		BattleTiming.SKILL_EFFECT,
		BattleTiming.SKILL_EFFECT_AFTER,
		BattleTiming.SKILL_AFTER
	], action_context)


func resolve_hit(hit_context: RefCounted) -> RefCounted:
	var result: RefCounted = dispatch_timing(BattleTiming.HIT_BEFORE, hit_context)
	if _is_non_continue(result):
		return result
	result = dispatch_timing(BattleTiming.DODGE_CHECK, hit_context)
	if _is_non_continue(result):
		return result
	if bool(hit_context.get("is_dodged")):
		result = dispatch_timing(BattleTiming.DODGE, hit_context)
		if _is_non_continue(result):
			return result
		return dispatch_timing(BattleTiming.HIT_AFTER, hit_context)
	return _dispatch_sequence([
		BattleTiming.HIT_CONFIRMED,
		BattleTiming.DAMAGE_BEFORE,
		BattleTiming.DAMAGE_APPLY,
		BattleTiming.DAMAGE_AFTER,
		BattleTiming.HIT_AFTER
	], hit_context)


func enqueue_nested_action(action_context: RefCounted) -> bool:
	if action_context == null:
		return false
	nested_actions.append(action_context)
	return true


func dequeue_nested_action() -> RefCounted:
	if nested_actions.is_empty():
		return null
	var action_context: RefCounted = nested_actions[0]
	nested_actions.remove_at(0)
	return action_context


func finish_battle(context: RefCounted) -> RefCounted:
	return dispatch_timing(BattleTiming.BATTLE_END, context)


func _dispatch_sequence(timings: Array[String], context: RefCounted) -> RefCounted:
	var result: RefCounted = BattleStepResult.new(BattleStepResult.CONTINUE)
	for timing in timings:
		result = dispatch_timing(timing, context)
		if _is_non_continue(result):
			return result
	return result


func _is_non_continue(result: RefCounted) -> bool:
	return String(result.get("kind")) != BattleStepResult.CONTINUE
