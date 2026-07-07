extends RefCounted
class_name ChargeSimulator

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
	match String(charge.get("kind", "")):
		"charge_attack_multiplier":
			bucket["attack_multiplier"] = float(bucket["attack_multiplier"]) * float(charge.get("value", 1.0))
		"charge_defense_multiplier":
			bucket["defense_multiplier"] = float(bucket["defense_multiplier"]) * float(charge.get("value", 1.0))
		"charge_bonus_damage":
			bucket["bonus_damage"] = int(bucket["bonus_damage"]) + int(charge.get("value", 0))
		"charge_repeat_attack":
			bucket["repeat_attack"] = int(bucket["repeat_attack"]) + maxi(1, int(charge.get("value", 1)))
		"charge_repeat_defense":
			bucket["repeat_defense"] = int(bucket["repeat_defense"]) + maxi(1, int(charge.get("value", 1)))


func apply_attack_modifiers(base: int, state: Dictionary, skill_id: String = "") -> int:
	var effects := _merged_charge_state(state, skill_id)
	var result := int(round(float(base) * float(effects.get("attack_multiplier", 1.0)))) + int(effects.get("bonus_damage", 0))
	state["attack_multiplier"] = 1.0
	state["bonus_damage"] = 0
	if skill_id != "":
		var skills: Dictionary = state.get("skills", {})
		if skills.has(skill_id):
			skills[skill_id]["attack_multiplier"] = 1.0
			skills[skill_id]["bonus_damage"] = 0
	return maxi(1, result)


func apply_defense_modifiers(base: int, state: Dictionary, skill_id: String = "") -> int:
	var effects := _merged_charge_state(state, skill_id)
	var result := int(round(float(base) * float(effects.get("defense_multiplier", 1.0))))
	state["defense_multiplier"] = 1.0
	if skill_id != "":
		var skills: Dictionary = state.get("skills", {})
		if skills.has(skill_id):
			skills[skill_id]["defense_multiplier"] = 1.0
	return maxi(1, result)


func consume_repeats(state: Dictionary, action_tag: String, skill_id: String = "") -> int:
	var key := "repeat_attack" if action_tag == "attack" else "repeat_defense"
	var repeats := int(state.get(key, 0))
	state[key] = 0
	if skill_id != "":
		var skills: Dictionary = state.get("skills", {})
		if skills.has(skill_id):
			repeats += int(skills[skill_id].get(key, 0))
			skills[skill_id][key] = 0
	return repeats


func _merged_charge_state(state: Dictionary, skill_id: String) -> Dictionary:
	var result := state.duplicate(true)
	if skill_id != "":
		var skills: Dictionary = state.get("skills", {})
		if skills.has(skill_id):
			var skill_effects: Dictionary = skills[skill_id]
			result["attack_multiplier"] = float(result.get("attack_multiplier", 1.0)) * float(skill_effects.get("attack_multiplier", 1.0))
			result["defense_multiplier"] = float(result.get("defense_multiplier", 1.0)) * float(skill_effects.get("defense_multiplier", 1.0))
			result["bonus_damage"] = int(result.get("bonus_damage", 0)) + int(skill_effects.get("bonus_damage", 0))
	return result