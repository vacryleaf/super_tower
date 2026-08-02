extends "res://scripts/tests/test_base.gd"

const TestHelpers = preload("res://scripts/tests/test_helpers.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const EncounterService = preload("res://scripts/core/encounter_service.gd")
const CharacterService = preload("res://scripts/core/character_service.gd")


func run() -> void:
	test_tutorial_data()
	test_tutorial_is_before_formal_floor_one()
	test_encounter_generation()
	test_late_battles_are_stronger_than_openers()
	test_equipment_slots_without_sets()


func test_tutorial_data() -> void:
	assert_equal(DataCatalog.TUTORIAL_ENCOUNTERS.size(), 3, "tutorial should define three encounter entries")
	for encounter in DataCatalog.TUTORIAL_ENCOUNTERS:
		assert_true(encounter.get("units", []).size() >= 1, "tutorial encounter has at least one enemy")
	var unlocks: Array = DataCatalog.TUTORIAL_UNLOCKS.get("unified", [])
	assert_equal(unlocks.size(), 3, "unified tutorial should define three unlock rewards")
	for unlock_id in unlocks:
		assert_true(DataCatalog.EQUIPMENT.has(unlock_id) or DataCatalog.SKILLS.has(unlock_id), "tutorial unlock should reference a known item or skill")


func test_tutorial_is_before_formal_floor_one() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	assert_true(session.is_tutorial(), "a new character should start with the three-battle prologue")
	assert_true(session.tutorial_active, "tutorial mode should be independent from floor index")
	assert_equal(session.floor_index, 1, "tutorial should not advance the formal floor index")
	while session.is_tutorial():
		if session.phase == "battle":
			TestHelpers.force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	assert_equal(session.floor_index, 1, "tutorial completion should leave formal floor 1 available")
	assert_equal(session.battle_index, 1, "formal floor should begin at battle 1")
	assert_true(not session.tutorial_active, "tutorial mode should be disabled after the third battle")
	assert_true(session.end_run_to_camp(), "tutorial completion should return to camp")
	session.start_new_game("warrior")
	assert_true(not session.is_tutorial(), "completed tutorial should not restart")
	assert_equal(session.floor_index, 1, "completed tutorial should start formal floor 1")
	assert_equal(session.battle_index, 1, "formal floor 1 should start at battle 1")
	assert_true(not String(session.current_encounter.get("id", "")).begins_with("tutorial_"), "formal floor 1 should use normal tower encounters")
	session.delete_save()


func test_encounter_generation() -> void:
	var encounters := EncounterService.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for tower_floor in range(2, DataCatalog.MAX_TOWER_FLOOR + 1):
		var counts := {"normal": 0, "elite": 0, "boss": 0}
		var floor_group_id := encounters.select_floor_group_id(rng)
		var has_multi_enemy := false
		for battle_index in range(1, 11):
			var encounter := encounters.generate_encounter(tower_floor, battle_index, floor_group_id)
			counts[encounter["type"]] += 1
			assert_equal(String(encounter.get("group_id", "")), floor_group_id, "floor %d should keep one monster group" % tower_floor)
			if encounter["units"].size() > 1:
				has_multi_enemy = true
			assert_true(encounter["units"].size() >= 1, "encounter has at least one enemy")
		assert_equal(int(counts["normal"]), 7, "floor %d normal count" % tower_floor)
		assert_equal(int(counts["elite"]), 2, "floor %d elite count" % tower_floor)
		assert_equal(int(counts["boss"]), 1, "floor %d boss count" % tower_floor)
		assert_true(floor_group_id in DataCatalog.monster_group_ids(), "floor %d group should be valid" % tower_floor)
		if tower_floor >= 3:
			assert_true(has_multi_enemy, "floor %d should include at least one multi-enemy formation" % tower_floor)


func test_late_battles_are_stronger_than_openers() -> void:
	var encounters := EncounterService.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 19
	for tower_floor in range(2, DataCatalog.MAX_TOWER_FLOOR + 1):
		var floor_group_id := encounters.select_floor_group_id(rng)
		var opener_total := 0.0
		for battle_index in range(1, 4):
			opener_total += TestHelpers.encounter_threat(encounters.generate_encounter(tower_floor, battle_index, floor_group_id), tower_floor)
		var late_total := 0.0
		for battle_index in range(4, 10):
			late_total += TestHelpers.encounter_threat(encounters.generate_encounter(tower_floor, battle_index, floor_group_id), tower_floor)
		assert_true((late_total / 6.0) > (opener_total / 3.0), "floor %d battles 4-9 average threat should exceed battles 1-3 (late=%.2f opener=%.2f)" % [tower_floor, late_total / 6.0, opener_total / 3.0])


func test_equipment_slots_without_sets() -> void:
	var character := CharacterService.new()
	var player := character.create_character("unified")
	character.equip_item(player, "common_moon_necklace")
	character.equip_item(player, "common_moon_ring")
	assert_equal(player["equipment"].size(), 1, "accessories should share one slot")
	assert_equal(String(player["equipment"].get("accessory", "")), "common_moon_ring", "latest accessory should replace previous accessory")
	assert_true(not player.has("set_counts"), "set counts should not exist after recalculation")
	assert_true(not player.has("active_set_effects"), "set effects should not exist after recalculation")

	var equipment_service_script = load("res://scripts/core/equipment_service.gd")
	var equipment_service = equipment_service_script.new()
	var legacy_player := {"equipment": {"ring": "common_moon_necklace", "head": "circus_mask"}}
	equipment_service.normalize_equipment(legacy_player)
	assert_equal(String(legacy_player["equipment"].get("accessory", "")), "common_moon_necklace", "legacy ring should migrate to accessory")
	assert_equal(String(legacy_player["equipment"].get("armor", "")), "circus_mask", "legacy head should migrate to armor")
