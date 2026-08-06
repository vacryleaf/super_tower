extends RefCounted
class_name PlayerActionModule

const ActionSource = preload("res://scripts/core/action_source.gd")
const BattleActionIntent = preload("res://scripts/core/battle/decision/battle_action_intent.gd")


func create_attack_intent(target_index: int) -> RefCounted:
	return BattleActionIntent.new("attack", "player", -1, target_index, "", ActionSource.ACTIVE_ATTACK)


func create_defend_intent() -> RefCounted:
	return BattleActionIntent.new("defend", "player", -1, -1, "", ActionSource.ACTIVE_ATTACK)


func create_dodge_intent() -> RefCounted:
	return BattleActionIntent.new("dodge", "player", -1, -1, "", ActionSource.ACTIVE_ATTACK)


func create_skill_intent(slot_index: int, target_index: int, skill_id: String = "") -> RefCounted:
	return BattleActionIntent.new("skill", "player", -1, target_index, skill_id, ActionSource.ACTIVE_ATTACK, slot_index)


func create_item_intent(item_id: String, target_index: int = -1) -> RefCounted:
	return BattleActionIntent.new("item", "player", -1, target_index, "", ActionSource.DIRECT, -1, item_id)
