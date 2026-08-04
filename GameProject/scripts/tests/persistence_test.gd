extends "res://scripts/tests/test_base.gd"

const TestHelpers = preload("res://scripts/tests/test_helpers.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func run() -> void:
	test_save_round_trip()
	test_end_run_to_camp_clears_active_run()
	test_profile_migrates_legacy_class_ids_to_unified()
	test_tower_coins_persist()
	test_npc_unlock_persists()
	test_group_history_persists_by_floor()
	test_blood_potion_persists_and_can_be_used_in_battle()


func test_save_round_trip() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	TestHelpers.force_win(session)
	session.battle_log.append("save_marker")
	session.deferred_damage = 7.5
	session.duel_target_index = 0
	session.perfect_deflect = true
	session.set_counter("saved_counter", 4)
	assert_true(session.save_game(), "save should succeed")
	var loaded = session_script.new()
	assert_true(loaded.load_game(), "load should succeed")
	assert_equal(loaded.phase, session.phase, "loaded phase")
	assert_equal(loaded.class_id, session.class_id, "loaded class")
	assert_equal(int(loaded.floor_index), int(session.floor_index), "loaded floor")
	assert_equal(int(loaded.battle_index), int(session.battle_index), "loaded battle")
	assert_equal(int(loaded.player["hp"]), int(session.player["hp"]), "loaded hp")
	assert_equal(loaded.enemies.size(), session.enemies.size(), "loaded enemy count")
	assert_equal(loaded.deferred_damage, session.deferred_damage, "loaded deferred damage")
	assert_equal(loaded.duel_target_index, session.duel_target_index, "loaded duel target")
	assert_equal(loaded.perfect_deflect, session.perfect_deflect, "loaded perfect deflect")
	assert_equal(loaded.get_counter("saved_counter"), 4, "loaded trigger counter")
	assert_true(not loaded.battle_log.has("save_marker"), "battle log should not persist")
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
	var target := {"type": "equipment", "id": String(session.player["tower_equipment_ids"][0])}
	session.character.attach_reward(session.player, target, {
		"kind": "attack",
		"label": "塔内测试攻击 +99",
		"value": 99
	})
	session.player["tower_consumables"] = ["minor_heal"]
	session.player["tower_equipped_skills"] = ["", "", "quick_shot", ""]
	session.player["tower_passive_skills"] = ["iron_will"]
	session.phase = "battle"
	session.current_encounter = {"type": "normal", "name": "存档验证"}
	var active_enemies: Array[Dictionary] = [TestHelpers.test_enemy("存档验证敌人", 12, 3, [])]
	session.enemies = active_enemies
	assert_true(session.save_game(), "active run should save before ending")
	assert_true(session.has_active_run(), "active run exists before ending")
	assert_true(session.end_run_to_camp(), "ending run should save profile")
	assert_equal(session.phase, "menu", "ending run should return to camp menu")
	assert_true(not session.has_active_run(), "ending run should clear active run")
	var loaded = session_script.new()
	assert_true(loaded.load_game(), "camp save should still be loadable after ending")
	assert_equal(loaded.phase, "menu", "loaded camp should stay in menu phase")
	var roster_player: Dictionary = session.get_roster_player("warrior")
	assert_true(not roster_player.is_empty(), "roster player should remain after ending run")
	assert_true(TestHelpers.dictionary_total(roster_player.get("equipment_attachments", {})) == 0, "tower equipment attachments should not persist")
	assert_true(roster_player.get("tower_equipment", {}).is_empty(), "tower equipment should not persist")
	assert_true(roster_player.get("tower_consumables", []).is_empty(), "tower consumables should not persist")
	assert_true(roster_player.get("tower_equipped_skills", []).all(func(skill_id): return String(skill_id) == ""), "tower skills should not persist")
	assert_true(roster_player.get("tower_passive_skills", []).is_empty(), "tower passives should not persist")
	session.delete_save()


func test_profile_migrates_legacy_class_ids_to_unified() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	TestHelpers.force_win(session)
	session.choose_reward(0)
	assert_true(session.save_game(), "unified profile save")

	var profile_session = session_script.new()
	var unified: Dictionary = profile_session.get_roster_player("unified")
	var legacy_warrior: Dictionary = profile_session.get_roster_player("warrior")
	var legacy_archer: Dictionary = profile_session.get_roster_player("archer")
	assert_true(not unified.is_empty(), "profile keeps unified role")
	assert_equal(legacy_warrior.get("class_id", ""), "unified", "warrior legacy id migrates")
	assert_equal(legacy_archer.get("class_id", ""), "unified", "archer legacy id migrates")
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
	assert_true(session.end_run_to_camp(), "ending tutorial should persist tower_coins")
	var loaded = session_script.new()
	loaded._load_account()
	assert_equal(loaded.tower_coins, 42, "tower_coins should persist across sessions")
	session.delete_save()


func test_npc_unlock_persists() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	assert_true(not session.is_npc_unlocked("mage"), "mage should remain locked before floor five boss")
	session.floor_index = 5
	session.current_encounter = {"type": "boss", "units": [{"id": "test_boss"}]}
	session._unlock_boss_npc(5)
	assert_true(session.end_run_to_camp(), "ending run should persist NPC progress")
	var loaded = session_script.new()
	loaded._load_account()
	assert_true(loaded.is_npc_unlocked("mage"), "mage unlock should persist")
	session.delete_save()


func test_group_history_persists_by_floor() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	session.tutorial_active = false
	session.floor_index = 3
	session.encountered_groups_by_floor = [["rat", "guard"], [], ["shadow", "caster", "mutant"]]
	session.floor_encounter_count = 3
	assert_true(session.save_game(), "group history should save with active run")
	var loaded = session_script.new()
	assert_true(loaded.load_game(), "group history save should load")
	assert_equal(loaded.encountered_groups_by_floor, session.encountered_groups_by_floor, "group history should preserve each floor row")
	assert_equal(loaded.floor_encounter_count, 3, "current floor group count should be restored")
	loaded.delete_save()


func test_blood_potion_persists_and_can_be_used_in_battle() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	var max_hp := int(session.player["max_hp"])
	session.player["hp"] = max_hp - 20
	var uses_before := int(session.player["blood_potion_uses"])
	session.use_blood_potion_in_battle()
	assert_equal(int(session.player["blood_potion_uses"]), uses_before - 1, "battle potion use should consume one use")
	assert_true(int(session.player["hp"]) > max_hp - 20, "battle potion should restore health")
	assert_true(session.has_acted, "battle potion should consume the player action")
	assert_true(session.save_game(), "potion state should save")
	var loaded = session_script.new()
	assert_true(loaded.load_game(), "saved run should load")
	assert_equal(int(loaded.player["blood_potion_uses"]), uses_before - 1, "potion uses should persist in active run")
	session.delete_save()
