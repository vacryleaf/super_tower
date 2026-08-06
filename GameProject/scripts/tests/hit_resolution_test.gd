extends "res://scripts/tests/test_base.gd"

const ActionContext = preload("res://scripts/core/action_context.gd")
const BattleHitContext = preload("res://scripts/core/battle/battle_hit_context.gd")
const BattleService = preload("res://scripts/core/battle_service.gd")
const HitResolutionModule = preload("res://scripts/core/battle/hit/hit_resolution_module.gd")


func run() -> void:
	test_player_hit_context_uses_resolved_target()
	test_enemy_hit_context_uses_player_side_target()
	test_invalid_hit_returns_structured_reason()
	test_battle_service_exposes_hit_context_entry()


func test_player_hit_context_uses_resolved_target() -> void:
	var resolver := HitResolutionModule.new()
	var enemies: Array[Dictionary] = [_unit("普通目标", "enemy", 100), _unit("嘲讽目标", "enemy", 100)]
	enemies[1]["taunt"] = 1
	var action: Dictionary = ActionContext.create_attack("active_attack", 0, "fixture.skill", "fire", 1)
	action["base_damage"] = 12
	action["final_damage"] = 15
	action["is_critical"] = true
	action["armor_multiplier"] = 0.5
	var result: Dictionary = resolver.resolve_player_hit(enemies, action, _unit("玩家", "player", 100), "action-1", "chain-1")
	assert_true(bool(result["valid"]), "player hit should resolve a living target")
	assert_equal(result["target"]["index"], 1, "player hit should preserve taunt redirection")
	var context: RefCounted = result["context"]
	assert_true(context is BattleHitContext, "resolved player hit should create BattleHitContext")
	assert_equal(context.get("skill_id"), "fixture.skill", "hit context should preserve skill ID")
	assert_equal(context.get("damage_type"), "fire", "hit context should preserve damage type")
	assert_equal(context.get("base_damage"), 12, "hit context should preserve base damage")
	assert_equal(context.get("modified_damage"), 15, "hit context should preserve modified damage")
	assert_true(bool(context.get("is_critical")), "hit context should preserve critical state")
	assert_equal(context.get("armor_multiplier"), 0.5, "hit context should preserve armor multiplier")
	assert_equal(context.get("parent_action_id"), "action-1", "hit context should preserve parent action ID")
	assert_equal(context.get("chain_id"), "chain-1", "hit context should preserve chain ID")


func test_enemy_hit_context_uses_player_side_target() -> void:
	var resolver := HitResolutionModule.new()
	var player := _unit("玩家", "player", 100)
	var allies: Array[Dictionary] = [_unit("盟友", "ally", 100)]
	var action: Dictionary = ActionContext.create_attack("enemy_attack", 1, "enemy.skill", "physical", 1)
	var result: Dictionary = resolver.resolve_enemy_hit(player, allies, action, _unit("敌人", "enemy", 100))
	assert_true(bool(result["valid"]), "enemy hit should resolve a player-side target")
	assert_equal(result["target"]["side"], "ally", "enemy hit should resolve the requested ally index")
	assert_equal(result["target"]["index"], 1, "enemy hit should preserve player-side target index")
	assert_equal(result["context"].get("target_actor")["name"], "盟友", "hit context should store the resolved target actor")


func test_invalid_hit_returns_structured_reason() -> void:
	var resolver := HitResolutionModule.new()
	var action: Dictionary = ActionContext.create_attack("active_attack", 0)
	var result: Dictionary = resolver.resolve_player_hit([], action, _unit("玩家", "player", 100))
	assert_true(not bool(result["valid"]), "hit resolver should reject an empty enemy list")
	assert_equal(result["reason"], "no_valid_enemy_target", "hit resolver should preserve target failure reason")
	assert_true(result["context"] == null, "invalid hit should not create a hit context")


func test_battle_service_exposes_hit_context_entry() -> void:
	var service := BattleService.new()
	var action: Dictionary = ActionContext.create_trigger("trigger_effect", 0, 8)
	var context: RefCounted = service.create_hit_context(action, _unit("来源", "player", 100), _unit("目标", "enemy", 100))
	assert_true(context is BattleHitContext, "BattleService should expose the unified hit context entry")
	assert_equal(context.get("final_damage"), 8, "compatibility hit entry should preserve trigger damage")


func _unit(unit_name: String, side: String, hp: int) -> Dictionary:
	return {
		"name": unit_name,
		"side": side,
		"hp": hp,
		"max_hp": hp,
		"taunt": 0,
		"passive_skills": [],
		"statuses": []
	}
