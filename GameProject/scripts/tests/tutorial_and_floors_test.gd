extends SceneTree

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const RunSimulator = preload("res://scripts/core/run_simulator.gd")
const CombatEngine = preload("res://scripts/core/combat_engine.gd")
const Combatant = preload("res://scripts/core/combatant.gd")

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
	test_reward_attachment_flow()
	test_random_reward_pool_counts()
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
		"warrior_training_helm": {"hp": 3, "attack": 0, "armor": 1, "block": 0},
		"warrior_old_chest": {"hp": 4, "attack": 0, "armor": 1, "block": 1},
		"warrior_soldier_belt": {"hp": 2, "attack": 0, "armor": 0, "block": 0},
		"warrior_practice_greaves": {"hp": 3, "attack": 0, "armor": 1, "block": 1},
		"warrior_cloth_gloves": {"hp": 1, "attack": 0, "armor": 0, "block": 0},
		"warrior_old_leggings": {"hp": 2, "attack": 0, "armor": 1, "block": 0},
		"warrior_march_boots": {"hp": 1, "attack": 0, "armor": 0, "block": 0},
		"warrior_training_sword": {"hp": 0, "attack": 3, "armor": 0, "block": 0},
		"warrior_wooden_shield": {"hp": 0, "attack": 0, "armor": 2, "block": 2},
		"archer_practice_hood": {"hp": 3, "attack": 1, "armor": 0, "block": 0},
		"archer_old_leather": {"hp": 4, "attack": 0, "armor": 1, "block": 1},
		"archer_hunter_belt": {"hp": 2, "attack": 0, "armor": 0, "block": 0},
		"archer_light_pants": {"hp": 3, "attack": 0, "armor": 1, "block": 1},
		"archer_bracers": {"hp": 1, "attack": 0, "armor": 0, "block": 0},
		"archer_soft_leggings": {"hp": 2, "attack": 0, "armor": 1, "block": 0},
		"archer_light_boots": {"hp": 1, "attack": 0, "armor": 0, "block": 0},
		"archer_practice_bow": {"hp": 0, "attack": 3, "armor": 0, "block": 0},
		"archer_simple_quiver": {"hp": 0, "attack": 2, "armor": 0, "block": 2}
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
	var expected_hp := after_attack - int(session.player["attack"]) - int(skill.get("power", 0)) - bonus
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
