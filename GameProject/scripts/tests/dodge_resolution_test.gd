extends "res://scripts/tests/test_base.gd"

const BattleHitContext = preload("res://scripts/core/battle/battle_hit_context.gd")
const BattleService = preload("res://scripts/core/battle_service.gd")
const BattleStepResult = preload("res://scripts/core/battle/battle_step_result.gd")
const BattleTiming = preload("res://scripts/core/battle/battle_timing.gd")
const DodgeResolutionModule = preload("res://scripts/core/battle/hit/dodge_resolution_module.gd")
const StatusService = preload("res://scripts/core/status_service.gd")


class DamageSessionStub extends RefCounted:
	var status_service := StatusService.new()
	var enemies: Array[Dictionary] = []
	var round_index: int = 1


func run() -> void:
	test_dodge_module_consumes_one_layer()
	test_zero_damage_does_not_consume_dodge()
	test_battle_flow_dodge_timing_uses_registered_module()
	test_damage_target_entry_uses_dodge_module_before_damage()


func test_dodge_module_consumes_one_layer() -> void:
	var target := _unit("目标", "enemy", 100, 2)
	var context := BattleHitContext.new(_unit("来源", "player", 100), target, "active_attack")
	context.base_damage = 10
	var result: RefCounted = DodgeResolutionModule.new().resolve(context)
	assert_equal(String(result.get("kind")), BattleStepResult.CONTINUE, "dodge resolution should return a continue result")
	assert_true(bool(context.get("is_dodged")), "dodge resolution should mark the hit as dodged")
	assert_equal(int(target["dodge_layers"]), 1, "dodge resolution should consume exactly one layer")
	assert_equal(int(context.get("final_damage")), 0, "dodged hit should have no final damage")


func test_zero_damage_does_not_consume_dodge() -> void:
	var target := _unit("目标", "enemy", 100, 1)
	var context := BattleHitContext.new(_unit("来源", "player", 100), target, "direct")
	context.base_damage = 0
	DodgeResolutionModule.new().resolve(context)
	assert_true(not bool(context.get("is_dodged")), "zero damage should not trigger dodge")
	assert_equal(int(target["dodge_layers"]), 1, "zero damage should not consume a dodge layer")


func test_battle_flow_dodge_timing_uses_registered_module() -> void:
	var service := BattleService.new()
	var target := _unit("目标", "enemy", 100, 1)
	var context := BattleHitContext.new(_unit("来源", "player", 100), target, "active_attack")
	context.base_damage = 10
	var result: RefCounted = service.battle_flow.resolve_hit(context)
	assert_equal(String(result.get("kind")), BattleStepResult.CONTINUE, "battle flow should complete the dodge branch")
	assert_true(bool(context.get("is_dodged")), "battle flow should invoke the registered dodge module")
	assert_equal(int(target["dodge_layers"]), 0, "battle flow should consume one dodge layer")


func test_damage_target_entry_uses_dodge_module_before_damage() -> void:
	var service := BattleService.new()
	var session := DamageSessionStub.new()
	var target := _unit("目标", "enemy", 100, 1)
	session.enemies = [target]
	var result: Dictionary = service.deal_damage_to_target(target, 20, "physical", session, _unit("来源", "player", 100))
	assert_true(bool(result["dodged"]), "damage target entry should return a dodge result")
	assert_equal(int(target["hp"]), 100, "dodged damage should not reduce HP")
	assert_equal(int(target["dodge_layers"]), 0, "damage target entry should consume one dodge layer")


func _unit(unit_name: String, side: String, hp: int, dodge_layers: int = 0) -> Dictionary:
	return {
		"name": unit_name,
		"side": side,
		"hp": hp,
		"max_hp": hp,
		"armor": 0,
		"block": 0,
		"dodge_layers": dodge_layers,
		"resistances": {},
		"passive_skills": [],
		"statuses": []
	}
