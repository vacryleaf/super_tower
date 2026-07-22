extends "res://scripts/tests/test_base.gd"

const TestHelpers = preload("res://scripts/tests/test_helpers.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const RunSimulator = preload("res://scripts/core/run_simulator.gd")
const CombatEngine = preload("res://scripts/core/combat_engine.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const CombatRules = preload("res://scripts/core/combat_rules.gd")
const TriggerEvents = preload("res://scripts/core/trigger_events.gd")


func run() -> void:
	test_block_power_is_separate_from_armor()
	test_enemy_block_power_is_separate_from_armor()
	test_player_and_enemy_share_combatant_contract()
	test_thick_skin_always_grants_armor()
	test_rat_corruption_and_armor_reduction()
	test_swarm_triggers_one_assist_per_living_ally()
	test_hidden_targets_require_visible_fallback()
	test_curse_refreshes_instead_of_stacking()
	test_toxic_mist_uses_holder_attack()
	test_new_units_wait_one_round()
	test_skill_multiplier_effects()
	test_counter_stance_and_multihit_dodge()
	test_block_expires_each_round()
	test_enemy_skill_execution()
	test_enemy_ai_skill_selection()
	test_enemy_taunt_skill()
	test_rank_skill_multiplier()
	test_skeleton_passive_damage_rules()
	test_skeleton_taunt_requires_an_ally()


func test_rat_corruption_and_armor_reduction() -> void:
	var status_service := StatusService.new()
	var player := {"hp": 100, "max_hp": 100, "defense": 1, "statuses": []}
	CombatRules.apply_corruption(player, 10, status_service)
	CombatRules.apply_corruption(player, 15, status_service)
	for _turn in range(3):
		CombatRules.resolve_corruption(player)
	assert_equal(int(player["hp"]), 91, "corruption should refresh and use the last hit attack value")
	CombatRules.apply_armor_reduction(player, 3, status_service, "测试减防")
	var combatant := Combatant.from_player(player, 0, 0, status_service)
	assert_equal(int(combatant["armor"]), -2, "armor reduction should allow negative defense")


func test_skeleton_passive_damage_rules() -> void:
	var armored_target := {"hp": 100, "armor": 10, "block": 0, "dodge_layers": 0}
	var damage_result := Combatant.apply_damage(armored_target, 30, "physical", 0.80)
	assert_equal(int(damage_result["damage"]), 24, "break armor should ignore 20 percent of armor")
	assert_equal(int(CombatRules.shadow_armor_reflect_damage({"damage_before_block": 10, "block_absorbed": 5, "block_broken": true, "damage": 5})), 10, "shadow armor should reflect twice when block breaks")
	var protected_target := {"hp": 100, "passive_skills": ["", "", "", ""]}
	var guard := {"hp": 100, "passive_skills": ["guard", "", "", ""]}
	assert_equal(CombatRules.ally_guard_damage_multiplier(protected_target, [protected_target, guard]), 0.80, "living guard should protect teammates")
	assert_equal(CombatRules.ally_guard_damage_multiplier(guard, [protected_target, guard]), 1.0, "guard should not protect itself")
	guard["hp"] = 0
	assert_equal(CombatRules.ally_guard_damage_multiplier(protected_target, [protected_target, guard]), 1.0, "dead guard should not protect teammates")
	var status_service := StatusService.new()
	var enraged := {"hp": 49, "max_hp": 100, "statuses": [], "passive_skills": ["enrage", "", "", ""]}
	Combatant.normalize_enemy(enraged)
	assert_equal(int(status_service.resolve_stat(enraged, 10.0, "attack")), 15, "enrage should increase damage below half health")
	assert_equal(status_service.resolve_stat(enraged, 1.0, "damage_taken"), 1.30, "enrage should increase damage taken below half health")


func test_skeleton_taunt_requires_an_ally() -> void:
	var EnemyActionRules = preload("res://scripts/core/enemy_action_rules.gd")
	var rules = EnemyActionRules.new()
	var skeleton := {
		"hp": 50, "max_hp": 50,
		"behavior_weights": {"enemy_skeleton_taunt": 40},
		"skill_cooldowns": {},
		"innate_skills": {"attack_1": "innate_attack_1"}
	}
	assert_equal(rules.choose_skill(skeleton, 1, {}, true), "innate_attack_1", "taunt should be unavailable when alone")
	skeleton["skill_cooldowns"] = {"enemy_skeleton_taunt": 2}
	assert_equal(rules.choose_skill(skeleton, 1, {}, false), "innate_attack_1", "taunt should respect cooldown")


func test_hidden_targets_require_visible_fallback() -> void:
	var hidden_enemy := {"hp": 10, "passive_skills": ["hidden", "", "", ""]}
	var visible_enemy := {"hp": 10, "passive_skills": ["", "", "", ""]}
	assert_equal(CombatRules.valid_target([hidden_enemy, visible_enemy], 0), 1, "hidden enemy should be skipped while visible targets exist")
	assert_equal(CombatRules.valid_target([hidden_enemy], 0), 0, "hidden enemy should still be targetable when alone")


func test_curse_refreshes_instead_of_stacking() -> void:
	var status_service := StatusService.new()
	var attacker := Combatant.from_enemy_unit({
		"name": "诅咒测试施法者",
		"rank": "normal",
		"hp": 20,
		"attack": 10,
		"defense": 0,
		"passive_skills": ["curse", "", "", ""],
		"skills": []
	}, "normal", 1)
	var target := {"hp": 100, "max_hp": 100, "statuses": []}
	status_service.fire_trigger(attacker, TriggerEvents.ON_HIT_DEALT, {"session": null, "battle_log": [], "source": attacker, "target": target})
	status_service.fire_trigger(attacker, TriggerEvents.ON_HIT_DEALT, {"session": null, "battle_log": [], "source": attacker, "target": target})
	var curse_statuses: Array = target.get("statuses", []).filter(func(status): return String(status.get("id", "")) == "curse_debuff")
	assert_equal(curse_statuses.size(), 1, "curse should refresh instead of stacking")
	assert_equal(int(curse_statuses[0]["duration"]), 3, "curse duration should refresh to 3 rounds")


func test_toxic_mist_uses_holder_attack() -> void:
	var status_service := StatusService.new()
	var player := {"hp": 100, "max_hp": 100, "statuses": []}
	var ally := {"hp": 100, "max_hp": 100, "statuses": []}
	var boss := {
		"hp": 100,
		"attack": 20,
		"defense": 0,
		"passive_skills": ["toxic_mist", "", "", ""]
	}
	CombatRules.apply_arena_effects(player, [boss], 3, status_service, [ally], [])
	assert_equal(int(player["hp"]), 94, "toxic mist should use holder attack against player")
	assert_equal(int(ally["hp"]), 94, "toxic mist should also hit allied units")


func test_new_units_wait_one_round() -> void:
	var summon_enemy := {
		"hp": 20,
		"max_hp": 20,
		"attack": 5,
		"defense": 1,
		"block_power": 1,
		"passive_skills": ["summon", "", "", ""],
		"skills": [],
		"statuses": [{"id": "summon_ready", "name": "召唤准备", "kind": "buff", "stack": "replace", "duration": 1}]
	}
	var summon_enemies: Array[Dictionary] = [summon_enemy]
	CombatRules.check_summon(summon_enemies, 4, [])
	assert_equal(int(summon_enemies[1]["available_round"]), 5, "summoned unit should wait until the next round")

	var split_enemy := {
		"hp": 40,
		"max_hp": 100,
		"attack": 8,
		"defense": 2,
		"block_power": 2,
		"passive_skills": ["split", "", "", ""],
		"skills": [],
		"split_triggered": false
	}
	var split_enemies: Array[Dictionary] = [split_enemy]
	CombatRules.check_split(split_enemies, 7, [])
	assert_equal(int(split_enemies[1]["available_round"]), 8, "split unit should wait until the next round")


func test_swarm_triggers_one_assist_per_living_ally() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	session.player["hp"] = 100
	session.player["defense"] = 0
	session.player_block = 0
	var rats: Array[Dictionary] = [
		TestHelpers.test_enemy("群袭甲", 30, 10, []),
		TestHelpers.test_enemy("群袭乙", 30, 10, [])
	]
	for rat in rats:
		rat["passive_skills"] = ["swarm", "", "", ""]
	session.enemies = rats
	session._enemy_attack(session.enemies[0], 0, false)
	assert_equal(int(session.player["hp"]), 80, "one living swarm ally should contribute exactly one normal attack")


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
	for key in ["side", "rank", "max_hp", "hp", "attack", "defense", "armor", "block_power", "block", "dodge_layers", "taunt", "passive_skills"]:
		assert_true(player_unit.has(key), "player combatant has %s" % key)
		assert_true(enemy_unit.has(key), "enemy combatant has %s" % key)
	var player_damage := Combatant.apply_damage(player_unit, 20)
	var enemy_damage := Combatant.apply_damage(enemy_unit, 20)
	assert_true(int(player_damage["damage"]) > 0, "player combatant should take resolved damage")
	assert_true(int(enemy_damage["damage"]) > 0, "enemy combatant should take resolved damage")


func test_thick_skin_always_grants_armor() -> void:
	var combat: CombatEngine = CombatEngine.new()
	var enemy: Dictionary = combat.scale_enemy({
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


func test_skill_multiplier_effects() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var warrior = session_script.new()
	warrior.start_new_game("warrior")
	warrior.player["equipped_skills"] = ["war_cry"]
	warrior.energy = 12
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
	archer.energy = int(DataCatalog.SKILLS["hunter_mark"]["energy_cost"])
	archer.use_skill(0, 0)
	assert_true(archer.enemies[0].get("statuses", []).size() > 0, "hunter mark should add a debuff status to enemy")
	var dmg_mult: float = archer.status_service.resolve_stat(archer.enemies[0], 1.0, StatusService.STAT_DAMAGE_TAKEN)
	assert_true(dmg_mult > 1.0, "hunter mark should increase damage taken multiplier")
	archer.has_acted = false
	archer.player_attack(0)
	assert_true(int(archer.enemies[0]["hp"]) < 90, "hunter mark should amplify following attack damage")


func test_counter_stance_and_multihit_dodge() -> void:
	var session_script = load("res://scripts/core/play_session.gd")

	var warrior = session_script.new()
	warrior.start_new_game("warrior")
	warrior.player["equipped_skills"] = ["counter_stance"]
	warrior.player["attack"] = 10
	var counter_enemies: Array[Dictionary] = [TestHelpers.test_enemy("反击测试敌人", 100, 1, [])]
	warrior.enemies = counter_enemies
	warrior.energy = int(DataCatalog.SKILLS["counter_stance"]["energy_cost"])
	warrior.use_skill(0, 0)
	warrior._enemy_attack(warrior.enemies[0], 0, false)
	assert_true(int(warrior.enemies[0]["hp"]) < 100, "counter stance should counterattack after being hit")
	assert_equal(int(warrior.counter_stance_charges), 0, "counter stance should consume one counter charge")

	var archer = session_script.new()
	archer.start_new_game("archer")
	archer.player["equipped_skills"] = ["quick_shot"]
	archer.player["attack"] = 10
	var dodging_enemies: Array[Dictionary] = [TestHelpers.test_enemy("闪避测试敌人", 100, 0, [])]
	dodging_enemies[0]["dodge_layers"] = 1
	archer.enemies = dodging_enemies
	archer.energy = int(DataCatalog.SKILLS["quick_shot"]["energy_cost"])
	archer.use_skill(0, 0)
	assert_equal(int(archer.enemies[0]["hp"]), 82, "quick shot should only lose its first hit to one dodge layer")

	var dodger = session_script.new()
	dodger.start_new_game("warrior")
	dodger.player["hp"] = 100
	dodger.player["defense"] = 0
	dodger.player_block = 0
	dodger.dodge_layers = 1
	var swarm_enemies: Array[Dictionary] = [TestHelpers.test_enemy("多段测试敌人", 100, 10, ["swarm"])]
	dodger.enemies = swarm_enemies
	dodger._enemy_attack(dodger.enemies[0], 0, false)
	assert_equal(int(dodger.dodge_layers), 0, "one dodge layer should be consumed by the first hit only")
	assert_equal(int(dodger.player["hp"]), 100, "swarm should not add a self extra hit without a living swarm ally")


func test_block_expires_each_round() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	session.player_block = 999
	session.end_turn()
	assert_equal(int(session.player_block), 0, "block should expire when next player turn begins")

func test_enemy_skill_execution() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	session.player["hp"] = 200
	var enemy := {
		"name": "技能测试敌人",
		"rank": "normal",
		"max_hp": 100,
		"hp": 20,
		"attack": 10,
		"defense": 3,
		"armor": 0,
		"block_power": 3,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": [],
		"skills": ["enemy_heavy_strike"],
		"innate_skills": {"attack_1": "innate_attack_1", "defend": "innate_defend", "dodge": "innate_dodge"}
	}
	session.enemies = [enemy] as Array[Dictionary]
	session.end_turn()
	var used_skill := false
	for entry in session.battle_log:
		if "重击" in entry:
			used_skill = true
			break
	assert_true(used_skill, "enemy with heavy strike skill should use it during its turn")

	session = session_script.new()
	session.start_new_game("warrior")
	session.player["hp"] = 200
	var defend_enemy := {
		"name": "防御技能敌人",
		"rank": "normal",
		"max_hp": 100,
		"hp": 100,
		"attack": 10,
		"defense": 3,
		"armor": 0,
		"block_power": 3,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": ["fortify"],
		"skills": ["enemy_fortify"],
		"innate_skills": {"attack_1": "innate_attack_1", "defend": "innate_defend", "dodge": "innate_dodge"}
	}
	session.enemies = [defend_enemy, TestHelpers.test_enemy("防御旁观敌人", 10, 0, [])] as Array[Dictionary]
	session.end_turn()
	var used_defend := false
	for entry in session.battle_log:
		if "固守" in entry:
			used_defend = true
			break
	assert_true(used_defend, "enemy with fortify skill should use it")
	assert_true(int(defend_enemy["block"]) > 0, "enemy should gain block from fortify skill")


func test_enemy_ai_skill_selection() -> void:
	var EnemyActionRules = preload("res://scripts/core/enemy_action_rules.gd")
	var rules = EnemyActionRules.new()

	var enemy := {
		"name": "AI测试敌人",
		"rank": "normal",
		"max_hp": 100,
		"hp": 100,
		"attack": 10,
		"defense": 3,
		"armor": 0,
		"block_power": 3,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": [],
		"skills": ["enemy_heavy_strike", "enemy_fortify"],
		"innate_skills": {"attack_1": "innate_attack_1", "defend": "innate_defend", "dodge": "innate_dodge"}
	}
	assert_equal(rules.choose_skill(enemy, 1), "enemy_heavy_strike", "should choose attack skill when healthy")

	enemy["hp"] = 20
	var chosen := rules.choose_skill(enemy, 1)
	assert_equal(chosen, "enemy_fortify", "should choose defense skill when low HP")

	var tank_enemy := {
		"name": "坦克AI",
		"rank": "normal",
		"max_hp": 100,
		"hp": 100,
		"attack": 10,
		"defense": 5,
		"armor": 0,
		"block_power": 5,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": ["tank"],
		"skills": ["enemy_heavy_strike", "enemy_fortify"],
		"innate_skills": {"attack_1": "innate_attack_1", "defend": "innate_defend", "dodge": "innate_dodge"}
	}
	assert_equal(rules.choose_skill(tank_enemy, 2), "enemy_fortify", "tank should prefer defense on even rounds")

	var no_skills_enemy := {
		"name": "无技能敌人",
		"rank": "normal",
		"max_hp": 50,
		"hp": 50,
		"attack": 5,
		"defense": 0,
		"armor": 0,
		"block_power": 1,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": [],
		"skills": [],
		"innate_skills": {"attack_1": "innate_attack_1", "defend": "innate_defend", "dodge": "innate_dodge"}
	}
	assert_equal(rules.choose_skill(no_skills_enemy, 1), "innate_attack_1", "enemy with no skills should fallback to innate attack")


func test_enemy_taunt_skill() -> void:
	var EnemyActionRules = preload("res://scripts/core/enemy_action_rules.gd")
	var rules = EnemyActionRules.new()

	var taunt_enemy := {
		"name": "嘲讽测试敌人",
		"rank": "normal",
		"max_hp": 100,
		"hp": 100,
		"attack": 10,
		"defense": 3,
		"armor": 0,
		"block_power": 3,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": ["taunt"],
		"skills": ["enemy_taunt"],
		"innate_skills": {"attack_1": "innate_attack_1", "defend": "innate_defend", "dodge": "innate_dodge"}
	}
	assert_equal(rules.choose_skill(taunt_enemy, 1), "enemy_taunt", "taunt enemy should use taunt skill on round 1")
	assert_equal(rules.choose_skill(taunt_enemy, 2), "innate_attack_1", "taunt enemy should use innate attack on round 2")

	taunt_enemy["taunt"] = 1
	assert_equal(rules.choose_skill(taunt_enemy, 4), "innate_attack_1", "taunt enemy with active taunt should not taunt again on round 4")


func test_rank_skill_multiplier() -> void:
	var CombatRules = preload("res://scripts/core/combat_rules.gd")

	var normal_enemy := {
		"name": "普通敌人",
		"rank": "normal",
		"attack": 10,
		"block_power": 5,
		"max_hp": 100
	}
	var elite_enemy := {
		"name": "精英敌人",
		"rank": "elite",
		"attack": 10,
		"block_power": 5,
		"max_hp": 100
	}
	var boss_enemy := {
		"name": "Boss敌人",
		"rank": "boss",
		"attack": 10,
		"block_power": 5,
		"max_hp": 100
	}

	var normal_dmg := CombatRules.skill_attack_value_for_actor(normal_enemy, "enemy_heavy_strike")
	var elite_dmg := CombatRules.skill_attack_value_for_actor(elite_enemy, "enemy_heavy_strike")
	var boss_dmg := CombatRules.skill_attack_value_for_actor(boss_enemy, "enemy_heavy_strike")

	assert_equal(normal_dmg, 15, "normal rank should use base 1.50 multiplier")
	assert_equal(elite_dmg, 18, "elite rank should apply 1.20 rank multiplier")
	assert_equal(boss_dmg, 22, "boss rank should apply 1.45 rank multiplier")

	var normal_block := CombatRules.skill_defense_value_for_actor(normal_enemy, "enemy_fortify")
	var elite_block := CombatRules.skill_defense_value_for_actor(elite_enemy, "enemy_fortify")

	assert_equal(normal_block, 8, "normal defense should use base multiplier")
	assert_equal(elite_block, 9, "elite defense should apply rank multiplier")
