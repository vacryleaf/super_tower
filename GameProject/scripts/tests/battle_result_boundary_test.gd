extends "res://scripts/tests/test_base.gd"

const TestHelpers = preload("res://scripts/tests/test_helpers.gd")


func run() -> void:
	test_victory_when_all_enemies_defeated()
	test_defeat_when_player_dies()
	test_no_result_while_battle_running()
	test_victory_callback_goes_through_run_layer()
	test_defeat_callback_formal_battle()
	test_tutorial_defeat_restarts()
	test_duplicate_settlement_is_idempotent()


func _session() -> RefCounted:
	var session := PlaySession.new()
	session.delete_save()
	session.start_new_game("warrior")
	return session


# 切到正式战斗：教程完成标记 + 非教程模式后重新开始当前战斗。
func _formal_session() -> RefCounted:
	var session := _session()
	session.player["tutorial_completed"] = true
	session.tutorial_active = false
	session.floor_index = 2
	session.battle_index = 1
	session.floor_group_id = ""
	session._start_current_battle()
	return session


func _kill_all_enemies(session: RefCounted) -> void:
	for enemy in session.enemies:
		enemy["hp"] = 0


func test_victory_when_all_enemies_defeated() -> void:
	var session := _session()
	_kill_all_enemies(session)
	var result: RefCounted = session.battle_result.judge(session)
	assert_true(result != null, "finished battle should produce a result")
	assert_true(result.is_victory(), "all enemies dead should be a victory")
	assert_equal(String(result.reason), "enemies_defeated", "victory reason should be enemies defeated")
	assert_equal(int(result.enemies_alive), 0, "victory result should report zero alive enemies")
	assert_true(int(result.player_hp) > 0, "victory result should record player hp")
	session.delete_save()


func test_defeat_when_player_dies() -> void:
	var session := _session()
	session.player["hp"] = 0
	var result: RefCounted = session.battle_result.judge(session)
	assert_true(result != null, "finished battle should produce a result")
	assert_true(result.is_defeat(), "player death should be a defeat")
	assert_equal(String(result.reason), "player_death", "defeat reason should be player death")
	assert_equal(int(result.player_hp), 0, "defeat result should record zero player hp")
	session.delete_save()


func test_no_result_while_battle_running() -> void:
	var session := _session()
	var result: RefCounted = session.battle_result.judge(session)
	assert_true(result == null, "ongoing battle should not produce a result")
	session.delete_save()


func test_victory_callback_goes_through_run_layer() -> void:
	var session := _session()
	var battles_before := int(session.player["battles_completed"])
	_kill_all_enemies(session)
	session._on_victory()
	assert_equal(String(session.phase), "reward", "victory callback should enter reward phase")
	assert_true(session.reward_options.size() > 0, "victory callback should build reward options")
	assert_equal(int(session.player["battles_completed"]), battles_before + 1, "victory callback should advance battles completed")
	session.delete_save()


func test_defeat_callback_formal_battle() -> void:
	var session := _formal_session()
	session.player["hp"] = 0
	session._on_defeat()
	assert_equal(String(session.phase), "game_over", "formal battle defeat should end the run")
	assert_true(String(session.message).contains("失败"), "formal battle defeat should describe the failure")
	session.delete_save()


func test_tutorial_defeat_restarts() -> void:
	var session := _session()
	var restarts_before := int(session.player["tutorial_restarts"])
	var battle_before := int(session.battle_index)
	session.player["hp"] = 0
	session._on_defeat()
	assert_equal(String(session.phase), "battle", "tutorial defeat should restart the battle")
	assert_equal(int(session.player["tutorial_restarts"]), restarts_before + 1, "tutorial defeat should count a restart")
	assert_equal(int(session.battle_index), battle_before, "tutorial defeat should not advance the battle index")
	session.delete_save()


func test_duplicate_settlement_is_idempotent() -> void:
	var session := _session()
	_kill_all_enemies(session)
	var first: RefCounted = session.battle_result.judge(session)
	var second: RefCounted = session.battle_result.judge(session)
	assert_equal(first.to_dictionary(), second.to_dictionary(), "judge should be deterministic for the same state")
	session.enemies[0]["hp"] = 5
	assert_equal(int(first.to_dictionary()["enemies_alive"]), 0, "result snapshot should not reflect later mutations")
	session.delete_save()
