extends RefCounted
class_name EnemyDecisionModule

const ActionSource = preload("res://scripts/core/action_source.gd")
const BattleActionIntent = preload("res://scripts/core/battle/decision/battle_action_intent.gd")
const EnemyActionRules = preload("res://scripts/core/enemy_action_rules.gd")

var enemy_rules: RefCounted


func _init(rules: RefCounted = null) -> void:
	enemy_rules = rules if rules != null else EnemyActionRules.new()


func create_intent(
	enemy: Dictionary,
	enemy_index: int,
	round_index: int,
	player_context: Dictionary = {},
	is_alone: bool = false,
	rng: RandomNumberGenerator = null
) -> RefCounted:
	var decision: String = String(enemy_rules.call("intent", enemy, round_index, player_context, is_alone))
	var skill_id: String = String(enemy_rules.call("choose_skill", enemy, round_index, player_context, is_alone, rng))
	return BattleActionIntent.new(
		"enemy_action",
		"enemy",
		enemy_index,
		-1,
		skill_id,
		ActionSource.ENEMY_ATTACK,
		-1,
		"",
		{"decision": decision}
	)
