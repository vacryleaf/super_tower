extends RefCounted
class_name CharacterService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const ChargeService = preload("res://scripts/core/charge_service.gd")
const EquipmentService = preload("res://scripts/core/equipment_service.gd")
const MAX_CHARGES := 5

var equipment := EquipmentService.new()


func create_character(class_id: String) -> Dictionary:
	var class_data: Dictionary = DataCatalog.CLASSES[class_id]
	var player := {
		"class_id": class_id,
		"base_max_hp": int(class_data["max_hp"]),
		"base_attack": int(class_data["base_attack"]),
		"base_defense": int(class_data["base_defense"]),
		"base_block": int(class_data.get("base_block", 1)),
		"max_hp_bonus": 0,
		"attack_bonus": 0,
		"defense_bonus": 0,
		"block_bonus": 0,
		"skill_bonus": 0,
		"state_attack_bonus": 0,
		"state_defense_bonus": 0,
		"extra_hits": 0,
		"set_counts": {},
		"active_set_effects": {},
		"equipment_attachments": {},
		"skill_attachments": {},
		"equipment": {},
		"equipment_ids": [],
		"unlocked_skills": [],
		"equipped_skills": [],
		"innate_skills": {
			"attack": "innate_attack",
			"defend": "innate_defend",
			"dodge": "innate_dodge"
		},
		"tutorial_completed": false,
		"battles_completed": 0,
		"highest_floor": 0,
		"boss_rewards": 0,
		"normal_rewards": 0,
		"elite_rewards": 0,
		"tutorial_restarts": 0
	}
	recalculate_player_stats(player, true)
	return player


func equip_item(player: Dictionary, item_id: String) -> void:
	equipment.equip_item(player, item_id)


func unlock_skill(player: Dictionary, skill_id: String, equip_now: bool) -> void:
	equipment.unlock_skill(player, skill_id, equip_now)


func unlock_next_skill(player: Dictionary) -> void:
	equipment.unlock_next_skill(player)


func equipment_target_by_slot(player: Dictionary, slot: String) -> Dictionary:
	return equipment.equipment_target_by_slot(player, slot)


func attach_reward(player: Dictionary, target: Dictionary, reward: Dictionary) -> void:
	if target.is_empty():
		return
	if ChargeService.is_charge_kind(String(reward.get("kind", ""))) and ChargeService.charge_count(player) >= MAX_CHARGES:
		return
	var target_type := String(target.get("type", ""))
	var target_id := String(target.get("id", ""))
	if target_type == "" or target_id == "":
		return
	var key := "equipment_attachments" if target_type == "equipment" else "skill_attachments"
	if not player.has(key):
		player[key] = {}
	if not player[key].has(target_id):
		player[key][target_id] = []
	var attachment := reward.duplicate(true)
	attachment["kind"] = String(attachment.get("kind", ""))
	attachment["label"] = String(attachment.get("label", ""))
	attachment["target_type"] = target_type
	attachment["target_id"] = target_id
	player[key][target_id].append(attachment)


func preferred_attachment_target(player: Dictionary, reward_kind: String) -> Dictionary:
	if reward_kind == "attack":
		var weapon := equipment_target_by_slot(player, "weapon")
		if not weapon.is_empty():
			return weapon
	if reward_kind == "defense":
		for slot in ["offhand", "body", "head", "legs"]:
			var armor_target := equipment_target_by_slot(player, slot)
			if not armor_target.is_empty():
				return armor_target
	if reward_kind == "skill" and not player["equipped_skills"].is_empty():
		return {"type": "skill", "id": String(player["equipped_skills"][0])}
	if reward_kind == "state" and not player["equipment_ids"].is_empty():
		return {"type": "equipment", "id": String(player["equipment_ids"][0])}
	if reward_kind == "charge" and not player["equipment_ids"].is_empty():
		return {"type": "equipment", "id": String(player["equipment_ids"][0])}
	if not player["equipment_ids"].is_empty():
		return {"type": "equipment", "id": String(player["equipment_ids"][0])}
	if not player["equipped_skills"].is_empty():
		return {"type": "skill", "id": String(player["equipped_skills"][0])}
	return {}


func skill_attachment_bonus(player: Dictionary, skill_id: String, kind: String) -> int:
	var total := 0
	var attachments: Dictionary = player.get("skill_attachments", {})
	for attachment in attachments.get(skill_id, []):
		if ChargeService.attachment_stat_kind(String(attachment.get("kind", ""))) == kind:
			total += int(attachment.get("value", 0))
	return total


func skill_multiplier_bonus(player: Dictionary, skill_id: String, kind: String = "") -> float:
	var total := 0.0
	var attachments: Dictionary = player.get("skill_attachments", {})
	for attachment in attachments.get(skill_id, []):
		var attachment_kind := ChargeService.attachment_stat_kind(String(attachment.get("kind", "")))
		if attachment_kind == "skill_power" or attachment_kind == kind:
			total += ChargeService.attachment_multiplier_value(float(attachment.get("value", 0.0)))
	return total


func charge_count(player: Dictionary) -> int:
	return ChargeService.charge_count(player)


func is_charge_kind(kind: String) -> bool:
	return ChargeService.is_charge_kind(kind)


func attachment_multiplier_value(value: float) -> float:
	return ChargeService.attachment_multiplier_value(value)


func attachment_stat_kind(kind: String) -> String:
	return ChargeService.attachment_stat_kind(kind)


func recalculate_player_stats(player: Dictionary, reset_hp: bool) -> void:
	if not player.has("base_block"):
		var class_data: Dictionary = DataCatalog.CLASSES[String(player.get("class_id", "warrior"))]
		player["base_block"] = int(class_data.get("base_block", 1))
	if not player.has("block_bonus"):
		player["block_bonus"] = 0
	var hp := int(player["base_max_hp"]) + int(player["max_hp_bonus"])
	var attack := int(player["base_attack"]) + int(player["attack_bonus"])
	var defense := int(player["base_defense"]) + int(player["defense_bonus"])
	var block_power := int(player["base_block"]) + int(player["block_bonus"])
	player["state_attack_bonus"] = 0
	player["state_defense_bonus"] = 0
	player["extra_hits"] = 0
	player["innate_skills"] = {
		"attack": "innate_attack",
		"defend": "innate_defend",
		"dodge": "innate_dodge"
	}
	var set_counts := _equipment_set_counts(player)
	var equipment_attachments: Dictionary = player.get("equipment_attachments", {})
	var equipped_ids := _equipped_item_ids(player)
	for item_id in equipped_ids:
		var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
		hp += int(item["hp"])
		attack += int(item["attack"])
		defense += int(item["armor"])
		block_power += int(item.get("block", 0))
		for attachment in equipment_attachments.get(item_id, []):
			match ChargeService.attachment_stat_kind(String(attachment.get("kind", ""))):
				"attack":
					attack += int(attachment.get("value", 0))
				"defense":
					defense += int(attachment.get("value", 0))
				"hp":
					hp += int(attachment.get("value", 0))
				"state_attack":
					player["state_attack_bonus"] += int(attachment.get("value", 0))
				"state_defense":
					player["state_defense_bonus"] += int(attachment.get("value", 0))
				"extra_hits":
					player["extra_hits"] += int(attachment.get("value", 0))
	var active_set_effects := _active_set_effects(set_counts)
	player["set_counts"] = set_counts
	player["active_set_effects"] = active_set_effects
	var flat_stats: Dictionary = active_set_effects.get("flat_stats", {})
	hp += int(flat_stats.get("hp", 0))
	attack += int(flat_stats.get("attack", 0))
	defense += int(flat_stats.get("armor", flat_stats.get("defense", 0)))
	block_power += int(flat_stats.get("block", 0))
	player["state_attack_bonus"] += int(flat_stats.get("state_attack", 0))
	player["state_defense_bonus"] += int(flat_stats.get("state_defense", 0))
	player["extra_hits"] += int(flat_stats.get("extra_hits", 0))
	var skill_attachments: Dictionary = player.get("skill_attachments", {})
	for skill_id in player["equipped_skills"]:
		for attachment in skill_attachments.get(skill_id, []):
			match ChargeService.attachment_stat_kind(String(attachment.get("kind", ""))):
				"hp":
					hp += int(attachment.get("value", 0))
				"state_attack":
					player["state_attack_bonus"] += int(attachment.get("value", 0))
				"state_defense":
					player["state_defense_bonus"] += int(attachment.get("value", 0))
	var old_max := int(player.get("max_hp", hp))
	player["max_hp"] = hp
	player["attack"] = attack
	player["defense"] = defense
	player["block_power"] = block_power
	if reset_hp or not player.has("hp"):
		player["hp"] = hp
	else:
		player["hp"] = mini(hp, int(player["hp"]) + maxi(0, hp - old_max))


func _equipment_set_counts(player: Dictionary) -> Dictionary:
	var counts := {}
	for item_id in _equipped_item_ids(player):
		if not DataCatalog.EQUIPMENT.has(item_id):
			continue
		var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
		var set_id := String(item.get("set_id", ""))
		if set_id == "":
			continue
		counts[set_id] = int(counts.get(set_id, 0)) + 1
	return counts


func _equipped_item_ids(player: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var equipped: Dictionary = player.get("equipment", {})
	for item_id in equipped.values():
		result.append(String(item_id))
	return result


func _active_set_effects(set_counts: Dictionary) -> Dictionary:
	var effects := {
		"modifiers": [],
		"on_battle_start": [],
		"flat_stats": {"hp": 0, "attack": 0, "armor": 0, "defense": 0, "block": 0, "state_attack": 0, "state_defense": 0, "extra_hits": 0},
		"set_requirement_delta": 0
	}
	var requirement_delta := 0
	for set_id in set_counts.keys():
		if not DataCatalog.EQUIPMENT_SETS.has(set_id):
			continue
		var set_data: Dictionary = DataCatalog.EQUIPMENT_SETS[set_id]
		var bonuses: Dictionary = set_data.get("bonuses", {})
		if int(set_counts[set_id]) >= 2 and bonuses.has(2):
			requirement_delta += int((bonuses[2] as Dictionary).get("set_requirement_delta", 0))
	effects["set_requirement_delta"] = requirement_delta
	for set_id in set_counts.keys():
		if not DataCatalog.EQUIPMENT_SETS.has(set_id):
			continue
		var set_data: Dictionary = DataCatalog.EQUIPMENT_SETS[set_id]
		var bonuses: Dictionary = set_data.get("bonuses", {})
		for raw_threshold in bonuses.keys():
			var threshold := int(raw_threshold)
			var adjusted_threshold := threshold
			if threshold >= 3:
				adjusted_threshold = maxi(2, threshold - requirement_delta)
			if int(set_counts[set_id]) >= adjusted_threshold:
				_merge_set_bonus(effects, bonuses[raw_threshold], String(set_id), threshold)
	return effects


func _merge_set_bonus(effects: Dictionary, bonus: Dictionary, set_id: String, threshold: int) -> void:
	for key in bonus.keys():
		if key == "label":
			continue
		if key == "modifiers":
			for mod in bonus[key]:
				var mod_copy: Dictionary = mod.duplicate(true)
				mod_copy["source"] = "set:%s:%d" % [set_id, threshold]
				effects["modifiers"].append(mod_copy)
		elif key == "on_battle_start":
			for action in bonus[key]:
				effects["on_battle_start"].append(action.duplicate(true))
		elif key == "set_requirement_delta":
			pass
		elif effects["flat_stats"].has(key):
			effects["flat_stats"][key] = effects["flat_stats"][key] + bonus[key]
		else:
			effects[key] = effects.get(key, 0) + bonus[key]