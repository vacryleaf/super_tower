extends "res://scripts/tests/test_base.gd"

const BattleContext = preload("res://scripts/core/battle/battle_context.gd")
const BattleActionContext = preload("res://scripts/core/battle/battle_action_context.gd")
const BattleHitContext = preload("res://scripts/core/battle/battle_hit_context.gd")
const BattleStepResult = preload("res://scripts/core/battle/battle_step_result.gd")


func run() -> void:
	test_battle_context_does_not_require_session()
	test_battle_context_copies_queued_actions_and_events()
	test_action_context_preserves_chain_and_cancellation()
	test_hit_context_records_resolution_state()
	test_step_result_states()


func test_battle_context_does_not_require_session() -> void:
	var context := BattleContext.new(null, {"status_service": "fixture"}, "battle-fixture")
	assert_equal(context.context_id, "battle-fixture", "battle context should preserve explicit IDs")
	assert_true(context.battle_state == null, "battle context should construct without a PlaySession or BattleState")
	assert_equal(context.services["status_service"], "fixture", "battle context should preserve explicit service ports")
	assert_true(context.action_queue.is_empty(), "new battle context should start with an empty action queue")


func test_battle_context_copies_queued_actions_and_events() -> void:
	var context := BattleContext.new()
	var intent := {"kind": "skill", "skill_id": "fixture.skill"}
	context.enqueue_action(intent)
	intent["skill_id"] = "mutated.skill"
	var queued := context.dequeue_action()
	assert_equal(queued["skill_id"], "fixture.skill", "queued action should not alias caller data")
	assert_true(context.dequeue_action().is_empty(), "dequeueing an empty queue should return an empty dictionary")
	context.record_event("action_started", {"actor_id": "player"})
	assert_equal(context.events.size(), 1, "record_event should append one event")
	assert_equal(context.events[0]["kind"], "action_started", "record_event should store the event kind")
	context.cancel_current_action("fixture cancel")
	assert_true(context.is_action_cancelled(), "battle context should expose action cancellation")
	context.clear_action_cancellation()
	assert_true(not context.is_action_cancelled(), "battle context should clear action cancellation")


func test_action_context_preserves_chain_and_cancellation() -> void:
	var intent := {"source": "active_attack", "skill_id": "fixture.skill"}
	var context := BattleActionContext.new(intent, {"id": "player"}, "parent-action", "root-chain", "action-fixture")
	intent["skill_id"] = "mutated.skill"
	assert_equal(context.context_id, "action-fixture", "action context should preserve explicit IDs")
	assert_equal(context.parent_context_id, "parent-action", "action context should keep the parent ID")
	assert_equal(context.chain_id, "root-chain", "action context should preserve the inherited chain ID")
	assert_equal(context.intent["skill_id"], "fixture.skill", "action context should copy intent data")
	assert_equal(context.source, "active_attack", "action context should derive the source from intent")
	context.set_cost({"energy": 2})
	context.cancel("insufficient energy")
	assert_equal(context.cost["energy"], 2, "action context should preserve cost data")
	assert_true(context.cancelled, "action context should record cancellation")
	assert_equal(context.cancel_reason, "insufficient energy", "action context should preserve cancellation reason")


func test_hit_context_records_resolution_state() -> void:
	var context := BattleHitContext.new({"id": "player"}, {"id": "enemy"}, "active_attack", "action-fixture", "root-chain", "hit-fixture")
	context.base_damage = 10
	context.modified_damage = 12
	context.mark_dodged()
	assert_true(context.is_dodged, "hit context should record a dodge result")
	assert_equal(context.final_damage, 0, "a dodged hit should have no final damage")
	context.apply_damage_result(7, 3, 2, true)
	assert_equal(context.final_damage, 7, "hit context should record final damage")
	assert_equal(context.armor_reduced, 3, "hit context should record armor reduction")
	assert_equal(context.block_absorbed, 2, "hit context should record block absorption")
	assert_true(context.killed, "hit context should record kill state")
	assert_equal(context.parent_action_id, "action-fixture", "hit context should retain the parent action ID")


func test_step_result_states() -> void:
	var continued := BattleStepResult.new(BattleStepResult.CONTINUE, "", "", {"stage": "action"})
	assert_equal(continued.kind, BattleStepResult.CONTINUE, "step result should preserve continue state")
	assert_true(not continued.is_terminal(), "continue result should not be terminal")
	var skipped := BattleStepResult.new(BattleStepResult.SKIP, "condition failed")
	assert_equal(skipped.kind, BattleStepResult.SKIP, "step result should preserve skip state")
	var cancelled := BattleStepResult.new(BattleStepResult.CANCEL_ACTION, "no energy")
	assert_true(cancelled.is_terminal(), "cancel action result should be terminal for the current flow")
	var ended := BattleStepResult.new(BattleStepResult.END_BATTLE, "victory")
	assert_equal(ended.kind, BattleStepResult.END_BATTLE, "step result should preserve end state")
	var failed := BattleStepResult.new(BattleStepResult.ERROR, "unknown action", "invalid_action")
	assert_equal(failed.error_code, "invalid_action", "step result should preserve structured error codes")
	assert_true(failed.is_terminal(), "error result should be terminal")
