extends RefCounted
class_name SkillManageView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

const SLOT_LABELS := ["技能一（低耗伤害）", "技能二（高耗爆发）", "技能三（中耗效果）", "技能四（冷却技能）"]


func render(root: Control, class_key: String, roster_player: Dictionary, label_factory: Callable, action_callback: Callable, close_callback: Callable) -> void:
	var cls_name := String(DataCatalog.CLASSES.get(class_key, {"name": "角色"}).get("name", "角色"))
	root.add_child(label_factory.call("%s - 技能管理" % cls_name, 28))

	var unlocked: Array = roster_player.get("unlocked_skills", [])
	var equipped: Array = roster_player.get("equipped_skills", [])
	while equipped.size() < 4:
		equipped.append("")

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	var skills_by_slot: Dictionary = _skills_by_slot(class_key)

	for slot in range(1, 5):
		var slot_skills: Array = skills_by_slot.get(slot, [])
		if slot_skills.is_empty():
			continue

		var section := VBoxContainer.new()
		content.add_child(section)

		var current_equipped := String(equipped[slot - 1])
		var header_text: String = SLOT_LABELS[slot - 1]
		if current_equipped != "" and DataCatalog.SKILLS.has(current_equipped):
			header_text += "  — 已装备：%s" % DataCatalog.SKILLS[current_equipped]["name"]
		section.add_child(label_factory.call(header_text, 16))

		for skill_id in slot_skills:
			var skill: Dictionary = DataCatalog.SKILLS[skill_id]
			var is_unlocked: bool = unlocked.has(skill_id)
			var is_equipped: bool = current_equipped == skill_id

			var row := HBoxContainer.new()
			row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

			var label_text: String = "  " + String(skill["name"])
			if not is_unlocked:
				label_text += "（未解锁）"

			var label: Label = label_factory.call(label_text, 15)
			if not is_unlocked:
				label.modulate = Color(0.4, 0.4, 0.4)
			elif is_equipped:
				label.modulate = Color(0.3, 0.8, 0.3)
			row.add_child(label)

			if is_unlocked:
				var button := Button.new()
				if is_equipped:
					button.text = "卸下"
				else:
					button.text = "装备"
				button.custom_minimum_size = Vector2(80, 34)
				button.pressed.connect(func(): action_callback.call(class_key, slot, skill_id))
				row.add_child(button)

			section.add_child(row)

	var close_button := Button.new()
	close_button.text = "返回营地"
	close_button.custom_minimum_size = Vector2(160, 44)
	close_button.pressed.connect(close_callback)
	root.add_child(close_button)


func _skills_by_slot(class_key: String) -> Dictionary:
	var result: Dictionary = {}
	for skill_id in DataCatalog.SKILLS.keys():
		var skill_class := String(DataCatalog.SKILLS[skill_id].get("class", ""))
		if skill_class != class_key and skill_class != "common":
			continue
		var slot := int(DataCatalog.SKILLS[skill_id].get("slot", 0))
		if slot < 1 or slot > 4:
			continue
		if not result.has(slot):
			result[slot] = []
		result[slot].append(String(skill_id))
	return result
