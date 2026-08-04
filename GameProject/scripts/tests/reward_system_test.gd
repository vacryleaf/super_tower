extends "res://scripts/tests/test_base.gd"

const TestHelpers = preload("res://scripts/tests/test_helpers.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const CharacterService = preload("res://scripts/core/character_service.gd")


func run() -> void:
	test_reward_attachment_flow()
	test_random_reward_pool_counts()
	test_equipment_slot_replacement()
	test_boss_tower_equipment_reward()
	test_reward_options_do_not_include_charge_rewards()
	test_huangqi_juice_three_use_heal()
	test_skill_bound_charge_only_triggers_on_that_skill()
	test_charge_limit()
	test_boss_skill_reward_slot_scope()
	test_boss_grants_tower_coins()
	test_tower_reward_rules()
	test_skill_shop_purchase()


func test_reward_attachment_flow() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			TestHelpers.force_win(session)
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
			TestHelpers.force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	session.phase = "reward"
	session.current_encounter = {"type": "normal"}
	session._build_reward_options()
	assert_true(session.reward_options.size() >= 3, "normal rewards should include at least three random options")
	assert_true(session._reward_pool("normal").size() > session.reward_options.size(), "normal reward pool should be larger than shown options")
	assert_true(TestHelpers.has_core_growth_reward(session.reward_options), "normal rewards should include at least one core growth option")

	session.current_encounter = {"type": "elite"}
	session._build_reward_options()
	assert_true(session.reward_options.size() >= 4, "elite rewards should include at least four random options")
	assert_true(TestHelpers.has_core_growth_reward(session.reward_options), "elite rewards should include at least one core growth option")

	session.current_encounter = {"type": "boss"}
	session._build_reward_options()
	assert_true(session.reward_options.size() >= 5, "boss rewards should include core, skill and equipment options")
	assert_true(TestHelpers.has_core_growth_reward(session.reward_options), "boss rewards should include at least one core growth option")
	assert_true(session.reward_options.any(func(reward: Dictionary): return String(reward.get("kind", "")) == "tower_skill"), "boss rewards should include a tower skill")
	assert_true(session.reward_options.any(func(reward: Dictionary): return String(reward.get("kind", "")) == "tower_equipment"), "boss rewards should include tower equipment")


func test_equipment_slot_replacement() -> void:
	var character := CharacterService.new()
	var player := character.create_character("warrior")
	character.equip_item(player, "common_moon_necklace")
	assert_equal(String(player["equipment"].get("accessory", "")), "common_moon_necklace", "first accessory should occupy accessory slot")
	character.equip_item(player, "common_moon_ring")
	assert_equal(String(player["equipment"].get("accessory", "")), "common_moon_ring", "second accessory should replace the single accessory slot")
	assert_true(not player.has("set_counts"), "set counts should not be created")
	assert_true(not player.has("active_set_effects"), "set effects should not be created")

func test_boss_tower_equipment_reward() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			TestHelpers.force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	session.phase = "reward"
	session.current_encounter = {"type": "boss"}
	session._build_reward_options()
	var equipment_index := -1
	for i in range(session.reward_options.size()):
		if String(session.reward_options[i].get("kind", "")) == "tower_equipment":
			equipment_index = i
			break
	assert_true(equipment_index >= 0, "boss rewards should include tower equipment")
	var reward: Dictionary = session.reward_options[equipment_index]
	var item_id := String(reward.get("item_id", ""))
	session.choose_reward(equipment_index)
	assert_true(session.player.get("tower_equipment_ids", []).has(item_id), "boss equipment should enter tower equipment")
	assert_true(not session.player.get("equipment_ids", []).has(item_id), "tower equipment should not enter permanent equipment")


func test_reward_options_do_not_include_charge_rewards() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			TestHelpers.force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	for encounter_type in ["normal", "elite", "boss"]:
		session.phase = "reward"
		session.current_encounter = {"type": encounter_type}
		session._build_reward_options()
		for reward in session.reward_options:
			assert_true(not String(reward.get("kind", "")).begins_with("charge_"), "%s rewards should not include charge kinds" % encounter_type)


func test_huangqi_juice_three_use_heal() -> void:
	assert_true(DataCatalog.CONSUMABLES.has("huangqi_juice"), "huangqi juice should exist in consumable catalog")
	assert_true(DataCatalog.STARTER_CONSUMABLES.has("huangqi_juice"), "huangqi juice should be a free starter consumable")
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	session.player["consumables"] = ["huangqi_juice", "", "", "", ""]
	session.player["hp"] = 10
	session.player["max_hp"] = 100
	session.phase = "battle"
	var charges: Array[Dictionary] = session.available_charges()
	assert_equal(charges.size(), 1, "huangqi juice should appear as one charge")
	var charge_id := String(charges[0].get("charge_id", ""))
	assert_true(charge_id != "", "huangqi juice charge should have an id")
	for expected_hp in [40, 70, 100]:
		session.charge_ready[charge_id] = true
		session.use_charge(charge_id)
		assert_equal(int(session.player["hp"]), expected_hp, "huangqi juice should heal 30 percent each use")
	assert_true(bool(session.charge_used.get(charge_id, false)), "huangqi juice should be exhausted after three uses")


func test_skill_bound_charge_only_triggers_on_that_skill() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			TestHelpers.force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	var skill_id: String = session.character.skill_id_for_slot(session.player, 0)
	var bonus := 11
	session.character.attach_reward(session.player, {"type": "skill", "id": skill_id}, {
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
	session.phase = "battle"
	session.current_encounter = {"type": "normal"}
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
	session.energy = 12
	session.player["critical_weight"] = 0
	session.player_attack(0)
	var after_attack := 999 - int(session.player["attack"])
	assert_equal(int(session.enemies[0]["hp"]), after_attack, "normal attack should not consume skill-bound charge")
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	session.has_acted = false
	session.energy = int(skill.get("energy_cost", 0))
	session.use_skill(0, 0)
	var expected_skill_damage := int(round(float(session.player["attack"]) * float(skill.get("multiplier", 1.0)))) + bonus
	var expected_hp := after_attack - expected_skill_damage
	assert_equal(int(session.enemies[0]["hp"]), expected_hp, "matching skill should consume skill-bound charge")


func test_charge_limit() -> void:
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
	for i in range(6):
		session.character.attach_reward(session.player, target, {
			"kind": "charge_bonus_damage",
			"label": "充能测试 %d" % i,
			"value": i + 1
		})
	assert_equal(session.available_charges().size(), 5, "player should hold at most five charges")

func test_boss_skill_reward_slot_scope() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	var reward_service: Variant = load("res://scripts/core/reward_service.gd").new()
	for _i in range(10):
		var reward: Dictionary = reward_service.tower_skill_reward("unified")
		assert_true([3, 4].has(int(DataCatalog.SKILLS[reward["skill_id"]].get("slot", 0))), "boss tower skill should use slot three or four")
	var passive_reward: Dictionary = reward_service.tower_passive_skill_reward()
	assert_equal(String(passive_reward.get("kind", "")), "tower_passive_skill", "boss may offer a passive skill reward")


func test_boss_grants_tower_coins() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			TestHelpers.force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	var coins_before: int = session.tower_coins
	session.current_encounter = {"type": "boss"}
	session.floor_index = 5
	TestHelpers.force_win(session)
	assert_equal(session.tower_coins, coins_before + 50, "floor five boss should grant ten times the effective tower level")
	session.save_game()
	session.delete_save()


func test_tower_reward_rules() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	session.tutorial_active = false
	session.floor_index = 4
	session.tower_bonus = 0
	session.current_encounter = {"type": "normal", "units": [{}]}
	assert_equal(session._tower_coin_reward(), 4, "normal reward should equal one times effective tower level")
	session.current_encounter = {"type": "elite", "units": [{}]}
	assert_equal(session._tower_coin_reward(), 12, "elite reward should equal three times effective tower level")
	session.current_encounter = {"type": "boss", "units": [{}]}
	assert_equal(session._tower_coin_reward(), 40, "boss reward should equal ten times effective tower level")
	assert_equal(DataCatalog.TOWER_CONSUMABLE_DROP_CHANCE, 0.20, "tower consumable drop chance should be twenty percent")
	assert_equal(DataCatalog.TOWER_EQUIPMENT_DROP_CHANCES["normal"], 0.10, "normal equipment drop chance should be ten percent")
	assert_equal(DataCatalog.TOWER_EQUIPMENT_DROP_CHANCES["elite"], 0.50, "elite equipment drop chance should be fifty percent")
	assert_equal(DataCatalog.TOWER_EQUIPMENT_DROP_CHANCES["boss"], 1.00, "boss equipment drop chance should be one hundred percent")
	session.delete_save()


func test_skill_shop_purchase() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	while session.is_tutorial():
		if session.phase == "battle":
			TestHelpers.force_win(session)
		elif session.phase == "reward":
			session.choose_reward(0)
	session.tower_coins = 30
	session.floor_index = 5
	session.current_encounter = {"type": "boss", "units": [{"id": "test_boss"}]}
	session._unlock_boss_npc(5)
	assert_true(session.end_run_to_camp(), "tutorial should return to camp before shop purchase")
	assert_true(session.is_shop_unlocked() == false, "merchant gate should be separate from mage")
	assert_true(session.is_npc_unlocked("mage"), "mage should be unlocked at floor five boss")
	var result: bool = session.buy_common_skill("first_aid")
	assert_true(result, "purchase should succeed with enough coins")
	assert_equal(session.tower_coins, 15, "tower_coins should decrease by 15")
	var profile = session.save_profile.read_profile(Callable(session, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	var warrior: Dictionary = roster.get("unified", {})
	assert_true(warrior.get("unlocked_skills", []).has("first_aid"), "unified role should have first_aid unlocked")
	var dup_result: bool = session.buy_common_skill("first_aid")
	assert_true(not dup_result, "duplicate purchase should fail")
	session.delete_save()
