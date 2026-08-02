extends RefCounted
class_name EquipmentService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func equip_item(player: Dictionary, item_id: String) -> void:
	if not DataCatalog.EQUIPMENT.has(item_id):
		return
	var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
	var slot := DataCatalog.equipment_slot(item)
	if slot == "":
		return
	if not player.has("equipment"):
		player["equipment"] = {}
	var equipment: Dictionary = player["equipment"]
	for equipped_slot in equipment.keys():
		if String(equipment[equipped_slot]) == item_id and String(equipped_slot) != slot:
			equipment.erase(equipped_slot)
	player["equipment"][slot] = item_id
	if not player.has("equipment_ids"):
		player["equipment_ids"] = []
	if not player["equipment_ids"].has(item_id):
		player["equipment_ids"].append(item_id)


func normalize_equipment(player: Dictionary) -> void:
	var source: Dictionary = player.get("equipment", {})
	var normalized: Dictionary = {}
	for raw_slot in source.keys():
		var item_id := String(source[raw_slot])
		if item_id == "" or not DataCatalog.EQUIPMENT.has(item_id):
			continue
		var slot := DataCatalog.equipment_slot(String(raw_slot))
		if slot == "":
			var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
			slot = DataCatalog.equipment_slot(item)
		if slot == "":
			continue
		if not normalized.has(slot) or String(raw_slot) == slot:
			normalized[slot] = item_id
	player["equipment"] = normalized


func unlock_skill(player: Dictionary, skill_id: String, equip_now: bool) -> void:
	if not player["unlocked_skills"].has(skill_id):
		player["unlocked_skills"].append(skill_id)
	if equip_now:
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		var slot := int(skill.get("slot", 0))
		if slot >= 1 and slot <= 4:
			while player["equipped_skills"].size() < 4:
				player["equipped_skills"].append("")
			player["equipped_skills"][slot - 1] = skill_id


func unlock_next_skill(player: Dictionary) -> void:
	var class_id: String = player["class_id"]
	for skill_id in DataCatalog.SKILLS.keys():
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		if DataCatalog.skill_class_compatible(skill, class_id) and not player["unlocked_skills"].has(skill_id):
			unlock_skill(player, skill_id, _has_empty_skill_slot(player))
			return


func _has_empty_skill_slot(player: Dictionary) -> bool:
	for skill_id in player["equipped_skills"]:
		if String(skill_id) == "":
			return true
	return false


func equipment_target_by_slot(player: Dictionary, slot: String) -> Dictionary:
	var equipment: Dictionary = player.get("equipment", {})
	var normalized_slot := DataCatalog.equipment_slot(slot)
	if equipment.has(normalized_slot):
		return {"type": "equipment", "id": String(equipment[normalized_slot])}
	return {}