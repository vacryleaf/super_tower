extends RefCounted
class_name ChargeService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const MAX_CHARGES := 5

var rng := RandomNumberGenerator.new()


func available_charges(session: Variant) -> Array[Dictionary]:
	var charges: Array[Dictionary] = []
	collect_charges_from_group(session, charges, "equipment", session.player.get("equipment_attachments", {}))
	collect_charges_from_group(session, charges, "skill", session.player.get("skill_attachments", {}))
	collect_consumable_charges(session, charges, session.player.get("consumables", []))
	return charges


func use_charge(session: Variant, charge_id: String) -> void:
	session.last_events.clear()
	if session.phase != "battle":
		return
	if bool(session.charge_used.get(charge_id, false)):
		session.message = "该充能本场战斗已经使用。"
		return
	if not bool(session.charge_ready.get(charge_id, false)):
		session.message = "该充能尚未就绪。"
		return
	var charge := charge_by_id(session, charge_id)
	if charge.is_empty():
		session.message = "没有找到可用充能。"
		return
	apply_charge_effect(session, charge)
	var uses_left := _charge_uses_left(session, charge)
	uses_left = maxi(0, uses_left - 1)
	session.charge_uses_left[charge_id] = uses_left
	session.charge_ready[charge_id] = false
	session.charge_used[charge_id] = uses_left <= 0
	var label: String = session._reward_short_label(charge)
	if uses_left > 0:
		session.battle_log.append("发动充能：%s（剩余 %d 次）。" % [label, uses_left])
		session.message = "已发动充能：%s（剩余 %d 次）。" % [label, uses_left]
	else:
		session.battle_log.append("发动充能：%s（已耗尽）。" % label)
		session.message = "已发动充能：%s（已耗尽）。" % label
	session.last_events.append({"kind": "charge", "target": "player", "amount": 0})


func collect_charges_from_group(session: Variant, result: Array[Dictionary], target_type: String, groups: Dictionary) -> void:
	for target_id in groups.keys():
		var attachments: Array = groups.get(target_id, [])
		for i in range(attachments.size()):
			if result.size() >= MAX_CHARGES:
				return
			var attachment: Dictionary = attachments[i]
			var kind := String(attachment.get("kind", ""))
			if not kind.begins_with("charge_"):
				continue
			var charge := attachment.duplicate(true)
			charge["charge_id"] = "%s:%s:%d" % [target_type, String(target_id), i]
			charge["source_label"] = session._target_label({"type": target_type, "id": String(target_id)})
			charge["uses"] = maxi(1, int(charge.get("uses", 1)))
			var uses_left := _charge_uses_left(session, charge)
			charge["uses_left"] = uses_left
			charge["used"] = uses_left <= 0
			charge["ready"] = bool(session.charge_ready.get(charge["charge_id"], false)) and uses_left > 0
			result.append(charge)


func collect_consumable_charges(session: Variant, result: Array[Dictionary], consumables: Array) -> void:
	for i in range(consumables.size()):
		if result.size() >= MAX_CHARGES:
			return
		var item_id := String(consumables[i])
		if item_id == "" or not DataCatalog.CONSUMABLES.has(item_id):
			continue
		var item: Dictionary = DataCatalog.CONSUMABLES[item_id]
		var kind := String(item.get("kind", ""))
		if not kind.begins_with("charge_"):
			continue
		var charge := item.duplicate(true)
		charge["charge_id"] = "consumable:%d" % i
		charge["target_type"] = "consumable"
		charge["target_id"] = item_id
		charge["source_label"] = session._target_label({"type": "consumable", "id": item_id})
		charge["uses"] = maxi(1, int(charge.get("uses", 1)))
		var uses_left := _charge_uses_left(session, charge)
		charge["uses_left"] = uses_left
		charge["used"] = uses_left <= 0
		charge["ready"] = bool(session.charge_ready.get(charge["charge_id"], false)) and uses_left > 0
		result.append(charge)


func charge_by_id(session: Variant, charge_id: String) -> Dictionary:
	for charge in available_charges(session):
		if String(charge.get("charge_id", "")) == charge_id:
			return charge
	return {}


func random_ready_charge(session: Variant) -> String:
	var charges := available_charges(session)
	var candidates: Array[Dictionary] = []
	for charge in charges:
		var charge_id := String(charge.get("charge_id", ""))
		if bool(charge.get("used", false)):
			continue
		if bool(charge.get("ready", false)):
			continue
		candidates.append(charge)
	if candidates.is_empty():
		return ""
	rng.randomize()
	var selected: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
	var selected_id := String(selected.get("charge_id", ""))
	session.charge_ready[selected_id] = true
	return session._reward_short_label(selected)


func apply_charge_effect(session: Variant, charge: Dictionary) -> void:
	if _apply_direct_charge_effect(session, charge):
		return
	ensure_charge_effects(session)
	var effects := charge_effect_bucket(session, charge)
	apply_charge_to_bucket(effects, charge)


func charge_effect_bucket(session: Variant, charge: Dictionary) -> Dictionary:
	var target_type := String(charge.get("target_type", ""))
	var target_id := String(charge.get("target_id", ""))
	if target_type == "skill" and target_id != "":
		var skills: Dictionary = session.pending_charge_effects.get("skills", {})
		if not skills.has(target_id):
			skills[target_id] = empty_charge_values()
		session.pending_charge_effects["skills"] = skills
		return skills[target_id]
	return session.pending_charge_effects["global"]


func _charge_uses_left(session: Variant, charge: Dictionary) -> int:
	var charge_id := String(charge.get("charge_id", ""))
	var max_uses := maxi(1, int(charge.get("uses", 1)))
	if charge_id == "":
		return max_uses
	return maxi(0, int(session.charge_uses_left.get(charge_id, max_uses)))


func apply_charge_attack_modifiers(session: Variant, base: int, skill_id: String = "") -> int:
	ensure_charge_effects(session)
	var effects := merged_charge_effects(session, skill_id)
	var result := compute_charge_attack(base, effects)
	clear_charge_attack_effects(session, skill_id)
	return result


func apply_charge_defense_modifiers(session: Variant, base: int, skill_id: String = "") -> int:
	ensure_charge_effects(session)
	var effects := merged_charge_effects(session, skill_id)
	var result := compute_charge_defense(base, effects)
	clear_charge_defense_effects(session, skill_id)
	return result


func consume_charge_repeat(session: Variant, action_tag: String, skill_id: String = "") -> int:
	ensure_charge_effects(session)
	var repeats := consume_repeats_from_bucket(session.pending_charge_effects["global"], action_tag)
	if skill_id != "":
		var skills: Dictionary = session.pending_charge_effects.get("skills", {})
		if skills.has(skill_id):
			repeats += consume_repeats_from_bucket(skills[skill_id], action_tag)
	return repeats


func merged_charge_effects(session: Variant, skill_id: String) -> Dictionary:
	var global_effects: Dictionary = session.pending_charge_effects["global"]
	if skill_id != "":
		var skills: Dictionary = session.pending_charge_effects.get("skills", {})
		if skills.has(skill_id):
			return merge_charge_buckets(global_effects, skills[skill_id])
	return global_effects.duplicate(true)


func clear_charge_attack_effects(session: Variant, skill_id: String) -> void:
	session.pending_charge_effects["global"]["attack_multiplier"] = 1.0
	session.pending_charge_effects["global"]["bonus_damage"] = 0
	if skill_id != "":
		var skills: Dictionary = session.pending_charge_effects.get("skills", {})
		if skills.has(skill_id):
			skills[skill_id]["attack_multiplier"] = 1.0
			skills[skill_id]["bonus_damage"] = 0


func clear_charge_defense_effects(session: Variant, skill_id: String) -> void:
	session.pending_charge_effects["global"]["defense_multiplier"] = 1.0
	if skill_id != "":
		var skills: Dictionary = session.pending_charge_effects.get("skills", {})
		if skills.has(skill_id):
			skills[skill_id]["defense_multiplier"] = 1.0


func ensure_charge_effects(session: Variant) -> void:
	if session.pending_charge_effects.is_empty():
		session.pending_charge_effects = empty_charge_effects()
	if not session.pending_charge_effects.has("global"):
		var legacy: Dictionary = session.pending_charge_effects.duplicate(true)
		session.pending_charge_effects = empty_charge_effects()
		for key in empty_charge_values().keys():
			if legacy.has(key):
				session.pending_charge_effects["global"][key] = legacy[key]
	if not session.pending_charge_effects.has("skills"):
		session.pending_charge_effects["skills"] = {}
	for key in empty_charge_values().keys():
		if not session.pending_charge_effects["global"].has(key):
			session.pending_charge_effects["global"][key] = empty_charge_values()[key]


func empty_charge_effects() -> Dictionary:
	return {
		"global": empty_charge_values(),
		"skills": {}
	}


func empty_charge_values() -> Dictionary:
	return {
		"attack_multiplier": 1.0,
		"defense_multiplier": 1.0,
		"bonus_damage": 0,
		"repeat_attack": 0,
		"repeat_defense": 0
	}


static func apply_charge_to_bucket(bucket: Dictionary, charge: Dictionary) -> void:
	match String(charge.get("kind", "")):
		"charge_attack_multiplier":
			bucket["attack_multiplier"] = float(bucket.get("attack_multiplier", 1.0)) * float(charge.get("value", 1.0))
		"charge_defense_multiplier":
			bucket["defense_multiplier"] = float(bucket.get("defense_multiplier", 1.0)) * float(charge.get("value", 1.0))
		"charge_bonus_damage":
			bucket["bonus_damage"] = int(bucket.get("bonus_damage", 0)) + int(charge.get("value", 0))
		"charge_repeat_attack":
			bucket["repeat_attack"] = int(bucket.get("repeat_attack", 0)) + maxi(1, int(charge.get("value", 1)))
		"charge_repeat_defense":
			bucket["repeat_defense"] = int(bucket.get("repeat_defense", 0)) + maxi(1, int(charge.get("value", 1)))


static func merge_charge_buckets(global_bucket: Dictionary, skill_bucket: Dictionary) -> Dictionary:
	var result := global_bucket.duplicate(true)
	result["attack_multiplier"] = float(result.get("attack_multiplier", 1.0)) * float(skill_bucket.get("attack_multiplier", 1.0))
	result["defense_multiplier"] = float(result.get("defense_multiplier", 1.0)) * float(skill_bucket.get("defense_multiplier", 1.0))
	result["bonus_damage"] = int(result.get("bonus_damage", 0)) + int(skill_bucket.get("bonus_damage", 0))
	result["repeat_attack"] = int(result.get("repeat_attack", 0)) + int(skill_bucket.get("repeat_attack", 0))
	result["repeat_defense"] = int(result.get("repeat_defense", 0)) + int(skill_bucket.get("repeat_defense", 0))
	return result


static func compute_charge_attack(base: int, bucket: Dictionary) -> int:
	return maxi(1, int(round(float(base) * float(bucket.get("attack_multiplier", 1.0)))) + int(bucket.get("bonus_damage", 0)))


static func compute_charge_defense(base: int, bucket: Dictionary) -> int:
	return maxi(1, int(round(float(base) * float(bucket.get("defense_multiplier", 1.0)))))


static func consume_repeats_from_bucket(bucket: Dictionary, action_tag: String) -> int:
	var key := "repeat_attack" if action_tag == "attack" else "repeat_defense"
	var repeats := int(bucket.get(key, 0))
	bucket[key] = 0
	return repeats


static func charge_count(player: Dictionary) -> int:
	var total := 0
	for item_id in player.get("consumables", []):
		var consumable_id := String(item_id)
		if consumable_id == "" or not DataCatalog.CONSUMABLES.has(consumable_id):
			continue
		if is_charge_kind(String(DataCatalog.CONSUMABLES[consumable_id].get("kind", ""))):
			total += 1
	for groups in [player.get("equipment_attachments", {}), player.get("skill_attachments", {})]:
		for attachments in groups.values():
			for attachment in attachments:
				if is_charge_kind(String(attachment.get("kind", ""))):
					total += 1
	return total


static func is_charge_kind(kind: String) -> bool:
	return kind.begins_with("charge_")


static func attachment_multiplier_value(value: float) -> float:
	if absf(value) >= 1.0:
		return value * 0.05
	return value


static func attachment_stat_kind(kind: String) -> String:
	match kind:
		"attack":
			return "attack"
		"skill_power":
			return "skill_power"
		"defense":
			return "defense"
		"hp":
			return "hp"
		"state":
			return "state_attack"
		"state_defense":
			return "state_defense"
		"extra_hits":
			return "extra_hits"
	return kind


func _apply_direct_charge_effect(session: Variant, charge: Dictionary) -> bool:
	var kind := String(charge.get("kind", ""))
	if kind == "charge_heal_percent":
		var heal_ratio := float(charge.get("value", 0.0))
		if heal_ratio <= 0.0:
			return true
		var max_hp := int(session.player.get("max_hp", session.player.get("base_max_hp", 1)))
		var current_hp := int(session.player.get("hp", max_hp))
		var heal_amount := maxi(1, int(round(float(max_hp) * heal_ratio)))
		session.player["hp"] = mini(max_hp, current_hp + heal_amount)
		session.battle_log.append("%s 回复了 %d 点生命。" % [String(charge.get("name", "充能")), heal_amount])
		return true
	return false
