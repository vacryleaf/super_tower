extends RefCounted
class_name CharacterService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const ChargeService = preload("res://scripts/core/charge_service.gd")
const EquipmentService = preload("res://scripts/core/equipment_service.gd")
const MAX_CHARGES := 5

var equipment := EquipmentService.new()


func create_character(class_id: String) -> Dictionary:
	var normalized_class_id := DataCatalog.normalize_class_id(class_id)
	var class_data: Dictionary = DataCatalog.CLASSES[normalized_class_id]
	var player := {
		"class_id": normalized_class_id,
		"side": "player",
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
		"agility": 15,
		"critical_weight": 20,
		"critical_damage_bonus": 0.0,
		"attack_energy_gain": DataCatalog.ATTACK_ENERGY,
		"weapon_profile_id": "warrior_training_sword",
		"weapon_skill_1": "po_jun",
		"weapon_skill_2": "explosive_strike",
		"equipment_attachments": {},
		"skill_attachments": {},
		"equipment": {},
		"equipment_ids": [],
		"tower_equipment": {"weapon": "warrior_training_sword"},
		"tower_equipment_ids": ["warrior_training_sword"],
		"consumables": [],
		"consumable_ids": [],
		"tower_consumables": [],
		"blood_potion_level": 0,
		"blood_potion_uses": int(DataCatalog.BLOOD_POTION.get("starting_uses", 0)),
		"blood_potion_seed": 0,
		"unlocked_skills": [],
		"equipped_skills": [],
		"tower_equipped_skills": ["", "", "", ""],
		"passive_skills": ["", "", "", ""],
		"tower_passive_skills": [],
		"passive_skill_slots": 0,
		"unlocked_passive_skills": [],
		"permanent_equipment_upgrades": {},
		"permanent_skill_upgrades": {},
		"innate_skills": {
			"attack_1": "innate_attack_1",
			"defend": "innate_defend",
			"dodge": "innate_dodge"
		},
		"energy": 0,
		"skill_cooldowns": {},
		"tutorial_completed": false,
		"battles_completed": 0,
		"highest_floor": 0,
		"boss_rewards": 0,
		"normal_rewards": 0,
		"elite_rewards": 0,
		"tutorial_restarts": 0
	}
	_ensure_player_schema(player)
	recalculate_player_stats(player, true)
	return player


func equip_item(player: Dictionary, item_id: String) -> void:
	equipment.equip_item(player, item_id)
	recalculate_player_stats(player, false)


func equip_tower_item(player: Dictionary, item_id: String) -> bool:
	if not DataCatalog.EQUIPMENT.has(item_id):
		return false
	var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
	var slot := DataCatalog.equipment_slot(item)
	if slot == "":
		return false
	var tower_equipment: Dictionary = player.get("tower_equipment", {})
	var ids: Array = player.get("tower_equipment_ids", [])
	if not ids.has(item_id) and ids.size() >= DataCatalog.TOWER_EQUIPMENT_SLOTS:
		return false
	tower_equipment[slot] = item_id
	player["tower_equipment"] = tower_equipment
	if not ids.has(item_id):
		ids.append(item_id)
	player["tower_equipment_ids"] = ids
	recalculate_player_stats(player, false)
	return true


func add_tower_consumable(player: Dictionary, item_id: String, upgraded: bool = false) -> void:
	if not DataCatalog.CONSUMABLES.has(item_id):
		return
	var tower_consumables: Array = player.get("tower_consumables", [])
	tower_consumables.append({"id": item_id, "upgraded": true} if upgraded else item_id)
	player["tower_consumables"] = tower_consumables


func add_tower_skill(player: Dictionary, skill_id: String) -> void:
	if not DataCatalog.SKILLS.has(skill_id):
		return
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var slot := int(skill.get("slot", 0))
	if slot < 3 or slot > 4:
		return
	var tower_skills: Array = player.get("tower_equipped_skills", ["", "", "", ""])
	while tower_skills.size() < 4:
		tower_skills.append("")
	tower_skills[slot - 1] = skill_id
	player["tower_equipped_skills"] = tower_skills


func unlock_passive_skill(player: Dictionary, skill_id: String, equip_now: bool = true) -> void:
	if not DataCatalog.PASSIVE_SKILLS.has(skill_id):
		return
	var unlocked: Array = player.get("unlocked_passive_skills", [])
	if not unlocked.has(skill_id):
		unlocked.append(skill_id)
	player["unlocked_passive_skills"] = unlocked
	if equip_now:
		var passives: Array = player.get("passive_skills", ["", "", "", ""])
		while passives.size() < 4:
			passives.append("")
		for index in range(mini(4, int(player.get("passive_skill_slots", 0)))):
			if String(passives[index]) == "":
				passives[index] = skill_id
				break
		player["passive_skills"] = passives


func add_tower_passive_skill(player: Dictionary, skill_id: String) -> void:
	if not DataCatalog.PASSIVE_SKILLS.has(skill_id):
		return
	var passives: Array = player.get("tower_passive_skills", [])
	if passives.size() < int(player.get("passive_skill_slots", 0)):
		passives.append(skill_id)
	player["tower_passive_skills"] = passives


func apply_permanent_upgrade(player: Dictionary, target_type: String, target_id: String, kind: String, value: float) -> void:
	var key := "permanent_equipment_upgrades" if target_type == "equipment" else "permanent_skill_upgrades"
	var upgrades: Dictionary = player.get(key, {})
	var entries: Array = upgrades.get(target_id, [])
	entries.append({"kind": kind, "value": value})
	upgrades[target_id] = entries
	player[key] = upgrades
	recalculate_player_stats(player, false)


func use_blood_potion(player: Dictionary, heal_multiplier: float = 1.0) -> Dictionary:
	var uses_left := int(player.get("blood_potion_uses", 0))
	var max_hp := int(player.get("max_hp", player.get("base_max_hp", 1)))
	var current_hp := int(player.get("hp", max_hp))
	if uses_left <= 0:
		return {"used": false, "reason": "empty"}
	if current_hp >= max_hp:
		return {"used": false, "reason": "full"}
	var level := maxi(0, int(player.get("blood_potion_level", 0)))
	var base_ratio := float(DataCatalog.BLOOD_POTION.get("heal_ratio", 0.0))
	var level_ratio := float(DataCatalog.BLOOD_POTION.get("level_heal_ratio", 0.0))
	var heal_amount := maxi(1, int(ceil(float(max_hp) * (base_ratio + level_ratio * level))))
	heal_amount = maxi(1, int(ceil(float(heal_amount) * maxf(0.0, heal_multiplier))))
	heal_amount = mini(heal_amount, max_hp - current_hp)
	player["hp"] = current_hp + heal_amount
	player["blood_potion_uses"] = uses_left - 1
	return {"used": true, "amount": heal_amount, "uses_left": uses_left - 1}



func skill_id_for_slot(player: Dictionary, slot_index: int) -> String:
	if slot_index == 0:
		return String(player.get("weapon_skill_1", ""))
	if slot_index == 1:
		return String(player.get("weapon_skill_2", ""))
	var tower_skills: Array = player.get("tower_equipped_skills", [])
	if slot_index >= 0 and slot_index < tower_skills.size() and String(tower_skills[slot_index]) != "":
		return String(tower_skills[slot_index])
	var equipped: Array = player.get("equipped_skills", [])
	if slot_index >= 0 and slot_index < equipped.size():
		return String(equipped[slot_index])
	return ""

func unlock_skill(player: Dictionary, skill_id: String, equip_now: bool) -> void:
	equipment.unlock_skill(player, skill_id, equip_now)


func unlock_next_skill(player: Dictionary) -> void:
	equipment.unlock_next_skill(player)


func equipment_target_by_slot(player: Dictionary, slot: String) -> Dictionary:
	var target := equipment.equipment_target_by_slot(player, slot)
	if not target.is_empty():
		return target
	var tower_equipment: Dictionary = player.get("tower_equipment", {})
	var normalized_slot := DataCatalog.equipment_slot(slot)
	var tower_item_id := String(tower_equipment.get(normalized_slot, ""))
	if tower_item_id == "":
		return {}
	return {"type": "equipment", "id": tower_item_id}


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
	if reward_kind == "skill":
		for skill_id in player["equipped_skills"]:
			if String(skill_id) != "":
				return {"type": "skill", "id": skill_id}
	if reward_kind == "skill_power":
		for skill_id in player["equipped_skills"]:
			if String(skill_id) != "":
				return {"type": "skill", "id": skill_id}
	if reward_kind == "state" and not player["equipment_ids"].is_empty():
		return {"type": "equipment", "id": String(player["equipment_ids"][0])}
	if reward_kind == "charge" and not player["equipment_ids"].is_empty():
		return {"type": "equipment", "id": String(player["equipment_ids"][0])}
	if not player["equipment_ids"].is_empty():
		return {"type": "equipment", "id": String(player["equipment_ids"][0])}
	for skill_id in player["equipped_skills"]:
		if String(skill_id) != "":
			return {"type": "skill", "id": skill_id}
	return {}


func skill_attachment_bonus(player: Dictionary, skill_id: String, kind: String) -> int:
	var total := 0
	var attachments: Dictionary = player.get("skill_attachments", {}).duplicate(true)
	var permanent: Dictionary = player.get("permanent_skill_upgrades", {})
	attachments[skill_id] = attachments.get(skill_id, []) + permanent.get(skill_id, [])
	for attachment in attachments.get(skill_id, []):
		if ChargeService.attachment_stat_kind(String(attachment.get("kind", ""))) == kind:
			total += int(attachment.get("value", 0))
	return total


func skill_multiplier_bonus(player: Dictionary, skill_id: String, kind: String = "") -> float:
	var total := 0.0
	var attachments: Dictionary = player.get("skill_attachments", {}).duplicate(true)
	var permanent: Dictionary = player.get("permanent_skill_upgrades", {})
	attachments[skill_id] = attachments.get(skill_id, []) + permanent.get(skill_id, [])
	for attachment in attachments.get(skill_id, []):
		var attachment_kind := ChargeService.attachment_stat_kind(String(attachment.get("kind", "")))
		if attachment_kind == "skill_power" or attachment_kind == kind:
			total += ChargeService.attachment_multiplier_value(float(attachment.get("value", 0.0)))
	var equipment_attachments: Dictionary = player.get("equipment_attachments", {}).duplicate(true)
	var permanent_equipment: Dictionary = player.get("permanent_equipment_upgrades", {})
	for item_id in permanent_equipment.keys():
		equipment_attachments[item_id] = equipment_attachments.get(item_id, []) + permanent_equipment[item_id]
	for equipment_attachment_list in equipment_attachments.values():
		for attachment in equipment_attachment_list:
			if ChargeService.attachment_stat_kind(String(attachment.get("kind", ""))) == "skill_power":
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


func ensure_player_schema(player: Dictionary) -> void:
	_ensure_player_schema(player)


func recalculate_player_stats(player: Dictionary, reset_hp: bool) -> void:
	_ensure_player_schema(player)
	var hp := int(player["base_max_hp"]) + int(player["max_hp_bonus"])
	var attack := int(player["base_attack"]) + int(player["attack_bonus"])
	var defense := int(player["base_defense"]) + int(player["defense_bonus"])
	var block_power := int(player["base_block"]) + int(player["block_bonus"])
	player["state_attack_bonus"] = 0
	player["state_defense_bonus"] = 0
	player["extra_hits"] = 0
	player["innate_skills"] = {
		"attack_1": "innate_attack_1",
		"defend": "innate_defend",
		"dodge": "innate_dodge"
	}
	var weapon_profile := DataCatalog.weapon_profile_for_player(player)
	player["agility"] = int(weapon_profile.get("agility", 15))
	player["critical_weight"] = int(weapon_profile.get("critical_weight", 0))
	player["critical_damage_bonus"] = float(weapon_profile.get("critical_damage_bonus", 0.0))
	player["attack_energy_gain"] = int(weapon_profile.get("attack_energy_gain", DataCatalog.ATTACK_ENERGY))
	player["weapon_skill_1"] = String(weapon_profile.get("skill_1", ""))
	player["weapon_skill_2"] = String(weapon_profile.get("skill_2", ""))
	var weapon_id := String(player.get("tower_equipment", {}).get("weapon", player.get("equipment", {}).get("weapon", "")))
	player["weapon_profile_id"] = String(weapon_id if weapon_id != "" else "unarmed")
	attack += int(weapon_profile.get("attack_damage", 0))
	var equipment_attachments: Dictionary = player.get("equipment_attachments", {}).duplicate(true)
	var permanent_equipment_upgrades: Dictionary = player.get("permanent_equipment_upgrades", {})
	for item_id in permanent_equipment_upgrades.keys():
		equipment_attachments[item_id] = equipment_attachments.get(item_id, []) + permanent_equipment_upgrades[item_id]
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
	var skill_attachments: Dictionary = player.get("skill_attachments", {}).duplicate(true)
	var permanent_skill_upgrades: Dictionary = player.get("permanent_skill_upgrades", {})
	for skill_id in permanent_skill_upgrades.keys():
		skill_attachments[skill_id] = skill_attachments.get(skill_id, []) + permanent_skill_upgrades[skill_id]
	for skill_id in _effective_equipped_skills(player):
		if String(skill_id) == "":
			continue
		for attachment in skill_attachments.get(skill_id, []):
				match ChargeService.attachment_stat_kind(String(attachment.get("kind", ""))):
					"hp":
						hp += int(attachment.get("value", 0))
					"state_attack":
						player["state_attack_bonus"] += int(attachment.get("value", 0))
					"state_defense":
						player["state_defense_bonus"] += int(attachment.get("value", 0))
	for passive_id in _effective_passive_skills(player):
		var passive: Dictionary = DataCatalog.PASSIVE_SKILLS.get(passive_id, {})
		for effect in passive.get("effects", []):
			if String(effect.get("stat", "")) == "max_hp" and String(effect.get("type", "flat")) == "flat":
				hp += int(effect.get("value", 0))
	var old_max := int(player.get("max_hp", hp))
	player["max_hp"] = hp
	player["attack"] = attack
	player["defense"] = defense
	player["block_power"] = block_power
	if reset_hp or not player.has("hp"):
		player["hp"] = hp
	else:
		player["hp"] = mini(hp, int(player["hp"]) + maxi(0, hp - old_max))


func _ensure_player_schema(player: Dictionary) -> void:
	var legacy_class_id := String(player.get("class_id", ""))
	var normalized_class_id := DataCatalog.normalize_class_id(legacy_class_id)
	var class_data := _class_data_for(normalized_class_id)
	player["class_id"] = normalized_class_id
	if not player.has("side"):
		player["side"] = "player"
	if not player.has("base_max_hp"):
		player["base_max_hp"] = int(class_data.get("max_hp", 1))
	if not player.has("base_attack"):
		player["base_attack"] = int(class_data.get("base_attack", 1))
	if not player.has("base_defense"):
		player["base_defense"] = int(class_data.get("base_defense", 0))
	if not player.has("base_block"):
		player["base_block"] = int(class_data.get("base_block", 1))
	if not player.has("max_hp_bonus"):
		player["max_hp_bonus"] = 0
	if not player.has("attack_bonus"):
		player["attack_bonus"] = 0
	if not player.has("defense_bonus"):
		player["defense_bonus"] = 0
	if not player.has("block_bonus"):
		player["block_bonus"] = 0
	if not player.has("skill_bonus"):
		player["skill_bonus"] = 0
	if not player.has("agility"):
		player["agility"] = 15
	if not player.has("critical_weight"):
		player["critical_weight"] = 20
	if not player.has("critical_damage_bonus"):
		player["critical_damage_bonus"] = 0.0
	if not player.has("attack_energy_gain"):
		player["attack_energy_gain"] = DataCatalog.ATTACK_ENERGY
	if not player.has("weapon_profile_id"):
		player["weapon_profile_id"] = "unarmed"
	if not player.has("weapon_skill_1"):
		player["weapon_skill_1"] = "po_jun"
	if not player.has("weapon_skill_2"):
		player["weapon_skill_2"] = "explosive_strike"
	if not player.has("equipment"):
		player["equipment"] = {}
	if not player.has("equipment_ids"):
		player["equipment_ids"] = []
	if not player.has("tower_equipment"):
		player["tower_equipment"] = {}
	if not player.has("tower_equipment_ids"):
		player["tower_equipment_ids"] = []
	var normalized_tower_ids: Array = []
	for equipped_item_id in player["tower_equipment"].values():
		var normalized_equipped_id := String(equipped_item_id)
		if normalized_equipped_id != "" and DataCatalog.EQUIPMENT.has(normalized_equipped_id) and not normalized_tower_ids.has(normalized_equipped_id):
			normalized_tower_ids.append(normalized_equipped_id)
	for item_id in player["tower_equipment_ids"]:
		var normalized_item_id := String(item_id)
		if normalized_item_id == "" or not DataCatalog.EQUIPMENT.has(normalized_item_id) or normalized_tower_ids.has(normalized_item_id):
			continue
		if normalized_tower_ids.size() >= DataCatalog.TOWER_EQUIPMENT_SLOTS:
			break
		normalized_tower_ids.append(normalized_item_id)
	player["tower_equipment_ids"] = normalized_tower_ids
	if not player.has("consumables"):
		player["consumables"] = []
	while player["consumables"].size() < DataCatalog.NORMAL_CONSUMABLE_SLOTS:
		player["consumables"].append("")
	if player["consumables"].size() > DataCatalog.NORMAL_CONSUMABLE_SLOTS:
		player["consumables"].resize(DataCatalog.NORMAL_CONSUMABLE_SLOTS)
	if not player.has("consumable_ids"):
		player["consumable_ids"] = []
	if not player.has("tower_consumables"):
		player["tower_consumables"] = []
	if not player.has("blood_potion_level"):
		player["blood_potion_level"] = 0
	if not player.has("blood_potion_uses"):
		player["blood_potion_uses"] = int(DataCatalog.BLOOD_POTION.get("starting_uses", 0))
	if not player.has("blood_potion_seed"):
		player["blood_potion_seed"] = 0
	if player["consumable_ids"].is_empty():
		player["consumable_ids"] = DataCatalog.STARTER_CONSUMABLES.duplicate()
	if not player.has("unlocked_skills"):
		player["unlocked_skills"] = []
	if not player.has("equipped_skills"):
		player["equipped_skills"] = []
	while player["equipped_skills"].size() < 4:
		player["equipped_skills"].append("")
	if not player.has("tower_equipped_skills"):
		player["tower_equipped_skills"] = ["", "", "", ""]
	if not player.has("passive_skills"):
		player["passive_skills"] = player.get("traits", [])
	while player["passive_skills"].size() < 4:
		player["passive_skills"].append("")
	if player["passive_skills"].size() > 4:
		player["passive_skills"].resize(4)
	if not player.has("tower_passive_skills"):
		player["tower_passive_skills"] = []
	if not player.has("passive_skill_slots"):
		player["passive_skill_slots"] = 0
	if not player.has("unlocked_passive_skills"):
		player["unlocked_passive_skills"] = []
	if not player.has("permanent_equipment_upgrades"):
		player["permanent_equipment_upgrades"] = {}
	if not player.has("permanent_skill_upgrades"):
		player["permanent_skill_upgrades"] = {}
	player.erase("traits")
	if not player.has("innate_skills"):
		player["innate_skills"] = {
			"attack_1": "innate_attack_1",
			"defend": "innate_defend",
			"dodge": "innate_dodge"
		}
	if not player.has("equipment_attachments"):
		player["equipment_attachments"] = {}
	if not player.has("skill_attachments"):
		player["skill_attachments"] = {}
	player.erase("set_counts")
	player.erase("active_set_effects")
	if not player.has("statuses"):
		player["statuses"] = []
	equipment.normalize_equipment(player)
	var equipment_dict := _dictionary(player.get("equipment", {}))
	if player["equipment_ids"].is_empty() and not equipment_dict.is_empty():
		for item_id in equipment_dict.values():
			var item_id_text := String(item_id)
			if item_id_text != "" and not player["equipment_ids"].has(item_id_text):
				player["equipment_ids"].append(item_id_text)


func _class_data_for(class_id: String) -> Dictionary:
	return DataCatalog.CLASSES[DataCatalog.normalize_class_id(class_id)]


func _dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	return {}


func _equipped_item_ids(player: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var equipped: Dictionary = player.get("equipment", {})
	var tower_equipment: Dictionary = player.get("tower_equipment", {})
	var combined := equipped.duplicate()
	for slot in tower_equipment.keys():
		combined[slot] = tower_equipment[slot]
	for item_id in combined.values():
		result.append(String(item_id))
	return result


func _effective_equipped_skills(player: Dictionary) -> Array[String]:
	var skills: Array[String] = []
	for skill_id in player.get("equipped_skills", []):
		skills.append(String(skill_id))
	while skills.size() < 4:
		skills.append("")
	var tower_skills: Array = player.get("tower_equipped_skills", [])
	for index in range(mini(4, tower_skills.size())):
		if String(tower_skills[index]) != "":
			skills[index] = String(tower_skills[index])
	return skills


func _effective_passive_skills(player: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for passive_id in player.get("passive_skills", []):
		if String(passive_id) != "":
			result.append(String(passive_id))
	for passive_id in player.get("tower_passive_skills", []):
		if String(passive_id) != "":
			result.append(String(passive_id))
	return result
