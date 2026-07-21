extends "res://scripts/tests/test_base.gd"

const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func run() -> void:
	test_state_card_weights()
	test_player_armor_baseline_is_low()
	test_basic_equipment_values()
	test_enemy_roles_include_tank_taunt_and_backline()
	test_monster_groups_are_complete()
	test_cunning_masks_enemy_intent()
	test_skill_costs_minimum_two()
	test_external_resource_manifests()
	test_external_runtime_field_parity()


func test_state_card_weights() -> void:
	assert_equal(DataCatalog.get_state_weight_total(), 100, "state card weights must total 100")
	assert_equal(int(DataCatalog.STATE_CARDS["critical"]["weight"]), 5, "critical state card weight")
	assert_equal(int(DataCatalog.STATE_CARDS["read"]["weight"]), 5, "read state card weight")
	assert_equal(int(DataCatalog.STATE_CARDS["perfect_guard"]["weight"]), 5, "perfect guard state card weight")
	assert_equal(int(DataCatalog.STATE_CARDS["fallback"]["weight"]), 5, "emergency fallback state card weight")


func test_player_armor_baseline_is_low() -> void:
	assert_equal(int(DataCatalog.CLASSES["warrior"]["base_defense"]), 1, "warrior base armor")
	assert_equal(int(DataCatalog.CLASSES["archer"]["base_defense"]), 0, "archer base armor")
	for item_id in DataCatalog.EQUIPMENT.keys():
		assert_true(int(DataCatalog.EQUIPMENT[item_id]["armor"]) <= 2, "%s equipment armor cap" % item_id)
		assert_true(DataCatalog.EQUIPMENT[item_id].has("block"), "%s equipment has block" % item_id)


func test_basic_equipment_values() -> void:
	var expected := {
		"warrior_training_helm": {"hp": 5, "attack": 0, "armor": 1, "block": 1},
		"warrior_old_chest": {"hp": 7, "attack": 0, "armor": 1, "block": 2},
		"warrior_soldier_belt": {"hp": 4, "attack": 0, "armor": 0, "block": 1},
		"warrior_practice_greaves": {"hp": 5, "attack": 0, "armor": 1, "block": 1},
		"warrior_cloth_gloves": {"hp": 2, "attack": 0, "armor": 0, "block": 0},
		"warrior_old_leggings": {"hp": 4, "attack": 0, "armor": 1, "block": 1},
		"warrior_march_boots": {"hp": 3, "attack": 0, "armor": 0, "block": 0},
		"warrior_training_sword": {"hp": 0, "attack": 4, "armor": 0, "block": 0},
		"warrior_wooden_shield": {"hp": 0, "attack": 0, "armor": 2, "block": 2},
		"archer_practice_hood": {"hp": 4, "attack": 1, "armor": 0, "block": 1},
		"archer_old_leather": {"hp": 6, "attack": 0, "armor": 1, "block": 1},
		"archer_hunter_belt": {"hp": 4, "attack": 0, "armor": 0, "block": 1},
		"archer_light_pants": {"hp": 5, "attack": 0, "armor": 1, "block": 1},
		"archer_bracers": {"hp": 2, "attack": 0, "armor": 0, "block": 0},
		"archer_soft_leggings": {"hp": 3, "attack": 0, "armor": 1, "block": 1},
		"archer_light_boots": {"hp": 2, "attack": 0, "armor": 0, "block": 0},
		"archer_practice_bow": {"hp": 0, "attack": 3, "armor": 0, "block": 0},
		"archer_simple_quiver": {"hp": 0, "attack": 2, "armor": 1, "block": 2}
	}
	for item_id in expected.keys():
		var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
		var values: Dictionary = expected[item_id]
		for key in values.keys():
			assert_equal(int(item[key]), int(values[key]), "%s %s value" % [item_id, key])


func test_enemy_roles_include_tank_taunt_and_backline() -> void:
	var has_taunt_tank := false
	var has_backline := false
	for unit in DataCatalog.NORMAL_UNITS + DataCatalog.ELITE_UNITS + DataCatalog.BOSS_UNITS:
		var passive_skills: Array = unit.get("passive_skills", [])
		assert_equal(passive_skills.size(), 4, "%s should have four passive skill slots" % String(unit.get("name", "unit")))
		has_taunt_tank = has_taunt_tank or (passive_skills.has("tank") and passive_skills.has("taunt"))
		has_backline = has_backline or passive_skills.has("backline")
	assert_true(has_taunt_tank, "enemy catalog should include taunting tank")
	assert_true(has_backline, "enemy catalog should include backline output")


func test_monster_groups_are_complete() -> void:
	var group_ids := DataCatalog.monster_group_ids()
	assert_true(not group_ids.is_empty(), "monster groups should not be empty")
	for group_id in group_ids:
		var group_name := DataCatalog.monster_group_name(group_id)
		assert_true(group_name != "", "%s should have a name" % group_id)
		assert_true(not DataCatalog.monster_group_units(group_id, "normal").is_empty(), "%s should have normal units" % group_id)
		assert_true(not DataCatalog.monster_group_units(group_id, "elite").is_empty(), "%s should have elite units" % group_id)
		assert_true(not DataCatalog.monster_group_units(group_id, "boss").is_empty(), "%s should have boss units" % group_id)
	for rank in ["normal", "elite", "boss"]:
		for unit in DataCatalog.monster_group_units("rat", rank):
			assert_true(unit.get("passive_skills", []).has("swarm"), "%s should have swarm passive" % String(unit.get("name", "rat unit")))


func test_cunning_masks_enemy_intent() -> void:
	var has_cunning := false
	for unit in DataCatalog.NORMAL_UNITS + DataCatalog.ELITE_UNITS + DataCatalog.BOSS_UNITS:
		var passive_skills: Array = unit.get("passive_skills", [])
		has_cunning = has_cunning or passive_skills.has("cunning")
	assert_true(has_cunning, "enemy catalog should include cunning enemies")

	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	var enemies: Array[Dictionary] = [{
		"name": "狡诈测试敌人",
		"rank": "normal",
		"max_hp": 10,
		"hp": 10,
		"attack": 5,
		"defense": 1,
		"armor": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"passive_skills": ["cunning", "evade", "", ""]
	}]
	session.enemies = enemies
	assert_equal(session.enemy_intent_text(0), "狡诈", "cunning should mask true intent")


func test_skill_costs_minimum_two() -> void:
	for skill_id in DataCatalog.SKILLS.keys():
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		if String(skill.get("class", "")) == "enemy":
			continue
		assert_true(int(skill.get("energy_cost", 0)) >= 2 or int(skill.get("cooldown", 0)) > 0, "%s skill must have energy_cost or cooldown" % skill_id)
		assert_true(not skill.has("power"), "%s skill should use multipliers instead of flat power" % skill_id)


func test_external_resource_manifests() -> void:
	var tables := DataCatalog.external_catalog_tables()
	assert_true(tables.has("equipment_sets"), "external catalog should list equipment sets")
	assert_true(tables.has("equipment_manifest"), "external catalog should list equipment manifest")
	assert_true(tables.has("enemy_unit_manifest"), "external catalog should list enemy unit manifest")
	var equipment_manifest := DataCatalog.external_table("equipment_manifest")
	assert_true(equipment_manifest.get("set_equipment", []).size() >= 2, "equipment manifest should include set equipment")
	var enemy_manifest := DataCatalog.external_table("enemy_unit_manifest")
	assert_true(enemy_manifest.get("boss", []).size() >= 5, "enemy manifest should include boss ids")


func test_external_runtime_field_parity() -> void:
	var migrated_tables := {
		"state_cards": DataCatalog.STATE_CARDS,
		"classes": DataCatalog.CLASSES,
		"skills": DataCatalog.SKILLS
	}
	for table_name in migrated_tables.keys():
		var external_table := DataCatalog.external_table(table_name)
		var runtime_table: Dictionary = migrated_tables[table_name]
		for entry_id in external_table.keys():
			assert_true(runtime_table.has(entry_id), "%s.%s should exist in runtime catalog" % [table_name, entry_id])
			var external_entry: Dictionary = external_table[entry_id]
			var runtime_entry: Dictionary = runtime_table[entry_id]
			for field in external_entry.keys():
				assert_true(runtime_entry.has(field), "%s.%s.%s should exist in runtime catalog" % [table_name, entry_id, field])
				assert_catalog_value_equal(external_entry[field], runtime_entry[field], "%s.%s.%s parity" % [table_name, entry_id, field])
