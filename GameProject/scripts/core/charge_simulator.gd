extends RefCounted
class_name ChargeSimulator

const ChargeService = preload("res://scripts/core/charge_service.gd")
const MAX_CHARGES := 5


func build_charge_state(player: Dictionary) -> Dictionary:
	var state := {
		"attack_multiplier": 1.0,
		"defense_multiplier": 1.0,
		"bonus_damage": 0,
		"repeat_attack": 0,
		"repeat_defense": 0,
		"pool": [],
		"activated": [],
		"skills": {}
	}
	_collect_charge_pool(state["pool"], player.get("equipment_attachments", {}))
	_collect_charge_pool(state["pool"], player.get("skill_attachments", {}))
	return state


func _collect_charge_pool(pool: Array, groups: Dictionary) -> void:
	for attachments in groups.values():
		for attachment in attachments:
			if pool.size() >= MAX_CHARGES:
				return
			if String(attachment.get("kind", "")).begins_with("charge_"):
				pool.append(attachment)


func charge_one_for_round(state: Dictionary) -> void:
	var pool: Array = state.get("pool", [])
	var activated: Array = state.get("activated", [])
	var candidates: Array[int] = []
	for i in range(pool.size()):
		if not activated.has(i):
			candidates.append(i)
	if candidates.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var selected_index := candidates[rng.randi_range(0, candidates.size() - 1)]
	activated.append(selected_index)
	state["activated"] = activated
	_apply_charged_effect(state, pool[selected_index])


func _apply_charged_effect(state: Dictionary, charge: Dictionary) -> void:
	var target_type := String(charge.get("target_type", ""))
	var target_id := String(charge.get("target_id", ""))
	var bucket := state
	if target_type == "skill" and target_id != "":
		var skills: Dictionary = state.get("skills", {})
		if not skills.has(target_id):
			skills[target_id] = {
				"attack_multiplier": 1.0,
				"defense_multiplier": 1.0,
				"bonus_damage": 0,
				"repeat_attack": 0,
				"repeat_defense": 0
			}
		state["skills"] = skills
		bucket = skills[target_id]
	ChargeService.apply_charge_to_bucket(bucket, charge)


func apply_attack_modifiers(base: int, state: Dictionary, skill_id: String = "") -> int:
	var effects := _merged_charge_state(state, skill_id)
	var result := ChargeService.compute_charge_attack(base, effects)
	state["attack_multiplier"] = 1.0
	state["bonus_damage"] = 0
	if skill_id != "":
		var skills: Dictionary = state.get("skills", {})
		if skills.has(skill_id):
			skills[skill_id]["attack_multiplier"] = 1.0
			skills[skill_id]["bonus_damage"] = 0
	return result


func apply_defense_modifiers(base: int, state: Dictionary, skill_id: String = "") -> int:
	var effects := _merged_charge_state(state, skill_id)
	var result := ChargeService.compute_charge_defense(base, effects)
	state["defense_multiplier"] = 1.0
	if skill_id != "":
		var skills: Dictionary = state.get("skills", {})
		if skills.has(skill_id):
			skills[skill_id]["defense_multiplier"] = 1.0
	return result


func consume_repeats(state: Dictionary, action_tag: String, skill_id: String = "") -> int:
	var repeats := ChargeService.consume_repeats_from_bucket(state, action_tag)
	if skill_id != "":
		var skills: Dictionary = state.get("skills", {})
		if skills.has(skill_id):
			repeats += ChargeService.consume_repeats_from_bucket(skills[skill_id], action_tag)
	return repeats


func _merged_charge_state(state: Dictionary, skill_id: String) -> Dictionary:
	if skill_id != "":
		var skills: Dictionary = state.get("skills", {})
		if skills.has(skill_id):
			return ChargeService.merge_charge_buckets(state, skills[skill_id])
	return state.duplicate(true)