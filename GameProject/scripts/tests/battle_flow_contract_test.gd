extends "res://scripts/tests/test_base.gd"

const BattleActionContext = preload("res://scripts/core/battle/battle_action_context.gd")
const BattleContext = preload("res://scripts/core/battle/battle_context.gd")
const BattleFlow = preload("res://scripts/core/battle/battle_flow.gd")
const BattleHitContext = preload("res://scripts/core/battle/battle_hit_context.gd")
const BattleModule = preload("res://scripts/core/battle/battle_module.gd")
const BattleService = preload("res://scripts/core/battle_service.gd")
const BattleStepResult = preload("res://scripts/core/battle/battle_step_result.gd")
const BattleTiming = preload("res://scripts/core/battle/battle_timing.gd")


class RecorderModule extends BattleModule:
	var timings: Array[String] = []
	var stop_timing: String = ""
	var stop_kind: String = BattleStepResult.CONTINUE
	var mark_dodge_on_timing: String = ""

	func supports(_timing: String) -> bool:
		return true

	func execute(timing: String, context: RefCounted) -> RefCounted:
		timings.append(timing)
		if timing == mark_dodge_on_timing and context.has_method("mark_dodged"):
			context.call("mark_dodged")
		if timing == stop_timing:
			return BattleStepResult.new(stop_kind)
		return BattleStepResult.new(BattleStepResult.CONTINUE)


func run() -> void:
	test_start_and_round_sequence()
	test_action_sequence_stops_on_cancel()
	test_skill_sequence_is_explicit()
	test_dodge_path_skips_damage_timings()
	test_nested_action_queue_is_independent()
	test_battle_service_exposes_compatibility_flow_entry()


func test_start_and_round_sequence() -> void:
	var recorder := RecorderModule.new()
	var flow := BattleFlow.new()
	flow.register_module(recorder)
	var context := BattleContext.new()
	flow.start_battle(context)
	flow.run_round(context)
	assert_equal(recorder.timings, [
		BattleTiming.BATTLE_PREPARE,
		BattleTiming.BATTLE_START,
		BattleTiming.ROUND_START_BEFORE,
		BattleTiming.ROUND_START,
		BattleTiming.ROUND_START_AFTER,
		BattleTiming.ROUND_END_BEFORE,
		BattleTiming.ROUND_END
	], "battle flow should preserve battle and round timing order")


func test_action_sequence_stops_on_cancel() -> void:
	var recorder := RecorderModule.new()
	recorder.stop_timing = BattleTiming.ACTION_VALIDATE
	recorder.stop_kind = BattleStepResult.CANCEL_ACTION
	var flow := BattleFlow.new()
	flow.register_module(recorder)
	var result: RefCounted = flow.submit_action(BattleActionContext.new())
	assert_equal(String(result.get("kind")), BattleStepResult.CANCEL_ACTION, "cancel should be returned from submit_action")
	assert_equal(recorder.timings, [BattleTiming.ACTION_BEFORE, BattleTiming.ACTION_VALIDATE], "cancel should stop later action timings")


func test_skill_sequence_is_explicit() -> void:
	var recorder := RecorderModule.new()
	var flow := BattleFlow.new()
	flow.register_module(recorder)
	flow.execute_skill(BattleActionContext.new())
	assert_equal(recorder.timings, [
		BattleTiming.SKILL_BEFORE,
		BattleTiming.SKILL_EFFECT_BEFORE,
		BattleTiming.SKILL_EFFECT,
		BattleTiming.SKILL_EFFECT_AFTER,
		BattleTiming.SKILL_AFTER
	], "skill flow should expose each skill timing in order")


func test_dodge_path_skips_damage_timings() -> void:
	var recorder := RecorderModule.new()
	recorder.mark_dodge_on_timing = BattleTiming.DODGE_CHECK
	var flow := BattleFlow.new()
	flow.register_module(recorder)
	var result: RefCounted = flow.resolve_hit(BattleHitContext.new())
	assert_equal(String(result.get("kind")), BattleStepResult.CONTINUE, "dodge path should complete after hit cleanup")
	assert_equal(recorder.timings, [
		BattleTiming.HIT_BEFORE,
		BattleTiming.DODGE_CHECK,
		BattleTiming.DODGE,
		BattleTiming.HIT_AFTER
	], "dodged hit should skip confirmed hit and damage timings")


func test_nested_action_queue_is_independent() -> void:
	var flow := BattleFlow.new()
	var action_context := BattleActionContext.new()
	assert_true(flow.enqueue_nested_action(action_context), "flow should accept a nested action context")
	assert_true(flow.dequeue_nested_action() == action_context, "flow should return the queued nested action")
	assert_true(flow.dequeue_nested_action() == null, "empty nested action queue should return null")
	assert_true(not flow.enqueue_nested_action(null), "flow should reject a null nested action")


func test_battle_service_exposes_compatibility_flow_entry() -> void:
	var service := BattleService.new()
	var result: RefCounted = service.dispatch_battle_timing(BattleTiming.BATTLE_START, BattleContext.new())
	assert_equal(String(result.get("kind")), BattleStepResult.CONTINUE, "BattleService compatibility entry should delegate to BattleFlow")
