extends SceneTree

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const RunSimulator = preload("res://scripts/core/run_simulator.gd")

var failures: Array[String] = []


func _init() -> void:
	run_all()
	if failures.is_empty():
		print("ALL TESTS PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func run_all() -> void:
	test_state_card_weights()
	test_skill_costs_minimum_two()
	test_reward_attachment_flow()
	test_tutorial_unlocks("warrior")
	test_tutorial_unlocks("archer")
	test_encounter_generation()
	test_campaign_floors_1_to_10("warrior")
	test_campaign_floors_1_to_10("archer")


func test_state_card_weights() -> void:
	assert_equal(DataCatalog.get_state_weight_total(), 100, "state card weights must total 100")
	assert_equal(int(DataCatalog.STATE_CARDS["critical"]["weight"]), 5, "critical state card weight")
	assert_equal(int(DataCatalog.STATE_CARDS["read"]["weight"]), 5, "read state card weight")
	assert_equal(int(DataCatalog.STATE_CARDS["perfect_guard"]["weight"]), 5, "perfect guard state card weight")
	assert_equal(int(DataCatalog.STATE_CARDS["fallback"]["weight"]), 5, "emergency fallback state card weight")


func test_skill_costs_minimum_two() -> void:
	for skill_id in DataCatalog.SKILLS.keys():
		assert_true(int(DataCatalog.SKILLS[skill_id].get("cost", 0)) >= 2, "%s skill cost minimum two" % skill_id)


func test_reward_attachment_flow() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			_force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	session.phase = "reward"
	session.current_encounter = {"type": "normal"}
	session._build_reward_options()
	session.choose_reward(0)
	assert_equal(session.phase, "reward_target", "normal reward should request attachment target")
	assert_true(session.reward_targets.size() > 0, "reward target list should not be empty")
	session.choose_reward_target(0)
	var target_count := 0
	for attachments in session.player.get("equipment_attachments", {}).values():
		target_count += attachments.size()
	for attachments in session.player.get("skill_attachments", {}).values():
		target_count += attachments.size()
	assert_true(target_count > 0, "reward should attach to equipment or skill")


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
	assert_equal(int(player["tutorial_restarts"]), 0, "%s tutorial should not need restart with baseline policy" % class_id)

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


func test_campaign_floors_1_to_10(class_id: String) -> void:
	var simulator := RunSimulator.new()
	var result := simulator.run_campaign(class_id, 10)
	assert_true(result["success"], "%s floors 1-10 campaign must complete" % class_id)
	assert_equal(int(result["floors_completed"]), 10, "%s completed floor count" % class_id)
	assert_equal(int(result["battles_completed"]), 100, "%s completed battle count" % class_id)
	assert_equal(int(result["normal_rewards"]), 63, "%s normal reward count for floors 2-10" % class_id)
	assert_equal(int(result["elite_rewards"]), 18, "%s elite reward count for floors 2-10" % class_id)
	assert_equal(int(result["boss_rewards"]), 9, "%s boss reward count for floors 2-10" % class_id)
	assert_true(int(result["hp"]) > 0, "%s final hp above zero" % class_id)

	var player: Dictionary = result["player"]
	assert_true(player["tutorial_completed"], "%s campaign tutorial flag" % class_id)
	assert_true(player["equipped_skills"].size() <= 4, "%s max four skill slots" % class_id)
	assert_true(_has_no_duplicates(player["unlocked_skills"]), "%s skill unlocks must not duplicate" % class_id)

	for floor_summary in result["floor_summaries"]:
		assert_equal(int(floor_summary["battles"]), 10, "%s floor %d has ten battles" % [class_id, int(floor_summary["floor"])])


func _force_win(session) -> void:
	for enemy in session.enemies:
		enemy["hp"] = 0
	session._on_victory()


func _has_no_duplicates(values: Array) -> bool:
	var seen := {}
	for value in values:
		if seen.has(value):
			return false
		seen[value] = true
	return true


func assert_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
