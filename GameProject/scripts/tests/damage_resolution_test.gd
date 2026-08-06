extends "res://scripts/tests/test_base.gd"

const BattleEffectRuntime = preload("res://scripts/core/battle/skill/battle_effect_runtime.gd")
const DamageResolutionModule = preload("res://scripts/core/battle/hit/damage_resolution_module.gd")
const StatusService = preload("res://scripts/core/status_service.gd")


class DamageSessionStub extends RefCounted:
	var player: Dictionary = {}
	var enemies: Array[Dictionary] = []
	var status_service := StatusService.new()
	var round_index: int = 1
	var battle_log: Array[String] = []

	func _player_combatant() -> Dictionary:
		return player

	func _sync_player_combatant(combatant_unit: Dictionary) -> void:
		player["hp"] = int(combatant_unit.get("hp", player.get("hp", 0)))
		player["block"] = int(combatant_unit.get("block", player.get("block", 0)))
		player["dodge_layers"] = int(combatant_unit.get("dodge_layers", player.get("dodge_layers", 0)))


func run() -> void:
	test_armor_and_block_are_resolved_in_damage_module()
	test_true_damage_bypasses_armor()
	test_damage_type_resistance_is_applied()
	test_shadow_armor_reflect_is_applied_after_block()


func test_armor_and_block_are_resolved_in_damage_module() -> void:
	var session := _session()
	var target := _unit("目标", "enemy", 100)
	target["armor"] = 10
	target["block"] = 5
	session.enemies = [target]
	var result: Dictionary = _resolve(session, target, 30, "physical", session.player)
	assert_true(int(result["armor_reduced"]) > 0, "damage module should apply armor reduction")
	assert_true(int(result["block_absorbed"]) > 0, "damage module should apply block absorption")
	assert_equal(int(target["hp"]), 100 - int(result["damage"]), "damage module should update target HP by final damage")


func test_true_damage_bypasses_armor() -> void:
	var session := _session()
	var target := _unit("目标", "enemy", 100)
	target["armor"] = 99
	session.enemies = [target]
	var result: Dictionary = _resolve(session, target, 20, "true", session.player)
	assert_equal(int(result["armor_reduced"]), 0, "true damage should bypass armor")
	assert_equal(int(result["damage"]), 20, "true damage should preserve raw damage without block")


func test_damage_type_resistance_is_applied() -> void:
	var session := _session()
	var target := _unit("目标", "enemy", 100)
	target["resistances"] = {"fire": 0.5}
	session.enemies = [target]
	var result: Dictionary = _resolve(session, target, 20, "fire", session.player)
	assert_equal(int(result["damage"]), 10, "damage module should apply typed resistance before armor")


func test_shadow_armor_reflect_is_applied_after_block() -> void:
	var session := _session()
	var target := _unit("暗影护甲目标", "enemy", 100)
	target["block"] = 10
	target["shadow_armor_active"] = true
	session.enemies = [target]
	var result: Dictionary = _resolve(session, target, 10, "physical", session.player)
	assert_equal(int(result["damage"]), 0, "block should absorb the initial shadow armor hit")
	assert_equal(int(session.player["hp"]), 95, "shadow armor reflect should damage the attacker after block")
	assert_true(not session.battle_log.is_empty(), "shadow armor reflect should append a battle log entry")


func _resolve(session: DamageSessionStub, target: Dictionary, amount: int, damage_type: String, attacker: Dictionary) -> Dictionary:
	var runtime := BattleEffectRuntime.new(session)
	return DamageResolutionModule.new().resolve(target, amount, damage_type, runtime, attacker)


func _session() -> DamageSessionStub:
	var session := DamageSessionStub.new()
	session.player = _unit("玩家", "player", 100)
	return session


func _unit(unit_name: String, side: String, hp: int) -> Dictionary:
	return {
		"name": unit_name,
		"side": side,
		"hp": hp,
		"max_hp": hp,
		"armor": 0,
		"block": 0,
		"dodge_layers": 0,
		"resistances": {},
		"passive_skills": [],
		"statuses": []
	}
