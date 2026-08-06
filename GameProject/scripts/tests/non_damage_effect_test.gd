extends "res://scripts/tests/test_base.gd"

const BattleService = preload("res://scripts/core/battle_service.gd")
const CombatRules = preload("res://scripts/core/combat_rules.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const SkillActionService = preload("res://scripts/core/skill_action_service.gd")


class EffectSessionStub extends RefCounted:
	var player: Dictionary = {}
	var enemies: Array[Dictionary] = []
	var allies: Array[Dictionary] = []
	var status_service := StatusService.new()
	var battle_log: Array[String] = []
	var last_events: Array[Dictionary] = []
	var pending_state_card: String = ""
	var message: String = ""

	func _valid_target(target_index: int) -> int:
		return CombatRules.valid_target(enemies, target_index)

	func _alive_enemy_count() -> int:
		return CombatRules.alive_count(enemies)

	func _skill_multiplier_bonus(_skill_id: String, _stat_key: String) -> float:
		return 0.0

	func _apply_charge_defense_modifiers(amount: int, _skill_id: String) -> int:
		return amount

	func _add_player_block(amount: int) -> void:
		player["block"] = int(player.get("block", 0)) + maxi(0, amount)

	func _add_player_dodge(layers: int) -> void:
		Combatant.add_dodge(player, layers)

	func _sync_player_combatant(combatant_unit: Dictionary) -> void:
		var synced: Dictionary = Combatant.sync_to_player(combatant_unit, player)
		player["block"] = int(synced["block"])
		player["dodge_layers"] = int(synced["dodge_layers"])


var battle_service := BattleService.new()


func run() -> void:
	test_player_non_damage_actions_use_effect_modules()
	test_enemy_non_damage_actions_use_effect_modules()
	test_targeted_non_damage_actions_use_shared_targets()


func test_player_non_damage_actions_use_effect_modules() -> void:
	var session := _session()
	var skill := {
		"name": "玩家效果测试",
		"actions": [
			{"type": SkillActionService.ACTION_GAIN_BLOCK, "amount": 5},
			{"type": SkillActionService.ACTION_GAIN_DODGE, "layers": 2},
			{"type": SkillActionService.ACTION_APPLY_STATUS, "target": SkillActionService.TARGET_SELF, "status": _status("player_buff")},
			{"type": SkillActionService.ACTION_HEAL, "target": SkillActionService.TARGET_SELF, "amount": 7, "resolve_heal": false}
		]
	}
	session.player["hp"] = 40
	battle_service._execute_action_skill(session, "fixture_player_effects", skill, 0, session.player, true)
	assert_equal(int(session.player["block"]), 5, "player gain_block should use the effect module")
	assert_equal(int(session.player["dodge_layers"]), 2, "player gain_dodge should use the effect module")
	assert_equal(int(session.player["hp"]), 47, "player heal should use the effect module")
	assert_true(_has_status(session.player, "player_buff"), "player apply_status should use the effect module")


func test_enemy_non_damage_actions_use_effect_modules() -> void:
	var session := _session()
	var enemy: Dictionary = session.enemies[0]
	var skill := {
		"name": "敌方效果测试",
		"actions": [
			{"type": SkillActionService.ACTION_GAIN_BLOCK, "amount": 4},
			{"type": SkillActionService.ACTION_GAIN_DODGE, "layers": 1},
			{"type": SkillActionService.ACTION_APPLY_STATUS, "target": SkillActionService.TARGET_SELF, "status": _status("enemy_buff")},
			{"type": SkillActionService.ACTION_HEAL, "target": SkillActionService.TARGET_SELF, "amount": 6}
		]
	}
	enemy["hp"] = 40
	battle_service._execute_action_skill(session, "fixture_enemy_effects", skill, 0, enemy, false)
	assert_equal(int(enemy["block"]), 4, "enemy gain_block should use the effect module")
	assert_equal(int(enemy["dodge_layers"]), 1, "enemy gain_dodge should use the effect module")
	assert_equal(int(enemy["hp"]), 46, "enemy heal should use the effect module")
	assert_true(_has_status(enemy, "enemy_buff"), "enemy apply_status should use the effect module")


func test_targeted_non_damage_actions_use_shared_targets() -> void:
	var session := _session()
	var skill := {
		"name": "目标效果测试",
		"actions": [
			{"type": SkillActionService.ACTION_MODIFY_ARMOR, "target": SkillActionService.TARGET_SELECTED, "multiplier": 0.5},
			{"type": SkillActionService.ACTION_INTERRUPT, "target": SkillActionService.TARGET_SELECTED}
		]
	}
	session.enemies[0]["armor"] = 10
	battle_service._execute_action_skill(session, "fixture_target_effects", skill, 0, session.player, true)
	assert_equal(int(session.enemies[0]["armor"]), 5, "player modify_armor should resolve the shared enemy target")
	assert_true(bool(session.enemies[0].get("interrupted", false)), "player interrupt should resolve the shared enemy target")


func _session() -> EffectSessionStub:
	var session := EffectSessionStub.new()
	session.pending_state_card = "fixture_no_state"
	session.player = _unit("玩家", "player", 60)
	session.player["attack"] = 10
	session.player["block_power"] = 5
	session.enemies = [_unit("敌人", "enemy", 60)]
	session.enemies[0]["attack"] = 8
	session.enemies[0]["block_power"] = 4
	return session


func _unit(unit_name: String, side: String, hp: int) -> Dictionary:
	return {
		"name": unit_name,
		"side": side,
		"hp": hp,
		"max_hp": 60,
		"attack": 8,
		"defense": 4,
		"armor": 0,
		"block_power": 4,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"passive_skills": [],
		"statuses": []
	}


func _status(status_id: String) -> Dictionary:
	return {"id": status_id, "name": status_id, "kind": "buff", "stack": "replace", "duration": 2, "effects": []}


func _has_status(target: Dictionary, status_id: String) -> bool:
	for status in target.get("statuses", []):
		if String(status.get("id", "")) == status_id:
			return true
	return false
