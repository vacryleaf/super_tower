extends "res://scripts/tests/test_base.gd"

const ActionContext = preload("res://scripts/core/action_context.gd")
const ActionSource = preload("res://scripts/core/action_source.gd")
const BattleService = preload("res://scripts/core/battle_service.gd")
const CombatRules = preload("res://scripts/core/combat_rules.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const StatusService = preload("res://scripts/core/status_service.gd")

var battle_service := BattleService.new()


class BattleServiceSessionStub extends RefCounted:
	const CombatRules = preload("res://scripts/core/combat_rules.gd")
	const Combatant = preload("res://scripts/core/combatant.gd")
	var player: Dictionary = {}
	var enemies: Array[Dictionary] = []
	var allies: Array[Dictionary] = []
	var status_service := StatusService.new()
	var battle_log: Array[String] = []
	var last_events: Array[Dictionary] = []
	var duel_target_index := -1
	var round_index := 1
	var player_block := 0
	var dodge_layers := 0

	func _active_taunt_target() -> int:
		return CombatRules.active_taunt_target(enemies)

	func _opposing_units(actor: Dictionary) -> Array[Dictionary]:
		if String(actor.get("side", "player")) == "player":
			return enemies
		var player_side_units: Array[Dictionary] = [player]
		player_side_units.append_array(allies)
		return player_side_units

	func _sync_player_combatant(combatant_unit: Dictionary) -> void:
		var synced: Dictionary = Combatant.sync_to_player(combatant_unit, player)
		player_block = int(synced["block"])
		dodge_layers = int(synced["dodge_layers"])


func run() -> void:
	test_taunt_redirects_interactive_damage()
	test_duel_target_clears_after_kill()
	test_dodge_branch_consumes_dodge_layer()
	test_non_interactive_damage_ignores_taunt()


func test_taunt_redirects_interactive_damage() -> void:
	var session := _session_with_enemies([_enemy("普通目标", 100), _enemy("嘲讽目标", 100)])
	session.enemies[1]["taunt"] = 1
	battle_service.deal_damage(session, _damage_context(ActionSource.ACTIVE_ATTACK, 0, 10))
	assert_equal(int(session.enemies[0]["hp"]), 100, "interactive damage should not bypass taunt")
	assert_equal(int(session.enemies[1]["hp"]), 90, "interactive damage should redirect to taunt target")


func test_duel_target_clears_after_kill() -> void:
	var session := _session_with_enemies([_enemy("决斗目标", 5)])
	session.duel_target_index = 0
	battle_service.deal_damage(session, _damage_context(ActionSource.ACTIVE_ATTACK, 0, 10))
	assert_equal(int(session.enemies[0]["hp"]), 0, "damage should defeat the duel target")
	assert_equal(session.duel_target_index, -1, "defeated duel target should clear duel state")
	assert_true(session.battle_log.any(func(entry: String): return entry.contains("单挑领域：决斗目标已死亡")), "duel cleanup should be visible in the battle log")


func test_dodge_branch_consumes_dodge_layer() -> void:
	var session := _session_with_enemies([_enemy("闪避目标", 100)])
	session.enemies[0]["dodge_layers"] = 1
	battle_service.deal_damage(session, _damage_context(ActionSource.ACTIVE_ATTACK, 0, 10))
	assert_equal(int(session.enemies[0]["hp"]), 100, "dodged damage should not reduce health")
	assert_equal(int(session.enemies[0]["dodge_layers"]), 0, "dodge branch should consume one dodge layer")
	assert_true(session.last_events.any(func(entry: Dictionary): return String(entry.get("kind", "")) == "dodge_enemy_attack"), "dodge branch should emit a dodge event")


func test_non_interactive_damage_ignores_taunt() -> void:
	var session := _session_with_enemies([_enemy("触发目标", 100), _enemy("嘲讽目标", 100)])
	session.enemies[1]["taunt"] = 1
	battle_service.deal_damage(session, _damage_context(ActionSource.TRIGGER_EFFECT, 0, 10))
	assert_equal(int(session.enemies[0]["hp"]), 90, "non-interactive damage should use the requested target")
	assert_equal(int(session.enemies[1]["hp"]), 100, "non-interactive damage should ignore taunt redirection")


func _session_with_enemies(enemy_list: Array[Dictionary]) -> BattleServiceSessionStub:
	var session := BattleServiceSessionStub.new()
	session.player = {
		"name": "测试玩家",
		"side": "player",
		"hp": 100,
		"max_hp": 100,
		"defense": 0,
		"armor": 0,
		"block": 0,
		"dodge_layers": 0,
		"statuses": []
	}
	session.enemies = enemy_list
	return session


func _enemy(enemy_name: String, hp: int) -> Dictionary:
	return {
		"name": enemy_name,
		"side": "enemy",
		"hp": hp,
		"max_hp": hp,
		"attack": 1,
		"defense": 0,
		"armor": 0,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"passive_skills": [],
		"statuses": []
	}


func _damage_context(source: String, target_index: int, damage: int) -> Dictionary:
	var context := ActionContext.create_attack(source, target_index, "", "physical", 1)
	context["final_damage"] = damage
	return context
