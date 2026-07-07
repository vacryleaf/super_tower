extends RefCounted
class_name ActionContext

const ActionSource = preload("res://scripts/core/action_source.gd")


static func create_attack(source: String, target_index: int, skill_id: String = "", damage_type: String = "physical", hits: int = 1) -> Dictionary:
	return {
		"source": source,
		"target_index": target_index,
		"skill_id": skill_id,
		"damage_type": damage_type,
		"hits": hits,
		"base_damage": 0,
		"final_damage": 0,
		"is_critical": false,
		"armor_reduce": 0.0
	}


static func create_trigger(source: String, target_index: int, base_damage: int, damage_type: String = "physical") -> Dictionary:
	return {
		"source": source,
		"target_index": target_index,
		"skill_id": "",
		"damage_type": damage_type,
		"hits": 1,
		"base_damage": base_damage,
		"final_damage": base_damage,
		"is_critical": false,
		"armor_reduce": 0.0
	}
