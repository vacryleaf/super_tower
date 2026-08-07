extends "res://scripts/tests/test_base.gd"

const RuntimeCatalog = preload("res://scripts/core/runtime_catalog.gd")
const EncounterService = preload("res://scripts/core/encounter_service.gd")
const RewardService = preload("res://scripts/core/reward_service.gd")
const EncyclopediaIndexService = preload("res://scripts/core/encyclopedia_index_service.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const TraitCatalog = preload("res://scripts/core/trait_catalog.gd")


func run() -> void:
	test_skill_entries_match_runtime()
	test_equipment_entries_match_runtime()
	test_monster_entries_match_runtime()
	test_encounter_units_sourced_from_catalog()
	test_reward_references_consistent()
	test_trait_entries_consistent()


func test_skill_entries_match_runtime() -> void:
	var catalog := RuntimeCatalog.new()
	var skills := catalog.runtime_table("skills")
	assert_equal(skills.size(), DataCatalog.SKILLS.size(), "skills runtime table size")
	for skill_id in DataCatalog.SKILLS.keys():
		var normalized_id := String(skill_id)
		assert_true(catalog.has("skills", normalized_id), "skill %s in catalog" % normalized_id)
		assert_equal(catalog.entry("skills", normalized_id).get("name", ""), DataCatalog.SKILLS[skill_id]["name"], "skill %s name" % normalized_id)
	var rewards := RewardService.new(catalog)
	var skill_reward := rewards.tower_skill_reward("unified")
	if not skill_reward.is_empty():
		var rewarded_id := String(skill_reward.get("effect", {}).get("skill_id", ""))
		assert_true(catalog.has("skills", rewarded_id), "tower skill %s in catalog" % rewarded_id)


func test_equipment_entries_match_runtime() -> void:
	var catalog := RuntimeCatalog.new()
	var equipment := catalog.runtime_table("equipment")
	assert_equal(equipment.size(), DataCatalog.EQUIPMENT.size(), "equipment runtime table size")
	for item_id in DataCatalog.EQUIPMENT.keys():
		var normalized_id := String(item_id)
		assert_true(catalog.has("equipment", normalized_id), "equipment %s in catalog" % normalized_id)
	var rewards := RewardService.new(catalog)
	var equipment_reward := rewards.tower_equipment_reward({"equipment_ids": [], "tower_equipment": {}, "tower_equipment_ids": []}, "unified")
	if not equipment_reward.is_empty():
		var rewarded_id := String(equipment_reward.get("effect", {}).get("item_id", ""))
		assert_true(catalog.has("equipment", rewarded_id), "tower equipment %s in catalog" % rewarded_id)


func test_monster_entries_match_runtime() -> void:
	var catalog := RuntimeCatalog.new()
	assert_equal(catalog.monster_units("normal").size(), DataCatalog.NORMAL_UNITS.size(), "normal units size")
	assert_equal(catalog.monster_units("elite").size(), DataCatalog.ELITE_UNITS.size(), "elite units size")
	assert_equal(catalog.monster_units("boss").size(), DataCatalog.BOSS_UNITS.size(), "boss units size")
	for unit in DataCatalog.NORMAL_UNITS + DataCatalog.ELITE_UNITS + DataCatalog.BOSS_UNITS:
		var unit_id := String(unit.get("id", ""))
		if unit_id != "":
			assert_true(catalog.has("monsters", unit_id), "monster %s in catalog" % unit_id)


func test_encounter_units_sourced_from_catalog() -> void:
	var catalog := RuntimeCatalog.new()
	var encounters := EncounterService.new(catalog)
	var encounter := encounters.generate_encounter(1, 1)
	assert_true(String(encounter.get("group_id", "")) != "", "encounter has group id")
	for unit in encounter.get("units", []):
		var unit_id := String(unit.get("id", ""))
		if unit_id != "":
			assert_true(catalog.has("monsters", unit_id), "encounter unit %s in catalog" % unit_id)


func test_reward_references_consistent() -> void:
	var catalog := RuntimeCatalog.new()
	var rewards := RewardService.new(catalog)
	var tutorial := rewards.tutorial_reward("unified", 1)
	var unlock_id := String(tutorial.get("effect", {}).get("unlock_id", ""))
	assert_true(unlock_id != "", "tutorial unlock id resolved")
	assert_true(catalog.has("equipment", unlock_id) or catalog.has("skills", unlock_id), "tutorial unlock %s in catalog" % unlock_id)
	var index_service := EncyclopediaIndexService.new(catalog)
	var index := index_service.build_index()
	assert_true(index["skills"].has(unlock_id) or index["items"].has(unlock_id), "tutorial unlock %s in encyclopedia" % unlock_id)


func test_trait_entries_consistent() -> void:
	var index_service := EncyclopediaIndexService.new()
	var index := index_service.build_index()
	assert_equal(index["traits"].size(), TraitCatalog.LABELS.size(), "trait index size")
	for trait_id in TraitCatalog.LABELS.keys():
		var normalized_id := String(trait_id)
		assert_true(index["traits"].has(normalized_id), "trait %s in index" % normalized_id)
		assert_equal(String(index["traits"][normalized_id].get("display_name", "")), String(TraitCatalog.LABELS[trait_id]), "trait %s display name" % normalized_id)
