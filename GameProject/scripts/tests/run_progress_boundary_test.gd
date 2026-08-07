extends "res://scripts/tests/test_base.gd"

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const RewardService = preload("res://scripts/core/reward_service.gd")


func run() -> void:
	test_victory_normal_advances_growth_and_bestiary()
	test_victory_boss_unlocks_npc_and_writes_profile()
	test_victory_final_floor_records_completion()
	test_victory_tutorial_uses_fixed_reward()
	test_defeat_formal_enters_game_over()
	test_defeat_tutorial_restarts_battle()
	test_choose_reward_attachment_flow()
	test_choose_reward_direct_apply_advances()
	test_advance_after_reward_floor_progression()
	test_advance_after_reward_tower_victory()
	test_advance_after_reward_tutorial_epilogue()
	test_run_services_do_not_depend_on_battle_private_api()


func _session() -> RefCounted:
	var session := PlaySession.new()
	session.delete_save()
	session.start_new_game("warrior")
	return session


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


func _encounter_enemy_ids(session: RefCounted) -> Array:
	var ids: Array = []
	for unit in session.current_encounter.get("units", []):
		ids.append(String(unit.get("id", unit.get("name", ""))))
	return ids


func test_victory_normal_advances_growth_and_bestiary() -> void:
	var session := _formal_session()
	var battles_before := int(session.player["battles_completed"])
	var coins_before := int(session.tower_coins)
	var enemy_ids := _encounter_enemy_ids(session)
	_kill_all_enemies(session)
	session._on_victory()
	assert_equal(String(session.phase), "reward", "victory enters reward phase")
	assert_equal(int(session.player["battles_completed"]), battles_before + 1, "victory advances battles completed")
	assert_true(int(session.tower_coins) > coins_before, "victory grants tower coins")
	assert_true(session.reward_options.size() > 0, "victory builds reward options")
	var profile: Dictionary = session.save_profile.read_profile(Callable(session, "_persistent_player_snapshot"))
	var bestiary: Dictionary = profile.get("bestiary", {})
	for enemy_id in enemy_ids:
		assert_true(bestiary.has(enemy_id), "bestiary records defeated enemy")
	session.delete_save()


func test_victory_boss_unlocks_npc_and_writes_profile() -> void:
	var session := _session()
	session.player["tutorial_completed"] = true
	session.tutorial_active = false
	session.floor_index = 5
	session.battle_index = 10
	session.floor_group_id = ""
	session._start_current_battle()
	assert_equal(String(session.current_encounter.get("type", "")), "boss", "battle ten is a boss encounter")
	var coins_before := int(session.tower_coins)
	_kill_all_enemies(session)
	session._on_victory()
	assert_true(int(session.tower_coins) > coins_before, "boss victory grants tower coins")
	assert_true(session.npc_unlocks.has("mage"), "floor five boss unlocks mage")
	var profile: Dictionary = session.save_profile.read_profile(Callable(session, "_persistent_player_snapshot"))
	assert_true(Array(profile.get("npc_unlocks", [])).has("mage"), "npc unlock written back to profile")
	assert_true(not Array(profile.get("npc_unlocks", [])).has("merchant"), "unrelated npc stays locked")
	session.delete_save()


func test_victory_final_floor_records_completion() -> void:
	var session := _session()
	session.player["tutorial_completed"] = true
	session.tutorial_active = false
	session.floor_index = DataCatalog.MAX_TOWER_FLOOR
	session.battle_index = 10
	session.floor_group_id = ""
	session._start_current_battle()
	_kill_all_enemies(session)
	session._on_victory()
	assert_true(session.cleared_tower_bonuses.has(session.tower_bonus), "tower completion records cleared bonus")
	assert_true(int(session.tower_seeds) >= 1, "tower completion grants seed")
	assert_true(int(session.player.get("passive_skill_slots", 0)) >= 1, "first completion unlocks passive slot")
	var profile: Dictionary = session.save_profile.read_profile(Callable(session, "_persistent_player_snapshot"))
	var cleared_bonuses: Array = profile.get("cleared_tower_bonuses", [])
	var cleared_found := false
	for bonus in cleared_bonuses:
		if int(bonus) == int(session.tower_bonus):
			cleared_found = true
	assert_true(cleared_found, "cleared bonus written back to profile")
	assert_true(int(profile.get("tower_seeds", 0)) >= 1, "seed written back to profile")
	session.delete_save()


func test_victory_tutorial_uses_fixed_reward() -> void:
	var session := _session()
	assert_true(session.is_tutorial(), "new game starts in tutorial")
	var coins_before := int(session.tower_coins)
	_kill_all_enemies(session)
	session._on_victory()
	assert_equal(int(session.tower_coins), coins_before, "tutorial victory grants no tower coins")
	assert_equal(String(session.phase), "reward", "tutorial victory enters reward")
	assert_equal(session.reward_options.size(), 1, "tutorial reward is a fixed single option")
	assert_equal(String(session.reward_options[0].get("kind", "")), "tutorial_unlock", "tutorial reward kind")
	session.delete_save()


func test_defeat_formal_enters_game_over() -> void:
	var session := _formal_session()
	session.player["hp"] = 0
	session._on_defeat()
	assert_equal(String(session.phase), "game_over", "formal defeat enters game over")
	assert_true(String(session.message).find("第 2 层") >= 0, "formal defeat message includes floor")
	session.delete_save()


func test_defeat_tutorial_restarts_battle() -> void:
	var session := _session()
	var restarts_before := int(session.player.get("tutorial_restarts", 0))
	var max_hp := int(session.player.get("max_hp", 0))
	session.player["hp"] = 1
	session._on_defeat()
	assert_equal(int(session.player.get("tutorial_restarts", 0)), restarts_before + 1, "tutorial defeat counts restart")
	assert_equal(int(session.player["hp"]), max_hp, "tutorial defeat restores hp")
	assert_equal(String(session.phase), "battle", "tutorial defeat restarts battle")
	session.delete_save()


func test_choose_reward_attachment_flow() -> void:
	var session := _formal_session()
	session.phase = "reward"
	var attachment_options: Array[Dictionary] = [RewardService.make_reward("attack", "攻击 +3", "floor_reward:normal", "attachment", {"stat": "attack", "value": 3})]
	session.reward_options = attachment_options
	var target_count: int = session.reward_apply.build_reward_targets(session).size()
	assert_true(target_count > 0, "attachment targets should exist for a formal run")
	session.reward_apply.choose_reward(session, 0)
	assert_equal(String(session.phase), "reward_target", "attachment reward enters target phase")
	assert_true(not session.pending_reward.is_empty(), "pending reward kept for attachment")
	assert_equal(session.reward_targets.size(), target_count, "attachment targets built")
	var battle_before := int(session.battle_index)
	session.reward_apply.choose_reward_target(session, 0)
	assert_equal(String(session.phase), "battle", "attachment advances to next battle")
	assert_equal(int(session.battle_index), battle_before + 1, "attachment advances battle index")
	session.delete_save()


func test_choose_reward_direct_apply_advances() -> void:
	var session := _formal_session()
	session.player["hp"] = 1
	session.phase = "reward"
	var heal_options: Array[Dictionary] = [RewardService.make_reward("heal", "恢复生命", "legacy", "player", {"value": 10})]
	session.reward_options = heal_options
	var max_hp := int(session.player["max_hp"])
	var battle_before := int(session.battle_index)
	session.reward_apply.choose_reward(session, 0)
	assert_true(int(session.player["hp"]) >= mini(max_hp, 11), "heal reward restores at least ten hp")
	assert_equal(String(session.phase), "battle", "direct reward advances to next battle")
	assert_equal(int(session.battle_index), battle_before + 1, "direct reward advances battle index")
	session.delete_save()


func test_advance_after_reward_floor_progression() -> void:
	var session := _formal_session()
	session.floor_index = 2
	session.battle_index = 10
	session.run_progress.advance_after_reward(session)
	assert_equal(int(session.floor_index), 3, "battle ten advances floor")
	assert_equal(int(session.battle_index), 1, "battle ten resets battle index")
	assert_true(String(session.floor_group_id) != "", "floor advance starts next battle with a fresh group id")
	assert_equal(String(session.phase), "battle", "floor advance starts next battle")
	session.delete_save()


func test_advance_after_reward_tower_victory() -> void:
	var session := _formal_session()
	session.floor_index = DataCatalog.MAX_TOWER_FLOOR
	session.battle_index = 10
	session.run_progress.advance_after_reward(session)
	assert_equal(String(session.phase), "victory", "final floor battle ten completes run")
	assert_true(String(session.message).find("通关") >= 0, "tower victory message set")
	session.delete_save()


func test_advance_after_reward_tutorial_epilogue() -> void:
	var session := _session()
	session.battle_index = 3
	session.run_progress.advance_after_reward(session)
	assert_true(bool(session.player.get("tutorial_completed", false)), "tutorial completion marked")
	assert_true(not session.tutorial_active, "tutorial flag cleared")
	assert_equal(String(session.phase), "tutorial_epilogue", "tutorial ends in epilogue")
	assert_equal(int(session.floor_index), 1, "tutorial ends at formal floor one")
	assert_equal(int(session.battle_index), 1, "tutorial ends at formal battle one")
	session.delete_save()


func test_run_services_do_not_depend_on_battle_private_api() -> void:
	var run_source := FileAccess.get_file_as_string("res://scripts/core/run_progress_service.gd")
	var apply_source := FileAccess.get_file_as_string("res://scripts/core/reward_apply_service.gd")
	assert_true(run_source != "", "run progress source readable")
	assert_true(apply_source != "", "reward apply source readable")
	for banned in ["battle_service", "play_session", "combat_engine"]:
		assert_true(not run_source.contains(banned), "run progress avoids %s" % banned)
		assert_true(not apply_source.contains(banned), "reward apply avoids %s" % banned)
	for banned in ["_execute_action_skill", "_execute_enemy_action_skill", "_execute_action_damage", "_execute_enemy_action_damage", "_action_attack_value", "_enemy_action_attack_value"]:
		assert_true(not run_source.contains(banned), "run progress avoids battle private %s" % banned)
		assert_true(not apply_source.contains(banned), "reward apply avoids battle private %s" % banned)
	assert_true(not run_source.contains("_build_reward_options"), "run progress uses reward_apply port")
	assert_true(not apply_source.contains("_advance_after_reward"), "reward apply uses run_progress port")
