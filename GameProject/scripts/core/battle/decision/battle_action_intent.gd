extends RefCounted
class_name BattleActionIntent

var action_type: String = ""
var actor_side: String = ""
var actor_index: int = -1
var target_index: int = -1
var slot_index: int = -1
var skill_id: String = ""
var item_id: String = ""
var source: String = ""
var metadata: Dictionary = {}


func _init(
	intent_type: String = "",
	initial_actor_side: String = "",
	initial_actor_index: int = -1,
	initial_target_index: int = -1,
	initial_skill_id: String = "",
	initial_source: String = "",
	initial_slot_index: int = -1,
	initial_item_id: String = "",
	initial_metadata: Dictionary = {}
) -> void:
	action_type = intent_type
	actor_side = initial_actor_side
	actor_index = initial_actor_index
	target_index = initial_target_index
	slot_index = initial_slot_index
	skill_id = initial_skill_id
	source = initial_source
	item_id = initial_item_id
	metadata = initial_metadata.duplicate(true)


func is_player_intent() -> bool:
	return actor_side == "player"


func is_enemy_intent() -> bool:
	return actor_side == "enemy"


func to_dictionary() -> Dictionary:
	return {
		"action_type": action_type,
		"actor_side": actor_side,
		"actor_index": actor_index,
		"target_index": target_index,
		"slot_index": slot_index,
		"skill_id": skill_id,
		"item_id": item_id,
		"source": source,
		"metadata": metadata.duplicate(true)
	}
