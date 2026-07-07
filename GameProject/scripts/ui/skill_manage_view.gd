extends RefCounted
class_name SkillManageView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func render(root: Control, class_key: String, roster_player: Dictionary, label_factory: Callable, action_callback: Callable, close_callback: Callable) -> void:
	var class_name := String(DataCatalog.CLASSES[class_key]["name"])
	root.add_child(label_factory.call("%s - 技能管理" % class_name, 28))

	var unlocked: Array = roster_player.get("unlocked_skills", [])
	var equipped: Array = roster_player.get("equipped_skills", [])

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	content.add_child(label_factory.call("已装备技能槽：%d/4" % equipped.size(), 16))

	for skill_id in _class_skills(class_key):
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		var is_unlocked := unlocked.has(skill_id)
		var is_equipped := equipped.has(skill_id)

		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

		var label_text := skill["name"]
		if is_equipped:
			label_text += "（已装备）"
		elif not is_unlocked:
			label_text += "（未解锁）"

		var label := label_factory.call(label_text, 16)
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
				if equipped.size() >= 4:
					button.disabled = true
					button.text = "槽位已满"
			button.custom_minimum_size = Vector2(80, 34)
			button.pressed.connect(func(): action_callback.call(class_key, skill_id))
			row.add_child(button)

		content.add_child(row)

	var close_button := Button.new()
	close_button.text = "返回营地"
	close_button.custom_minimum_size = Vector2(160, 44)
	close_button.pressed.connect(close_callback)
	root.add_child(close_button)


func _class_skills(class_key: String) -> Array[String]:
	var result: Array[String] = []
	for skill_id in DataCatalog.SKILLS.keys():
		var skill_class := String(DataCatalog.SKILLS[skill_id].get("class", ""))
		if skill_class == class_key or skill_class == "common":
			result.append(String(skill_id))
	return result