extends "res://scripts/tests/test_base.gd"

const ActionSource = preload("res://scripts/core/action_source.gd")
const BattleActionIntent = preload("res://scripts/core/battle/decision/battle_action_intent.gd")
const EnemyDecisionModule = preload("res://scripts/core/battle/decision/enemy_decision_module.gd")
const PlayerActionModule = preload("res://scripts/core/battle/decision/player_action_module.gd")
const SkillActionService = preload("res://scripts/core/skill_action_service.gd")
const TargetResolutionModule = preload("res://scripts/core/battle/decision/target_resolution_module.gd")


func run() -> void:
	test_player_action_intents_are_normalized()
	test_action_intent_copies_metadata()
	test_enemy_decision_creates_intent_without_executing_action()
	test_player_target_resolution_reuses_combat_rules()
	test_action_target_modes_return_structured_targets()


func test_player_action_intents_are_normalized() -> void:
	var player_actions := PlayerActionModule.new()
	var attack: RefCounted = player_actions.create_attack_intent(2)
	assert_equal(attack.get("action_type"), "attack", "player attack should become an attack intent")
	assert_equal(attack.get("actor_side"), "player", "player attack should identify the player side")
	assert_equal(attack.get("target_index"), 2, "player attack should preserve the requested target")
	assert_equal(attack.get("source"), ActionSource.ACTIVE_ATTACK, "player attack should preserve its source")
	var skill: RefCounted = player_actions.create_skill_intent(1, 0, "fixture.skill")
	assert_equal(skill.get("action_type"), "skill", "player skill should become a skill intent")
	assert_equal(skill.get("slot_index"), 1, "player skill should preserve its slot")
	assert_equal(skill.get("skill_id"), "fixture.skill", "player skill should preserve its ID")
	var item: RefCounted = player_actions.create_item_intent("blood_potion")
	assert_equal(item.get("action_type"), "item", "player item should become an item intent")
	assert_equal(item.get("source"), ActionSource.DIRECT, "player item should use a non-attack source")


func test_action_intent_copies_metadata() -> void:
	var metadata := {"decision": "attack"}
	var intent := BattleActionIntent.new("enemy_action", "enemy", 1, -1, "fixture.skill", ActionSource.ENEMY_ATTACK, -1, "", metadata)
	metadata["decision"] = "mutated"
	var dictionary: Dictionary = intent.to_dictionary()
	assert_equal(dictionary["metadata"]["decision"], "attack", "action intent should not alias metadata input")
	assert_true(intent.is_enemy_intent(), "enemy intent should identify the enemy side")
	assert_true(not intent.is_player_intent(), "enemy intent should not identify the player side")


func test_enemy_decision_creates_intent_without_executing_action() -> void:
	var enemy := _unit("敌人", "enemy", 100)
	enemy["innate_skills"] = {"attack_1": "innate_attack_1"}
	var decision_module := EnemyDecisionModule.new()
	var intent: RefCounted = decision_module.create_intent(enemy, 2, 1, {}, false)
	assert_equal(intent.get("action_type"), "enemy_action", "enemy decision should create an enemy action intent")
	assert_equal(intent.get("actor_index"), 2, "enemy decision should preserve the enemy index")
	assert_equal(intent.get("skill_id"), "innate_attack_1", "enemy decision should preserve the selected skill")
	assert_equal(intent.get("metadata")["decision"], "attack", "enemy decision should preserve the behavior decision")
	assert_equal(enemy["hp"], 100, "creating an intent should not execute the enemy action")


func test_player_target_resolution_reuses_combat_rules() -> void:
	var resolver := TargetResolutionModule.new()
	var enemies: Array[Dictionary] = [_unit("普通目标", "enemy", 100), _unit("死亡目标", "enemy", 0)]
	var fallback: Dictionary = resolver.resolve_player_target(enemies, 1)
	assert_true(bool(fallback["valid"]), "resolver should fall back to an alive target")
	assert_equal(fallback["index"], 0, "resolver should select the first valid target")
	enemies[1]["hp"] = 100
	enemies[1]["taunt"] = 1
	var taunted: Dictionary = resolver.resolve_player_target(enemies, 0)
	assert_equal(taunted["index"], 1, "resolver should preserve CombatRules taunt redirection")
	var empty: Array[Dictionary] = []
	var invalid: Dictionary = resolver.resolve_player_target(empty, 0)
	assert_true(not bool(invalid["valid"]), "resolver should reject an empty enemy list")
	assert_equal(invalid["reason"], "no_valid_enemy_target", "resolver should provide a structured invalid reason")


func test_action_target_modes_return_structured_targets() -> void:
	var resolver := TargetResolutionModule.new()
	var player := _unit("玩家", "player", 100)
	var enemies: Array[Dictionary] = [_unit("敌人一", "enemy", 100), _unit("敌人二", "enemy", 100)]
	var allies: Array[Dictionary] = [_unit("盟友", "ally", 100)]
	var all_enemies: Array[Dictionary] = resolver.resolve_player_action_targets(player, enemies, allies, SkillActionService.TARGET_ALL_ENEMIES, 0)
	assert_equal(all_enemies.size(), 2, "all enemy targeting should return every living enemy")
	var self_target: Array[Dictionary] = resolver.resolve_player_action_targets(player, enemies, allies, SkillActionService.TARGET_SELF, 0)
	assert_equal(self_target[0]["side"], "player", "self targeting should return the player")
	var ally_target: Array[Dictionary] = resolver.resolve_player_action_targets(player, enemies, allies, SkillActionService.TARGET_ALLY_SELECTED, 0)
	assert_equal(ally_target[0]["side"], "ally", "ally targeting should return an ally")
	var enemy_targets: Array[Dictionary] = resolver.resolve_enemy_action_targets(player, allies, SkillActionService.TARGET_SELECTED, 1)
	assert_equal(enemy_targets[0]["side"], "ally", "enemy selected targeting should preserve ally side semantics")
	assert_equal(enemy_targets[0]["index"], 1, "enemy selected targeting should preserve the requested player-side index")
	var self_enemy_targets: Array[Dictionary] = resolver.resolve_enemy_action_targets(player, allies, SkillActionService.TARGET_SELF, 0)
	assert_true(self_enemy_targets.is_empty(), "enemy self effects should not target the player side")


func _unit(unit_name: String, side: String, hp: int) -> Dictionary:
	return {
		"name": unit_name,
		"side": side,
		"hp": hp,
		"max_hp": 100,
		"taunt": 0,
		"passive_skills": [],
		"statuses": []
	}
