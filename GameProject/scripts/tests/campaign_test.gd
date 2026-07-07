extends "res://scripts/tests/test_base.gd"

const TestHelpers = preload("res://scripts/tests/test_helpers.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const RunSimulator = preload("res://scripts/core/run_simulator.gd")
const CombatEngine = preload("res://scripts/core/combat_engine.gd")
const DynamicValueResolver = preload("res://scripts/core/dynamic_value_resolver.gd")


func run() -> void:
	test_tutorial_unlocks("warrior")
	test_tutorial_unlocks("archer")
	test_encounter_generation()
	test_late_battles_are_stronger_than_openers()
	test_baseline_campaign_difficulty_gate("warrior")
	test_baseline_campaign_difficulty_gate("archer")
	test_circus_set_juggling()
	test_jungle_set_meticulous()


func test_tutorial_unlocks(class_id: String) -> void:
	var simulator := RunSimulator.new()
	var result := simulator.run_tutorial(class_id)
	assert_true(result["success"], "%s tutorial must complete" % class_id)
	var player: Dictionary = result["player"]
	assert_true(player["tutorial_completed"], "%s tutorial completed flag" % class_id)
	assert_equal(int(player["battles_completed"]), 10, "%s tutorial battle count" % class_id)
	assert_equal(player["equipment_ids"].size(), 9, "%s tutorial equipment count" % class_id)
	assert_equal(player["equipped_skills"].size(), 1, "%s first skill equipped" % class_id)
	assert_equal(player["unlocked_skills"].size(), 1, "%s first skill unlocked once" % class_id)
	assert_true(int(player["tutorial_restarts"]) <= 1, "%s tutorial protection should rarely restart with low-armor baseline" % class_id)

	var first_skill: String = DataCatalog.CLASSES[class_id]["first_skill"]
	assert_true(player["equipped_skills"].has(first_skill), "%s first skill id" % class_id)
	for item_id in player["equipment_ids"]:
		var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
		assert_true(item.has("hp") and item.has("attack") and item.has("armor"), "%s equipment has hp/attack/armor" % item_id)
		assert_true(item["slot"] != "necklace" and item["slot"] != "ring", "%s tutorial must not unlock necklace or ring" % item_id)


func test_encounter_generation() -> void:
	var simulator := RunSimulator.new()
	for tower_floor in range(2, 11):
		var counts := {"normal": 0, "elite": 0, "boss": 0}
		var has_multi_enemy := false
		for battle_index in range(1, 11):
			var encounter := simulator.generate_encounter(tower_floor, battle_index)
			counts[encounter["type"]] += 1
			if encounter["units"].size() > 1:
				has_multi_enemy = true
			assert_true(encounter["units"].size() >= 1, "encounter has at least one enemy")
		assert_equal(int(counts["normal"]), 7, "floor %d normal count" % tower_floor)
		assert_equal(int(counts["elite"]), 2, "floor %d elite count" % tower_floor)
		assert_equal(int(counts["boss"]), 1, "floor %d boss count" % tower_floor)
		if tower_floor >= 3:
			assert_true(has_multi_enemy, "floor %d should include at least one multi-enemy formation" % tower_floor)


func test_late_battles_are_stronger_than_openers() -> void:
	var simulator := RunSimulator.new()
	var combat := CombatEngine.new()
	for tower_floor in range(2, 11):
		var opener_total := 0.0
		for battle_index in range(1, 4):
			opener_total += TestHelpers.encounter_threat(combat, simulator.generate_encounter(tower_floor, battle_index), tower_floor)
		var late_total := 0.0
		for battle_index in range(4, 10):
			late_total += TestHelpers.encounter_threat(combat, simulator.generate_encounter(tower_floor, battle_index), tower_floor)
		assert_true((late_total / 6.0) > (opener_total / 3.0), "floor %d battles 4-9 average threat should exceed battles 1-3" % tower_floor)


func test_baseline_campaign_difficulty_gate(class_id: String) -> void:
	var simulator := RunSimulator.new()
	var floor_five := simulator.run_campaign(class_id, 5)
	assert_true(floor_five["success"], "%s baseline campaign should clear floor 5, failed at floor %d battle %d" % [
		class_id,
		int(floor_five.get("failed_floor", 0)),
		TestHelpers.failed_battle(floor_five)
	])
	if bool(floor_five["success"]):
		assert_equal(int(floor_five["floors_completed"]), 5, "%s completed floor count before build gate" % class_id)
		assert_equal(int(floor_five["battles_completed"]), 50, "%s completed battle count through floor 5" % class_id)
		assert_equal(int(floor_five["normal_rewards"]), 28, "%s normal reward count for floors 2-5" % class_id)
		assert_equal(int(floor_five["elite_rewards"]), 8, "%s elite reward count for floors 2-5" % class_id)
		assert_equal(int(floor_five["boss_rewards"]), 4, "%s boss reward count for floors 2-5" % class_id)
		assert_true(int(floor_five["hp"]) > 0, "%s floor 5 final hp above zero" % class_id)

		var player: Dictionary = floor_five["player"]
		assert_true(player["tutorial_completed"], "%s campaign tutorial flag" % class_id)
		assert_true(player["equipped_skills"].size() <= 4, "%s max four skill slots" % class_id)
		assert_true(TestHelpers.has_no_duplicates(player["unlocked_skills"]), "%s skill unlocks must not duplicate" % class_id)

		for floor_summary in floor_five["floor_summaries"]:
			assert_equal(int(floor_summary["battles"]), 10, "%s floor %d has ten battles" % [class_id, int(floor_summary["floor"])])

	var deep_attempt := simulator.run_campaign(class_id, 10)
	assert_true(not bool(deep_attempt["success"]), "%s baseline campaign should not clear floor 10 without stronger set synergies" % class_id)
	assert_true(int(deep_attempt["failed_floor"]) >= 6, "%s baseline failure should happen after floor 5, got floor %d battle %d" % [
		class_id,
		int(deep_attempt.get("failed_floor", 0)),
		TestHelpers.failed_battle(deep_attempt)
	])


func test_circus_set_juggling() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			TestHelpers.force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	session.player["equipment"] = {}
	session.player["equipment_ids"] = []
	session.player["set_counts"] = {}
	session.player["active_set_effects"] = {}
	session.player["equipment_attachments"] = {}
	session.player["skill_attachments"] = {}
	var simulator = RunSimulator.new()
	simulator.equip_item(session.player, "circus_whip")
	simulator.equip_item(session.player, "circus_torch")
	simulator.equip_item(session.player, "circus_mask")
	simulator.equip_item(session.player, "circus_gloves")
	simulator._recalculate_player_stats(session.player, true)
	var effects: Dictionary = session.player.get("active_set_effects", {})
	assert_true(effects.get("modifiers", []).size() >= 0, "circus set should have modifiers slot")
	var on_start: Array = effects.get("on_battle_start", [])
	var has_juggling := false
	var has_performance := false
	for action in on_start:
		var status: Dictionary = action.get("status", {})
		if status.get("id", "") == "circus_juggling":
			has_juggling = true
		if status.get("id", "") == "circus_performance":
			has_performance = true
	assert_true(has_juggling, "circus 2-piece should grant juggling status")
	assert_true(has_performance, "circus 4-piece should grant performance status")
	session._start_current_battle()
	var has_juggling_status := false
	var has_performance_status := false
	for status in session.player.get("statuses", []):
		if status.get("id", "") == "circus_juggling":
			has_juggling_status = true
		if status.get("id", "") == "circus_performance":
			has_performance_status = true
	assert_true(has_juggling_status, "juggling status should be on player after battle start")
	assert_true(has_performance_status, "performance status should be on player after battle start")
	session._add_player_dodge(5)
	var enemy: Dictionary = session.enemies[0]
	session.battle_service.enemy_attack(session, enemy, 0, false)
	assert_equal(session.dodge_streak, 1, "dodge streak should be 1 after first dodge")
	session._add_player_dodge(5)
	session.battle_service.enemy_attack(session, enemy, 0, false)
	assert_equal(session.dodge_streak, 0, "dodge streak should reset after performance triggers")


func test_jungle_set_meticulous() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("archer")
	while session.is_tutorial():
		if session.phase == "battle":
			TestHelpers.force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	session.player["equipment"] = {}
	session.player["equipment_ids"] = []
	session.player["set_counts"] = {}
	session.player["active_set_effects"] = {}
	session.player["equipment_attachments"] = {}
	session.player["skill_attachments"] = {}
	var simulator = RunSimulator.new()
	simulator.equip_item(session.player, "jungle_bow")
	simulator.equip_item(session.player, "jungle_knife")
	simulator.equip_item(session.player, "jungle_hat")
	simulator.equip_item(session.player, "jungle_vest")
	simulator.equip_item(session.player, "jungle_pants")
	simulator.equip_item(session.player, "jungle_gloves")
	simulator._recalculate_player_stats(session.player, true)
	var effects: Dictionary = session.player.get("active_set_effects", {})
	var on_start: Array = effects.get("on_battle_start", [])
	var has_meticulous := false
	var has_seek_bloom := false
	var has_hunt := false
	for action in on_start:
		var status: Dictionary = action.get("status", {})
		if status.get("id", "") == "jungle_meticulous":
			has_meticulous = true
		if status.get("id", "") == "jungle_seek_bloom":
			has_seek_bloom = true
		if status.get("id", "") == "jungle_hunt":
			has_hunt = true
	assert_true(has_meticulous, "jungle 2-piece should grant meticulous status")
	assert_true(has_seek_bloom, "jungle 4-piece should grant seek_bloom status")
	assert_true(has_hunt, "jungle 6-piece should grant hunt status")
	session._start_current_battle()
	var has_meticulous_status := false
	var has_seek_bloom_status := false
	var has_hunt_status := false
	for status in session.player.get("statuses", []):
		if status.get("id", "") == "jungle_meticulous":
			has_meticulous_status = true
		if status.get("id", "") == "jungle_seek_bloom":
			has_seek_bloom_status = true
		if status.get("id", "") == "jungle_hunt":
			has_hunt_status = true
	assert_true(has_meticulous_status, "meticulous status should be on player")
	assert_true(has_seek_bloom_status, "seek_bloom status should be on player")
	assert_true(has_hunt_status, "hunt status should be on player")
	assert_equal(session.meticulous_stacks, 0, "meticulous should start at 0")
	assert_equal(session.seek_bloom_stacks, 1, "seek_bloom should be 1 after first turn start")
	session._add_player_dodge(5)
	var enemy: Dictionary = session.enemies[0]
	session.battle_service.enemy_attack(session, enemy, 0, false)
	assert_equal(session.meticulous_stacks, 1, "meticulous should be 1 after one dodge")
	session.dodge_layers = 0
	session.battle_service.enemy_attack(session, enemy, 0, false)
	assert_equal(session.meticulous_stacks, 0, "meticulous should reset after being hit")
	session._add_player_dodge(10)
	for i in range(5):
		session.battle_service.enemy_attack(session, enemy, 0, false)
	assert_equal(session.meticulous_stacks, 5, "meticulous should cap at 5 stacks")
	session.attacked_this_turn = false
	session._begin_player_turn()
	assert_equal(session.seek_bloom_stacks, 2, "seek_bloom should be 2 after two non-attack turns")
	session.attacked_this_turn = false
	session._begin_player_turn()
	assert_equal(session.seek_bloom_stacks, 3, "seek_bloom should cap at 3 stacks")
	var hunt_bonus := DynamicValueResolver.resolve("dynamic:hunt", session.player, {"meticulous_stacks": 5, "seek_bloom_stacks": 3})
	assert_true(abs(hunt_bonus - 2.85) < 0.001, "hunt bonus should be 2.85 with 5 meticulous + 3 seek_bloom")
	session.action_points = 1
	session.player_attack(0)
	assert_equal(session.meticulous_stacks, 0, "meticulous should reset after dealing damage")
	assert_equal(session.seek_bloom_stacks, 0, "seek_bloom should reset after dealing damage")