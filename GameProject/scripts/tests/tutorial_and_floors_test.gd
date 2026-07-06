extends SceneTree

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const RunSimulator = preload("res://scripts/core/run_simulator.gd")
const CombatEngine = preload("res://scripts/core/combat_engine.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const DynamicValueResolver = preload("res://scripts/core/dynamic_value_resolver.gd")

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
	test_player_armor_baseline_is_low()
	test_basic_equipment_values()
	test_block_power_is_separate_from_armor()
	test_enemy_block_power_is_separate_from_armor()
	test_player_and_enemy_share_combatant_contract()
	test_thick_skin_always_grants_armor()
	test_enemy_roles_include_tank_taunt_and_backline()
	test_cunning_masks_enemy_intent()
	test_skill_costs_minimum_two()
	test_skill_multiplier_effects()
	test_counter_stance_and_multihit_dodge()
	test_reward_attachment_flow()
	test_random_reward_pool_counts()
	test_set_equipment_effects()
	test_boss_permanent_equipment_reward()
	test_external_resource_manifests()
	test_charge_reward_flow()
	test_skill_bound_charge_only_triggers_on_that_skill()
	test_charge_limit()
	test_save_round_trip()
	test_end_run_to_camp_clears_active_run()
	test_profile_keeps_multiple_classes()
	test_block_expires_each_round()
	test_tutorial_unlocks("warrior")
	test_tutorial_unlocks("archer")
	test_encounter_generation()
	test_circus_set_juggling()
	test_jungle_set_meticulous()
	test_late_battles_are_stronger_than_openers()
	test_baseline_campaign_difficulty_gate("warrior")
	test_baseline_campaign_difficulty_gate("archer")


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


func test_block_power_is_separate_from_armor() -> void:
	assert_equal(int(DataCatalog.CLASSES["warrior"]["base_block"]), 5, "warrior base block")
	assert_equal(int(DataCatalog.CLASSES["archer"]["base_block"]), 3, "archer base block")
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("archer")
	session.player["defense"] = 0
	session.player["block_power"] = 7
	session.player_defend()
	assert_equal(int(session.player_block), 7, "defend should use block power even when armor is zero")


func test_enemy_block_power_is_separate_from_armor() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	var enemy := {
		"name": "格挡测试敌人",
		"rank": "normal",
		"max_hp": 100,
		"hp": 100,
		"attack": 1,
		"defense": 3,
		"armor": 3,
		"block_power": 9,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": []
	}
	var gained: int = session._enemy_defend(enemy, 1.0)
	assert_equal(gained, 9, "enemy defend should use block power")
	assert_equal(int(enemy["armor"]), 3, "enemy defend should not increase armor")
	assert_equal(int(enemy["block"]), 9, "enemy defend should increase current block")
	var test_enemies: Array[Dictionary] = [enemy]
	session.enemies = test_enemies
	session._apply_damage_to_enemy(0, 30)
	assert_true(int(session.enemies[0]["hp"]) < 100, "damage should pass after armor and block")
	assert_true(int(session.enemies[0]["block"]) < 9, "enemy block should absorb part of incoming damage")


func test_player_and_enemy_share_combatant_contract() -> void:
	var simulator := RunSimulator.new()
	var player := simulator.create_character("warrior")
	var player_unit := Combatant.from_player(player, 0, 0)
	var enemy_unit := Combatant.from_enemy_unit({
		"name": "统一模板测试敌人",
		"rank": "normal",
		"hp": 30,
		"attack": 5,
		"defense": 2,
		"traits": []
	}, "normal", 1)
	for key in ["side", "rank", "max_hp", "hp", "attack", "defense", "armor", "block_power", "block", "dodge_layers", "taunt", "traits"]:
		assert_true(player_unit.has(key), "player combatant has %s" % key)
		assert_true(enemy_unit.has(key), "enemy combatant has %s" % key)
	var player_damage := Combatant.apply_damage(player_unit, 20)
	var enemy_damage := Combatant.apply_damage(enemy_unit, 20)
	assert_true(int(player_damage["damage"]) > 0, "player combatant should take resolved damage")
	assert_true(int(enemy_damage["damage"]) > 0, "enemy combatant should take resolved damage")


func test_thick_skin_always_grants_armor() -> void:
	var combat := CombatEngine.new()
	var enemy := combat.scale_enemy({
		"name": "厚皮测试",
		"hp": 1.0,
		"attack": 1.0,
		"defense": 0.0,
		"traits": ["thick_skin"]
	}, 1, "normal", 1.0)
	assert_true(int(enemy["armor"]) >= 1, "thick skin should grant at least one armor")

	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	var loaded_enemies: Array[Dictionary] = [{
		"name": "旧存档厚皮",
		"rank": "normal",
		"max_hp": 10,
		"hp": 10,
		"attack": 1,
		"defense": 0,
		"armor": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": ["thick_skin"]
	}]
	session.enemies = loaded_enemies
	session._normalize_loaded_enemies()
	assert_true(int(session.enemies[0]["armor"]) >= 1, "loaded thick skin enemy should recover armor")


func test_enemy_roles_include_tank_taunt_and_backline() -> void:
	var has_taunt_tank := false
	var has_backline := false
	for unit in DataCatalog.NORMAL_UNITS + DataCatalog.ELITE_UNITS + DataCatalog.BOSS_UNITS:
		var traits: Array = unit.get("traits", [])
		has_taunt_tank = has_taunt_tank or (traits.has("tank") and traits.has("taunt"))
		has_backline = has_backline or traits.has("backline")
	assert_true(has_taunt_tank, "enemy catalog should include taunting tank")
	assert_true(has_backline, "enemy catalog should include backline output")


func test_cunning_masks_enemy_intent() -> void:
	var has_cunning := false
	for unit in DataCatalog.NORMAL_UNITS + DataCatalog.ELITE_UNITS + DataCatalog.BOSS_UNITS:
		var traits: Array = unit.get("traits", [])
		has_cunning = has_cunning or traits.has("cunning")
	assert_true(has_cunning, "enemy catalog should include cunning enemies")

	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	session.enemies.clear()
	session.enemies.append({
		"name": "狡诈测试敌人",
		"rank": "normal",
		"max_hp": 10,
		"hp": 10,
		"attack": 5,
		"defense": 1,
		"armor": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": ["cunning", "evade"]
	})
	assert_equal(session.enemy_intent_text(0), "狡诈", "cunning should mask true intent")


func test_skill_costs_minimum_two() -> void:
	for skill_id in DataCatalog.SKILLS.keys():
		assert_true(int(DataCatalog.SKILLS[skill_id].get("cost", 0)) >= 2, "%s skill cost minimum two" % skill_id)
		assert_true(not DataCatalog.SKILLS[skill_id].has("power"), "%s skill should use multipliers instead of flat power" % skill_id)


func test_skill_multiplier_effects() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var warrior = session_script.new()
	warrior.start_new_game("warrior")
	warrior.player["equipped_skills"] = ["war_cry"]
	warrior.action_points = 3
	warrior.use_skill(0, 0)
	var statuses: Array = warrior.player.get("statuses", [])
	assert_true(statuses.size() > 0, "war cry should add a status to player")
	var resolved_attack: float = warrior.status_service.resolve_stat(warrior.player, float(warrior.player["attack"]), StatusService.STAT_ATTACK)
	assert_true(resolved_attack > float(warrior.player["attack"]), "war cry should increase resolved attack via status")

	var archer = session_script.new()
	archer.start_new_game("archer")
	archer.player["equipped_skills"] = ["hunter_mark"]
	archer.player["attack"] = 10
	var marked_enemies: Array[Dictionary] = [{
		"name": "标记测试敌人",
		"rank": "normal",
		"max_hp": 100,
		"hp": 100,
		"attack": 0,
		"defense": 0,
		"armor": 0,
		"block_power": 1,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": []
	}]
	archer.enemies = marked_enemies
	archer.action_points = 3
	archer.use_skill(0, 0)
	assert_true(archer.enemies[0].get("statuses", []).size() > 0, "hunter mark should add a debuff status to enemy")
	var dmg_mult: float = archer.status_service.resolve_stat(archer.enemies[0], 1.0, StatusService.STAT_DAMAGE_TAKEN)
	assert_true(dmg_mult > 1.0, "hunter mark should increase damage taken multiplier")
	archer.player_attack(0)
	assert_true(int(archer.enemies[0]["hp"]) < 90, "hunter mark should amplify following attack damage")


func test_counter_stance_and_multihit_dodge() -> void:
	var session_script = load("res://scripts/core/play_session.gd")

	var warrior = session_script.new()
	warrior.start_new_game("warrior")
	warrior.player["equipped_skills"] = ["counter_stance"]
	warrior.player["attack"] = 10
	var counter_enemies: Array[Dictionary] = [_test_enemy("反击测试敌人", 100, 1, [])]
	warrior.enemies = counter_enemies
	warrior.action_points = 3
	warrior.use_skill(0, 0)
	warrior._enemy_attack(warrior.enemies[0], 0, false)
	assert_true(int(warrior.enemies[0]["hp"]) < 100, "counter stance should counterattack after being hit")
	assert_equal(int(warrior.counter_stance_charges), 0, "counter stance should consume one counter charge")

	var archer = session_script.new()
	archer.start_new_game("archer")
	archer.player["equipped_skills"] = ["quick_shot"]
	archer.player["attack"] = 10
	var dodging_enemies: Array[Dictionary] = [_test_enemy("闪避测试敌人", 100, 0, [])]
	dodging_enemies[0]["dodge_layers"] = 1
	archer.enemies = dodging_enemies
	archer.action_points = 3
	archer.use_skill(0, 0)
	assert_equal(int(archer.enemies[0]["hp"]), 82, "quick shot should only lose its first hit to one dodge layer")

	var dodger = session_script.new()
	dodger.start_new_game("warrior")
	dodger.player["hp"] = 100
	dodger.player["defense"] = 0
	dodger.player_block = 0
	dodger.dodge_layers = 1
	var swarm_enemies: Array[Dictionary] = [_test_enemy("多段测试敌人", 100, 10, ["swarm"])]
	dodger.enemies = swarm_enemies
	dodger._enemy_attack(dodger.enemies[0], 0, false)
	assert_equal(int(dodger.dodge_layers), 0, "one dodge layer should be consumed by the first hit only")
	assert_true(int(dodger.player["hp"]) < 100, "later hits in a multi-hit attack should still deal damage")


func _test_enemy(enemy_name: String, hp: int, attack: int, traits: Array) -> Dictionary:
	return {
		"name": enemy_name,
		"rank": "normal",
		"max_hp": hp,
		"hp": hp,
		"attack": attack,
		"defense": 0,
		"armor": 0,
		"block_power": 1,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": traits
	}


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


func test_random_reward_pool_counts() -> void:
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
	assert_equal(session.reward_options.size(), 3, "normal rewards should be three random options")
	assert_true(session._reward_pool("normal").size() > session.reward_options.size(), "normal reward pool should be larger than shown options")
	assert_true(_has_core_growth_reward(session.reward_options), "normal rewards should include at least one core growth option")

	session.current_encounter = {"type": "elite"}
	session._build_reward_options()
	assert_equal(session.reward_options.size(), 4, "elite rewards should be four random options")
	assert_true(_has_core_growth_reward(session.reward_options), "elite rewards should include at least one core growth option")

	session.current_encounter = {"type": "boss"}
	session._build_reward_options()
	assert_equal(session.reward_options.size(), 5, "boss rewards should show five options")
	assert_true(_has_core_growth_reward(session.reward_options), "boss rewards should include at least one core growth option")
	var has_skill := false
	for reward in session.reward_options:
		has_skill = has_skill or String(reward.get("kind", "")) == "skill"
	assert_true(has_skill, "boss rewards should keep a skill branch while randomizing the other options")


func _has_core_growth_reward(rewards: Array[Dictionary]) -> bool:
	for reward in rewards:
		if ["attack", "defense", "hp"].has(String(reward.get("kind", ""))):
			return true
	return false


func test_set_equipment_effects() -> void:
	var simulator := RunSimulator.new()
	var player := simulator.create_character("warrior")
	simulator.equip_item(player, "common_moon_necklace")
	simulator.equip_item(player, "common_moon_ring")
	simulator._recalculate_player_stats(player, true)
	var effects: Dictionary = player.get("active_set_effects", {})
	assert_equal(int(effects.get("set_requirement_delta", 0)), 1, "moon pair should reduce set requirements")
	assert_true(player.get("set_counts", {}).has("moon_pair"), "set count should include moon pair")


func test_boss_permanent_equipment_reward() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			_force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	session.phase = "reward"
	session.current_encounter = {"type": "boss"}
	session._build_reward_options()
	var equipment_index := -1
	for i in range(session.reward_options.size()):
		if String(session.reward_options[i].get("kind", "")) == "permanent_equipment":
			equipment_index = i
			break
	assert_true(equipment_index >= 0, "boss rewards should include permanent equipment")
	var reward: Dictionary = session.reward_options[equipment_index]
	var item_id := String(reward.get("item_id", ""))
	session.choose_reward(equipment_index)
	assert_true(session.player.get("equipment_ids", []).has(item_id), "permanent boss equipment should enter player equipment")


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
				_assert_catalog_value_equal(external_entry[field], runtime_entry[field], "%s.%s.%s parity" % [table_name, entry_id, field])


func test_charge_reward_flow() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			_force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	session.phase = "reward"
	var bonus := 8
	var forced_rewards: Array[Dictionary] = [{"kind": "charge_bonus_damage", "label": "充能测试：下一次攻击附加 8 点伤害", "value": bonus}]
	session.reward_options = forced_rewards
	session.choose_reward(0)
	assert_equal(session.phase, "reward_target", "charge reward should request attachment target")
	session.choose_reward_target(0)
	var charges: Array[Dictionary] = session.available_charges()
	assert_true(charges.size() > 0, "attached charge should be available in next battle")
	var charge_id := String(charges[0].get("charge_id", ""))
	assert_true(bool(charges[0].get("ready", false)), "one charge should become ready at player turn start")
	var test_enemies: Array[Dictionary] = [{
		"name": "充能测试敌人",
		"rank": "normal",
		"max_hp": 999,
		"hp": 999,
		"attack": 0,
		"defense": 0,
		"armor": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": []
	}]
	session.enemies = test_enemies
	session.action_points = 1
	session.use_charge(charge_id)
	assert_true(bool(session.charge_used.get(charge_id, false)), "charge should be marked used after activation")
	session.player_attack(0)
	var expected_hp := 999 - int(session.player["attack"]) - bonus
	assert_equal(int(session.enemies[0]["hp"]), expected_hp, "charge bonus damage should apply to next attack")


func test_skill_bound_charge_only_triggers_on_that_skill() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			_force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	var skill_id := String(session.player["equipped_skills"][0])
	var bonus := 11
	session.simulator.attach_reward(session.player, {"type": "skill", "id": skill_id}, {
		"kind": "charge_bonus_damage",
		"label": "技能绑定充能测试",
		"value": bonus
	})
	var charges: Array[Dictionary] = session.available_charges()
	var charge_id := ""
	for charge in charges:
		if String(charge.get("target_type", "")) == "skill" and String(charge.get("target_id", "")) == skill_id:
			charge_id = String(charge.get("charge_id", ""))
			break
	assert_true(charge_id != "", "skill-bound charge should be listed")
	session.charge_ready[charge_id] = true
	session.use_charge(charge_id)
	var test_enemies: Array[Dictionary] = [{
		"name": "技能充能测试敌人",
		"rank": "normal",
		"max_hp": 999,
		"hp": 999,
		"attack": 0,
		"defense": 0,
		"armor": 0,
		"block_power": 1,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": []
	}]
	session.enemies = test_enemies
	session.action_points = 3
	session.player_attack(0)
	var after_attack := 999 - int(session.player["attack"])
	assert_equal(int(session.enemies[0]["hp"]), after_attack, "normal attack should not consume skill-bound charge")
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	session.use_skill(0, 0)
	var expected_skill_damage := int(round(float(session.player["attack"]) * float(skill.get("multiplier", 1.0)))) + bonus
	var expected_hp := after_attack - expected_skill_damage
	assert_equal(int(session.enemies[0]["hp"]), expected_hp, "matching skill should consume skill-bound charge")


func test_charge_limit() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			_force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	var target := {"type": "equipment", "id": String(session.player["equipment_ids"][0])}
	for i in range(6):
		session.simulator.attach_reward(session.player, target, {
			"kind": "charge_bonus_damage",
			"label": "充能测试 %d" % i,
			"value": i + 1
		})
	assert_equal(session.available_charges().size(), 5, "player should hold at most five charges")


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
			_force_win(session)
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
	assert_true(_dictionary_total(roster_player.get("equipment_attachments", {})) == 0, "tower equipment attachments should not persist")
	session.delete_save()


func _dictionary_total(groups: Dictionary) -> int:
	var total := 0
	for values in groups.values():
		total += values.size()
	return total


func test_profile_keeps_multiple_classes() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var warrior_session = session_script.new()
	warrior_session.delete_save()
	warrior_session.start_new_game("warrior")
	_force_win(warrior_session)
	warrior_session.choose_reward(0)
	assert_true(warrior_session.save_game(), "warrior profile save")

	var archer_session = session_script.new()
	archer_session.start_new_game("archer")
	_force_win(archer_session)
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


func test_block_expires_each_round() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	session.player_block = 999
	session.end_turn()
	assert_equal(int(session.player_block), 0, "block should expire when next player turn begins")


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
			opener_total += _encounter_threat(combat, simulator.generate_encounter(tower_floor, battle_index), tower_floor)
		var late_total := 0.0
		for battle_index in range(4, 10):
			late_total += _encounter_threat(combat, simulator.generate_encounter(tower_floor, battle_index), tower_floor)
		assert_true((late_total / 6.0) > (opener_total / 3.0), "floor %d battles 4-9 average threat should exceed battles 1-3" % tower_floor)


func test_baseline_campaign_difficulty_gate(class_id: String) -> void:
	var simulator := RunSimulator.new()
	var floor_five := simulator.run_campaign(class_id, 5)
	assert_true(floor_five["success"], "%s baseline campaign should clear floor 5, failed at floor %d battle %d" % [
		class_id,
		int(floor_five.get("failed_floor", 0)),
		_failed_battle(floor_five)
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
		assert_true(_has_no_duplicates(player["unlocked_skills"]), "%s skill unlocks must not duplicate" % class_id)

		for floor_summary in floor_five["floor_summaries"]:
			assert_equal(int(floor_summary["battles"]), 10, "%s floor %d has ten battles" % [class_id, int(floor_summary["floor"])])

	var deep_attempt := simulator.run_campaign(class_id, 10)
	assert_true(not bool(deep_attempt["success"]), "%s baseline campaign should not clear floor 10 without stronger set synergies" % class_id)
	assert_true(int(deep_attempt["failed_floor"]) >= 6, "%s baseline failure should happen after floor 5, got floor %d battle %d" % [
		class_id,
		int(deep_attempt.get("failed_floor", 0)),
		_failed_battle(deep_attempt)
	])


func _force_win(session) -> void:
	for enemy in session.enemies:
		enemy["hp"] = 0
	session._on_victory()


func _encounter_threat(combat: CombatEngine, encounter: Dictionary, tower_floor: int) -> float:
	var total := 0.0
	for enemy in combat._build_enemies(encounter, tower_floor):
		total += float(enemy["max_hp"]) + float(enemy["attack"]) * 5.0 + float(enemy["defense"]) * 2.5 + float(enemy["armor"]) + float(enemy.get("block_power", 0))
	return total


func _failed_battle(result: Dictionary) -> int:
	var summaries: Array = result.get("floor_summaries", [])
	if summaries.is_empty():
		return 0
	var last: Dictionary = summaries[summaries.size() - 1]
	return int(last.get("battle", 0))


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


func _assert_catalog_value_equal(actual, expected, message: String) -> void:
	if typeof(actual) == TYPE_FLOAT or typeof(expected) == TYPE_FLOAT:
		if absf(float(actual) - float(expected)) > 0.001:
			failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
		return
	assert_equal(actual, expected, message)


func test_circus_set_juggling() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	# 清除教程状态
	while session.is_tutorial():
		if session.phase == "battle":
			_force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	# 装备4件马戏团装备
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
	# 验证套装效果已应用
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
	# 开始战斗，验证 status 被添加到玩家
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
	# 给玩家添加躲避层数
	session._add_player_dodge(5)
	# 模拟敌人攻击被闪避
	var enemy: Dictionary = session.enemies[0]
	session.battle_service.enemy_attack(session, enemy, 0, false)
	# 验证闪避计数
	assert_equal(session.dodge_streak, 1, "dodge streak should be 1 after first dodge")
	# 再闪避一次触发表演
	session._add_player_dodge(5)
	session.battle_service.enemy_attack(session, enemy, 0, false)
	# 表演效果触发后，闪避计数应重置
	assert_equal(session.dodge_streak, 0, "dodge streak should reset after performance triggers")


func test_jungle_set_meticulous() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("archer")
	while session.is_tutorial():
		if session.phase == "battle":
			_force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	# 装备6件丛林装备
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
	# 验证套装效果
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
	# 开始战斗
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
	# 初始状态：缜密0层，寻绽1层（首回合 _begin_player_turn 已触发）
	assert_equal(session.meticulous_stacks, 0, "meticulous should start at 0")
	assert_equal(session.seek_bloom_stacks, 1, "seek_bloom should be 1 after first turn start")
	# 闪避1次，缜密变为1层
	session._add_player_dodge(5)
	var enemy: Dictionary = session.enemies[0]
	session.battle_service.enemy_attack(session, enemy, 0, false)
	assert_equal(session.meticulous_stacks, 1, "meticulous should be 1 after one dodge")
	# 被击中，缜密重置
	session.dodge_layers = 0
	session.battle_service.enemy_attack(session, enemy, 0, false)
	assert_equal(session.meticulous_stacks, 0, "meticulous should reset after being hit")
	# 闪避5次，缜密最多5层
	session._add_player_dodge(10)
	for i in range(5):
		session.battle_service.enemy_attack(session, enemy, 0, false)
	assert_equal(session.meticulous_stacks, 5, "meticulous should cap at 5 stacks")
	# 不攻击的回合，寻绽计数增加（从1开始，首回合已计）
	session.attacked_this_turn = false
	session._begin_player_turn()
	assert_equal(session.seek_bloom_stacks, 2, "seek_bloom should be 2 after two non-attack turns")
	session.attacked_this_turn = false
	session._begin_player_turn()
	assert_equal(session.seek_bloom_stacks, 3, "seek_bloom should cap at 3 stacks")
	# 验证狩猎 bonus：缜密5层 + 寻绽3层 = 1.5 * 1.9 = 2.85
	var hunt_bonus := DynamicValueResolver.resolve("dynamic:hunt", session.player, {"meticulous_stacks": 5, "seek_bloom_stacks": 3})
	assert_true(abs(hunt_bonus - 2.85) < 0.001, "hunt bonus should be 2.85 with 5 meticulous + 3 seek_bloom")
	# 造成伤害后，缜密和寻绽应重置
	session.action_points = 1
	session.player_attack(0)
	assert_equal(session.meticulous_stacks, 0, "meticulous should reset after dealing damage")
	assert_equal(session.seek_bloom_stacks, 0, "seek_bloom should reset after dealing damage")
