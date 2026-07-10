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
		if skill.get("class", "") == class_id and not player["unlocked_skills"].has(skill_id):
			unlock_skill(player, skill_id, _has_empty_skill_slot(player))
			return


func _has_empty_skill_slot(player: Dictionary) -> bool:
	for skill_id in player["equipped_skills"]:
		if String(skill_id) == "":
			return true
	return false


func equipment_target_by_slot(player: Dictionary, slot: String) -> Dictionary:
	var equipment: Dictionary = player.get("equipment", {})
	if equipment.has(slot):
		return {"type": "equipment", "id": String(equipment[slot])}
	return {}