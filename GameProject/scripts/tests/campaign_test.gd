extends "res://scripts/tests/test_base.gd"

const TestHelpers = preload("res://scripts/tests/test_helpers.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const EncounterService = preload("res://scripts/core/encounter_service.gd")
const CharacterService = preload("res://scripts/core/character_service.gd")


func run() -> void:
	test_tutorial_data()
	test_first_tutorial_battle_loadout_and_guidance()
	test_tutorial_defense_and_dodge_guidance_rewards()
	test_tutorial_is_before_formal_floor_one()
	test_first_unlocks_tower_completion_and_group_features()
	test_tower_bonus_range_and_seed_progression()
	test_encounter_generation()
	test_late_battles_are_stronger_than_openers()
	test_equipment_slots_without_sets()
	test_tower_equipment_capacity()


func test_tutorial_data() -> void:
	assert_equal(DataCatalog.TUTORIAL_ENCOUNTERS.size(), 3, "tutorial should define three encounter entries")
	for encounter in DataCatalog.TUTORIAL_ENCOUNTERS:
		assert_true(encounter.get("units", []).size() >= 1, "tutorial encounter has at least one enemy")
	var unlocks: Array = DataCatalog.TUTORIAL_UNLOCKS.get("unified", [])
	assert_equal(unlocks.size(), 3, "unified tutorial should define three unlock rewards")
	for unlock_id in unlocks:
		assert_true(DataCatalog.EQUIPMENT.has(unlock_id) or DataCatalog.SKILLS.has(unlock_id), "tutorial unlock should reference a known item or skill")


func test_first_tutorial_battle_loadout_and_guidance() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()


func test_tutorial_defense_and_dodge_guidance_rewards() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	TestHelpers.force_win(session)
	session.choose_reward(0)
	assert_equal(session.battle_index, 2, "second tutorial battle should follow the first reward")
	assert_equal(session.pending_state_card, "perfect_guard", "second tutorial battle should draw the defense bonus card")
	assert_true(String(session.message).contains("点击防御"), "second tutorial battle should guide defense")
	TestHelpers.force_win(session)
	assert_equal(String(session.reward_options[0].get("item_id", "")), "warrior_wooden_shield", "second tutorial reward should be the fixed wooden shield")
	session.choose_reward(0)
	assert_equal(session.battle_index, 3, "third tutorial battle should follow the second reward")
	assert_equal(session.pending_state_card, "read", "third tutorial battle should draw the dodge bonus card")
	assert_true(String(session.message).contains("点击闪避"), "third tutorial battle should guide dodge")
	TestHelpers.force_win(session)
	assert_equal(String(session.reward_options[0].get("item_id", "")), "common_moon_ring", "third tutorial reward should be the fixed ring")
	session.choose_reward(0)
	assert_equal(String(session.player.get("tower_equipment", {}).get("accessory", "")), "common_moon_ring", "third tutorial reward should equip the ring")
	session.delete_save()
	session.start_new_game("warrior")
	assert_true(session.is_tutorial(), "first new game should enter tutorial")
	assert_equal(String(session.player.get("tower_equipment", {}).get("weapon", "")), "warrior_training_sword", "first tutorial battle should provide the training sword")
	assert_equal(session.character.skill_id_for_slot(session.player, 0), "tiao_zhan", "training sword should expose the first weapon skill")
	assert_true(String(session.message).contains("使用下方技能"), "first tutorial battle should guide skill usage")
	var unlocked_skills_before: Array = session.player.get("unlocked_skills", []).duplicate()
	TestHelpers.force_win(session)
	assert_equal(session.phase, "reward", "first tutorial victory should open the reward phase")
	assert_true(not session.reward_options.is_empty(), "first tutorial victory should provide a reward")
	if session.reward_options.is_empty():
		session.delete_save()
		return
	assert_equal(String(session.reward_options[0].get("item_id", "")), "warrior_old_chest", "first tutorial reward should be the fixed chest")
	session.choose_reward(0)
	assert_equal(session.player.get("unlocked_skills", []), unlocked_skills_before, "first tutorial reward should not unlock a new skill")
	assert_equal(String(session.player.get("tower_equipment", {}).get("armor", "")), "warrior_old_chest", "first tutorial reward should equip the chest")
	session.delete_save()


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


func test_first_unlocks_tower_completion_and_group_features() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()


func test_tower_bonus_range_and_seed_progression() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	assert_equal(DataCatalog.MAX_TOWER_BONUS, 6, "tower difficulty should support zero through plus six")
	session.tower_bonus = 6
	session.floor_index = 7
	assert_equal(session.effective_tower_level(), 13, "plus six tower should add to the floor level")
	session.cleared_tower_bonuses.clear()
	session.tower_seeds = 0
	session.max_tower_bonus = 0
	session.player["blood_potion_uses"] = 3
	session.player["passive_skill_slots"] = 0
	for tower_bonus in range(0, 7):
		session.tower_bonus = tower_bonus
		session.run_progress._record_tower_completion(session)
	assert_equal(session.tower_seeds, 7, "each tower difficulty should provide one seed on first clear")
	assert_equal(session.max_tower_bonus, 6, "all seven clears should unlock through plus six")
	assert_equal(session.player["blood_potion_uses"], 10, "seven seeds should increase blood potion uses from three to ten")
	session.delete_save()
	session.start_new_game("warrior")
	session.phase = "npc_shop"
	session.tower_coins = 60
	session.run_progress._unlock_boss_npc(session, 1)
	assert_true(session.is_npc_unlocked("merchant"), "floor one boss should unlock the merchant")
	assert_true(session.buy_tower_consumable("minor_heal"), "merchant should sell tower consumables")
	assert_true(not session.tower_stash.is_empty(), "merchant purchase should enter the tower stash")
	session.run_progress._unlock_boss_npc(session, 3)
	assert_true(session.is_npc_unlocked("blacksmith"), "floor three boss should unlock the blacksmith")
	assert_true(session.buy_permanent_equipment("warrior", "common_moon_ring"), "blacksmith should sell permanent equipment")
	session.run_progress._unlock_boss_npc(session, 5)
	assert_true(session.is_npc_unlocked("mage"), "floor five boss should unlock the mage")
	assert_true(session.buy_common_skill("first_aid"), "mage should sell permanent skills")
	session.tutorial_active = false
	session.encountered_groups_by_floor = []
	session.floor_index = 1
	for group_index in range(8):
		session._record_group_encounter("group_a")
	assert_true(not session.is_npc_feature_unlocked("merchant_upgraded"), "eight first-floor groups should not unlock merchant upgrades")
	session._record_group_encounter("group_b")
	assert_true(session.is_npc_feature_unlocked("merchant_upgraded"), "nine first-floor groups should unlock merchant upgrades")
	session.floor_index = 3
	for group_index in range(6):
		session._record_group_encounter("group_b")
	assert_true(not session.is_npc_feature_unlocked("blacksmith_upgraded"), "six third-floor groups should not unlock blacksmith upgrades")
	session._record_group_encounter("group_c")
	assert_true(session.is_npc_feature_unlocked("blacksmith_upgraded"), "seven third-floor groups should unlock blacksmith upgrades")
	session.floor_index = 5
	for group_index in range(4):
		session._record_group_encounter("group_c")
	assert_true(not session.is_npc_feature_unlocked("mage_upgraded"), "four fifth-floor groups should not unlock mage upgrades")
	session._record_group_encounter("group_d")
	assert_true(session.is_npc_feature_unlocked("mage_upgraded"), "five fifth-floor groups should unlock mage upgrades")
	session.floor_index = 7
	session.tower_bonus = 0
	session.cleared_tower_bonuses.clear()
	session.tower_seeds = 0
	session.player["blood_potion_uses"] = 3
	session.player["passive_skill_slots"] = 0
	session.run_progress._record_tower_completion(session)
	assert_equal(session.tower_seeds, 1, "first difficulty clear should provide one seed")
	assert_equal(session.max_tower_bonus, 1, "first difficulty clear should unlock the next tower bonus")
	assert_equal(session.player["blood_potion_uses"], 4, "each seed should add one blood potion use")
	assert_equal(session.player["passive_skill_slots"], 1, "first tower completion should unlock the first passive slot")
	session.run_progress._record_tower_completion(session)
	assert_equal(session.tower_seeds, 1, "reclearing one difficulty should not provide another seed")
	session.tower_bonus = 1
	session.run_progress._record_tower_completion(session)
	assert_equal(session.tower_seeds, 2, "clearing a second difficulty should provide another seed")
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


func test_tower_equipment_capacity() -> void:
	var character := CharacterService.new()
	var player := character.create_character("unified")
	var candidates: Array[String] = []
	for item_id in DataCatalog.EQUIPMENT.keys():
		var normalized_id := String(item_id)
		if not player["tower_equipment_ids"].has(normalized_id):
			candidates.append(normalized_id)
	assert_true(candidates.size() >= DataCatalog.TOWER_EQUIPMENT_SLOTS, "equipment catalog should provide capacity test items")
	for item_index in range(DataCatalog.TOWER_EQUIPMENT_SLOTS - 1):
		assert_true(character.equip_tower_item(player, candidates[item_index]), "tower equipment should fill an available bag slot")
	assert_equal(player["tower_equipment_ids"].size(), DataCatalog.TOWER_EQUIPMENT_SLOTS, "tower equipment bag should stop at four items")
	assert_true(not character.equip_tower_item(player, candidates[DataCatalog.TOWER_EQUIPMENT_SLOTS - 1]), "fifth tower equipment should be rejected")
	assert_equal(player["tower_equipment_ids"].size(), DataCatalog.TOWER_EQUIPMENT_SLOTS, "rejected equipment should not expand the bag")
