extends "res://scripts/tests/test_base.gd"

const TestHelpers = preload("res://scripts/tests/test_helpers.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const RunSimulator = preload("res://scripts/core/run_simulator.gd")
const CombatEngine = preload("res://scripts/core/combat_engine.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const StatusService = preload("res://scripts/core/status_service.gd")


func run() -> void:
	test_block_power_is_separate_from_armor()
	test_enemy_block_power_is_separate_from_armor()
	test_player_and_enemy_share_combatant_contract()
	test_thick_skin_always_grants_armor()
	test_skill_multiplier_effects()
	test_counter_stance_and_multihit_dodge()
	test_block_expires_each_round()


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
	var counter_enemies: Array[Dictionary] = [TestHelpers.test_enemy("反击测试敌人", 100, 1, [])]
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
	var dodging_enemies: Array[Dictionary] = [TestHelpers.test_enemy("闪避测试敌人", 100, 0, [])]
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
	var swarm_enemies: Array[Dictionary] = [TestHelpers.test_enemy("多段测试敌人", 100, 10, ["swarm"])]
	dodger.enemies = swarm_enemies
	dodger._enemy_attack(dodger.enemies[0], 0, false)
	assert_equal(int(dodger.dodge_layers), 0, "one dodge layer should be consumed by the first hit only")
	assert_true(int(dodger.player["hp"]) < 100, "later hits in a multi-hit attack should still deal damage")


func test_block_expires_each_round() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	session.player_block = 999
	session.end_turn()
	assert_equal(int(session.player_block), 0, "block should expire when next player turn begins")