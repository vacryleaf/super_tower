extends "res://scripts/tests/test_base.gd"

const BattleActionContext = preload("res://scripts/core/battle/battle_action_context.gd")
const BattleStepResult = preload("res://scripts/core/battle/battle_step_result.gd")
const EffectDispatcher = preload("res://scripts/core/battle/skill/effect_dispatcher.gd")
const EffectExecutor = preload("res://scripts/core/battle/skill/effect_executor.gd")
const SkillEffectModule = preload("res://scripts/core/battle/skill/skill_effect_module.gd")


class FixtureExecutor extends EffectExecutor:
	var calls: Array[Dictionary] = []
	var result_kind: String = BattleStepResult.CONTINUE

	func execute(action: Dictionary, _context: RefCounted) -> RefCounted:
		calls.append(action.duplicate(true))
		return BattleStepResult.new(result_kind)


func run() -> void:
	test_dispatcher_registers_and_routes_actions()
	test_dispatcher_rejects_unknown_or_invalid_actions()
	test_skill_effect_module_applies_conditions_before_dispatch()
	test_skill_effect_module_stops_on_executor_result()


func test_dispatcher_registers_and_routes_actions() -> void:
	var dispatcher := EffectDispatcher.new()
	var executor := FixtureExecutor.new()
	assert_true(dispatcher.register("fixture_action", executor), "dispatcher should register a valid executor")
	assert_true(dispatcher.has_executor("fixture_action"), "dispatcher should expose registered action types")
	var result: RefCounted = dispatcher.dispatch({"type": "fixture_action", "value": 3}, BattleActionContext.new())
	assert_equal(String(result.get("kind")), BattleStepResult.CONTINUE, "dispatcher should return executor results")
	assert_equal(executor.calls.size(), 1, "dispatcher should invoke the matching executor once")
	assert_equal(executor.calls[0]["value"], 3, "dispatcher should pass a copied action to the executor")
	assert_equal(dispatcher.action_types(), ["fixture_action"], "dispatcher should expose sorted registered action types")
	assert_true(dispatcher.unregister("fixture_action"), "dispatcher should unregister an executor")
	assert_true(not dispatcher.has_executor("fixture_action"), "unregistered action should no longer be available")


func test_dispatcher_rejects_unknown_or_invalid_actions() -> void:
	var dispatcher := EffectDispatcher.new()
	assert_true(not dispatcher.register("", FixtureExecutor.new()), "dispatcher should reject an empty action type")
	assert_true(not dispatcher.register("invalid", RefCounted.new()), "dispatcher should reject an invalid executor")
	var missing: RefCounted = dispatcher.dispatch({}, BattleActionContext.new())
	assert_equal(String(missing.get("error_code")), "missing_action_type", "missing action type should be structured")
	var unknown: RefCounted = dispatcher.dispatch({"type": "unknown"}, BattleActionContext.new())
	assert_equal(String(unknown.get("error_code")), "unknown_action_type", "unknown action should be structured")


func test_skill_effect_module_applies_conditions_before_dispatch() -> void:
	var dispatcher := EffectDispatcher.new()
	var executor := FixtureExecutor.new()
	dispatcher.register("fixture_action", executor)
	var skill_module := SkillEffectModule.new(dispatcher)
	var context := BattleActionContext.new({}, {"hp": 40, "max_hp": 100, "statuses": []})
	var skill := {
		"id": "fixture.skill",
		"actions": [
			{"type": "fixture_action", "conditions": [{"stat": "hp", "operator": "lt", "value": 50}]},
			{"type": "fixture_action", "conditions": [{"stat": "hp", "operator": "gt", "value": 90}]}
		]
	}
	var result: RefCounted = skill_module.execute_skill(skill, context)
	assert_equal(String(result.get("kind")), BattleStepResult.CONTINUE, "skill effect module should complete after conditional actions")
	assert_equal(executor.calls.size(), 1, "skill effect module should skip actions whose conditions fail")
	assert_equal(context.get("skill")["id"], "fixture.skill", "skill effect module should place the skill in the action context")
	assert_equal(context.get("action")["type"], "fixture_action", "skill effect module should place the latest action in the context")


func test_skill_effect_module_stops_on_executor_result() -> void:
	var dispatcher := EffectDispatcher.new()
	var executor := FixtureExecutor.new()
	executor.result_kind = BattleStepResult.CANCEL_ACTION
	dispatcher.register("fixture_action", executor)
	var skill_module := SkillEffectModule.new(dispatcher)
	var skill := {"actions": [{"type": "fixture_action"}, {"type": "fixture_action"}]}
	var result: RefCounted = skill_module.execute_skill(skill, BattleActionContext.new())
	assert_equal(String(result.get("kind")), BattleStepResult.CANCEL_ACTION, "skill effect module should return executor cancellation")
	assert_equal(executor.calls.size(), 1, "skill effect module should stop after a non-continue executor result")
