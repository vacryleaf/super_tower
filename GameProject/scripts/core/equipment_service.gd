extends RefCounted
class_name EquipmentService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func equip_item(player: Dictionary, item_id: String) -> void:
	var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
	var slot := String(item["slot"])
	if slot == "ring" and player["equipment"].has("ring"):
		slot = "ring2"
	player["equipment"][slot] = item_id
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


func equipment_target_by_slot(player: Dictionary, slot: String) -> Dictionary:
	var equipment: Dictionary = player.get("equipment", {})
	if equipment.has(slot):
		return {"type": "equipment", "id": String(equipment[slot])}
	return {}