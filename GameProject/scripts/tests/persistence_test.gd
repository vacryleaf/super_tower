extends "res://scripts/tests/test_base.gd"

const TestHelpers = preload("res://scripts/tests/test_helpers.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func run() -> void:
	test_save_round_trip()
	test_end_run_to_camp_clears_active_run()
	test_profile_keeps_multiple_classes()
	test_tower_coins_persist()


func test_save_round_trip() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	session.player_attack(0)
	session.battle_log.append("save_marker")
	assert_true(session.save_game(), "save should succeed")
	var loaded = session_script.new()
	assert_true(loaded.load_game(), "load should succeed")
	assert_equal(loaded.phase, session.phase, "loaded phase")
	assert_equal(loaded.class_id, session.class_id, "loaded class")
	assert_equal(int(loaded.floor_index), int(session.floor_index), "loaded floor")
	assert_equal(int(loaded.battle_index), int(session.battle_index), "loaded battle")
	assert_equal(int(loaded.player["hp"]), int(session.player["hp"]), "loaded hp")
	assert_equal(loaded.enemies.size(), session.enemies.size(), "loaded enemy count")
	assert_true(loaded.battle_log.has("save_marker"), "loaded battle log")
	loaded.delete_save()


func test_end_run_to_camp_clears_active_run() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			TestHelpers.force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	var target := {"type": "equipment", "id": String(session.player["equipment_ids"][0])}
	session.simulator.attach_reward(session.player, target, {
		"kind": "attack",
		"label": "塔内测试攻击 +99",
		"value": 99
	})
	assert_true(session.save_game(), "active run should save before ending")
	assert_true(session.has_active_run(), "active run exists before ending")
	assert_true(session.end_run_to_camp(), "ending run should save profile")
	assert_equal(session.phase, "menu", "ending run should return to camp menu")
	assert_true(not session.has_active_run(), "ending run should clear active run")
	var loaded = session_script.new()
	assert_true(not loaded.load_game(), "no active run should be loadable after ending")
	var roster_player: Dictionary = session.get_roster_player("warrior")
	assert_true(not roster_player.is_empty(), "roster player should remain after ending run")
	assert_true(TestHelpers.dictionary_total(roster_player.get("equipment_attachments", {})) == 0, "tower equipment attachments should not persist")
	session.delete_save()


func test_profile_keeps_multiple_classes() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var warrior_session = session_script.new()
	warrior_session.delete_save()
	warrior_session.start_new_game("warrior")
	TestHelpers.force_win(warrior_session)
	warrior_session.choose_reward(0)
	assert_true(warrior_session.save_game(), "warrior profile save")

	var archer_session = session_script.new()
	archer_session.start_new_game("archer")
	TestHelpers.force_win(archer_session)
	archer_session.choose_reward(0)
	assert_true(archer_session.save_game(), "archer profile save")

	var profile_session = session_script.new()
	var warrior: Dictionary = profile_session.get_roster_player("warrior")
	var archer: Dictionary = profile_session.get_roster_player("archer")
	assert_true(not warrior.is_empty(), "profile keeps warrior")
	assert_true(not archer.is_empty(), "profile keeps archer")
	assert_equal(warrior.get("class_id", ""), "warrior", "warrior roster class")
	assert_equal(archer.get("class_id", ""), "archer", "archer roster class")
	profile_session.delete_save()

func test_tower_coins_persist() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			TestHelpers.force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	session.tower_coins = 42
	assert_true(session.save_game(), "save should persist tower_coins")
	var loaded = session_script.new()
	loaded._load_account()
	assert_equal(loaded.tower_coins, 42, "tower_coins should persist across sessions")
	session.delete_save()
