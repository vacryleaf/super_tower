extends "res://scripts/tests/test_base.gd"

const BattleContext = preload("res://scripts/core/battle/battle_context.gd")
const BattleModule = preload("res://scripts/core/battle/battle_module.gd")
const BattleModuleRegistry = preload("res://scripts/core/battle/battle_module_registry.gd")
const BattleStepResult = preload("res://scripts/core/battle/battle_step_result.gd")
const BattleTiming = preload("res://scripts/core/battle/battle_timing.gd")


class FixtureModule extends BattleModule:
	var supported_timings: Array[String] = []
	var priority_value: int = 0
	var result_kind: String = BattleStepResult.CONTINUE
	var calls: Array[String] = []

	func _init(timings: Array[String], order_value: int = 0, next_result: String = BattleStepResult.CONTINUE) -> void:
		supported_timings = timings.duplicate()
		priority_value = order_value
		result_kind = next_result

	func supports(timing: String) -> bool:
		return timing in supported_timings

	func priority(_timing: String) -> int:
		return priority_value

	func execute(timing: String, _context: RefCounted) -> RefCounted:
		calls.append(timing)
		return BattleStepResult.new(result_kind)


func run() -> void:
	test_known_timings_are_registered()
	test_registry_sorts_by_priority_then_registration_order()
	test_registry_rejects_invalid_and_duplicate_modules()
	test_dispatch_stops_after_skip_or_cancel()
	test_unknown_timing_returns_structured_error()


func test_known_timings_are_registered() -> void:
	assert_true(BattleTiming.is_known(BattleTiming.ROUND_START), "round start should be a known battle timing")
	assert_true(BattleTiming.is_known(BattleTiming.DAMAGE_APPLY), "damage apply should be a known battle timing")
	assert_true(not BattleTiming.is_known("unknown_timing"), "arbitrary timing should not be known")


func test_registry_sorts_by_priority_then_registration_order() -> void:
	var registry := BattleModuleRegistry.new()
	var second := FixtureModule.new([BattleTiming.ACTION_BEFORE], 10)
	var first := FixtureModule.new([BattleTiming.ACTION_BEFORE], 0)
	var same_priority := FixtureModule.new([BattleTiming.ACTION_BEFORE], 10)
	assert_true(registry.register(second), "registry should accept the first valid module")
	assert_true(registry.register(first), "registry should accept a lower priority module")
	assert_true(registry.register(same_priority), "registry should accept a same priority module")
	var modules := registry.modules_for(BattleTiming.ACTION_BEFORE)
	assert_equal(modules.size(), 3, "registry should return every matching module")
	assert_true(modules[0] == first, "lower numeric priority should run first")
	assert_true(modules[1] == second, "same priority modules should preserve registration order")
	assert_true(modules[2] == same_priority, "same priority modules should preserve registration order")


func test_registry_rejects_invalid_and_duplicate_modules() -> void:
	var registry := BattleModuleRegistry.new()
	var valid := FixtureModule.new([BattleTiming.BATTLE_START])
	assert_true(not registry.register(RefCounted.new()), "registry should reject modules without the battle module contract")
	assert_true(registry.register(valid), "registry should accept a valid module")
	assert_true(not registry.register(valid), "registry should reject duplicate module registration")
	assert_true(registry.unregister(valid), "registry should remove a registered module")
	assert_true(not registry.unregister(valid), "registry should report missing modules during unregister")


func test_dispatch_stops_after_skip_or_cancel() -> void:
	var context := BattleContext.new()
	var skip_registry := BattleModuleRegistry.new()
	var skip_module := FixtureModule.new([BattleTiming.ACTION_BEFORE], 0, BattleStepResult.SKIP)
	var skipped_module := FixtureModule.new([BattleTiming.ACTION_BEFORE], 10)
	skip_registry.register(skip_module)
	skip_registry.register(skipped_module)
	var skip_result: RefCounted = skip_registry.dispatch(BattleTiming.ACTION_BEFORE, context)
	assert_equal(String(skip_result.get("kind")), BattleStepResult.SKIP, "skip should become the dispatch result")
	assert_equal(skip_module.calls.size(), 1, "skip module should run once")
	assert_true(skipped_module.calls.is_empty(), "skip should stop later modules in the same timing")

	var cancel_registry := BattleModuleRegistry.new()
	var cancel_module := FixtureModule.new([BattleTiming.ACTION_VALIDATE], 0, BattleStepResult.CANCEL_ACTION)
	var cancelled_module := FixtureModule.new([BattleTiming.ACTION_VALIDATE], 10)
	cancel_registry.register(cancel_module)
	cancel_registry.register(cancelled_module)
	var cancel_result: RefCounted = cancel_registry.dispatch(BattleTiming.ACTION_VALIDATE, context)
	assert_equal(String(cancel_result.get("kind")), BattleStepResult.CANCEL_ACTION, "cancel should become the dispatch result")
	assert_true(cancelled_module.calls.is_empty(), "cancel should stop later modules in the same timing")


func test_unknown_timing_returns_structured_error() -> void:
	var registry := BattleModuleRegistry.new()
	var result: RefCounted = registry.dispatch("unknown_timing", BattleContext.new())
	assert_equal(String(result.get("kind")), BattleStepResult.ERROR, "unknown timing should return an error result")
	assert_equal(String(result.get("error_code")), "unknown_timing", "unknown timing should preserve its error code")
