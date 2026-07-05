extends RefCounted
class_name CharacterService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const MAX_CHARGES := 5


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
		"equipment_attachments": {},
		"skill_attachments": {},
		"equipment": {},
		"equipment_ids": [],
		"unlocked_skills": [],
		"equipped_skills": [],
		"tutorial_completed": false,
		"battles_completed": 0,
		"boss_rewards": 0,
		"normal_rewards": 0,
		"elite_rewards": 0,
		"tutorial_restarts": 0
	}
	recalculate_player_stats(player, true)
	return player


func equip_item(player: Dictionary, item_id: String) -> void:
	var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
	player["equipment"][item["slot"]] = item_id
	if not player["equipment_ids"].has(item_id):
		player["equipment_ids"].append(item_id)


func unlock_skill(player: Dictionary, skill_id: String, equip_now: bool) -> void:
	if not player["unlocked_skills"].has(skill_id):
		player["unlocked_skills"].append(skill_id)
	if equip_now and not player["equipped_skills"].has(skill_id) and player["equipped_skills"].size() < 4:
		player["equipped_skills"].append(skill_id)


func unlock_next_skill(player: Dictionary) -> void:
	var class_id: String = player["class_id"]
	for skill_id in DataCatalog.SKILLS.keys():
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		if skill.get("class", "") == class_id and not player["unlocked_skills"].has(skill_id):
			unlock_skill(player, skill_id, player["equipped_skills"].size() < 4)
			return
	for skill_id in DataCatalog.SKILLS.keys():
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		if skill.get("class", "") == "common" and not player["unlocked_skills"].has(skill_id):
			unlock_skill(player, skill_id, player["equipped_skills"].size() < 4)
			return


func attach_reward(player: Dictionary, target: Dictionary, reward: Dictionary) -> void:
	if target.is_empty():
		return
	if is_charge_kind(String(reward.get("kind", ""))) and charge_count(player) >= MAX_CHARGES:
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


func equipment_target_by_slot(player: Dictionary, slot: String) -> Dictionary:
	var equipment: Dictionary = player.get("equipment", {})
	if equipment.has(slot):
		return {"type": "equipment", "id": String(equipment[slot])}
	return {}


func skill_attachment_bonus(player: Dictionary, skill_id: String, kind: String) -> int:
	var total := 0
	var attachments: Dictionary = player.get("skill_attachments", {})
	for attachment in attachments.get(skill_id, []):
		if attachment_stat_kind(String(attachment.get("kind", ""))) == kind:
			total += int(attachment.get("value", 0))
	return total


func skill_multiplier_bonus(player: Dictionary, skill_id: String, kind: String = "") -> float:
	var total := 0.0
	var attachments: Dictionary = player.get("skill_attachments", {})
	for attachment in attachments.get(skill_id, []):
		var attachment_kind := attachment_stat_kind(String(attachment.get("kind", "")))
		if attachment_kind == "skill_power" or attachment_kind == kind:
			total += attachment_multiplier_value(float(attachment.get("value", 0.0)))
	return total


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
	var equipment_attachments: Dictionary = player.get("equipment_attachments", {})
	for item_id in player["equipment_ids"]:
		var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
		hp += int(item["hp"])
		attack += int(item["attack"])
		defense += int(item["armor"])
		block_power += int(item.get("block", 0))
		for attachment in equipment_attachments.get(item_id, []):
			match attachment_stat_kind(String(attachment.get("kind", ""))):
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
	var skill_attachments: Dictionary = player.get("skill_attachments", {})
	for skill_id in player["equipped_skills"]:
		for attachment in skill_attachments.get(skill_id, []):
			match attachment_stat_kind(String(attachment.get("kind", ""))):
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


func charge_count(player: Dictionary) -> int:
	var total := 0
	for groups in [player.get("equipment_attachments", {}), player.get("skill_attachments", {})]:
		for attachments in groups.values():
			for attachment in attachments:
				if is_charge_kind(String(attachment.get("kind", ""))):
					total += 1
	return total


func is_charge_kind(kind: String) -> bool:
	return kind.begins_with("charge_")


func attachment_multiplier_value(value: float) -> float:
	if absf(value) >= 1.0:
		return value * 0.05
	return value


func attachment_stat_kind(kind: String) -> String:
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
	return kind
