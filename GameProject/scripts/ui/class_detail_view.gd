extends RefCounted
class_name ClassDetailView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func render(root: Control, class_key: String, roster_player: Dictionary, label_factory: Callable, manage_callback: Callable, close_callback: Callable) -> void:
	var data: Dictionary = DataCatalog.CLASSES[class_key]
	root.add_child(label_factory.call(String(data["name"]), 30))
	root.add_child(_avatar_for(class_key))

	root.add_child(label_factory.call("生命%d  攻击%d  护甲%d  格挡%d" % [
		int(data["max_hp"]), int(data["base_attack"]), int(data["base_defense"]), int(data.get("base_block", 1))
	], 18))

	if roster_player.is_empty():
		root.add_child(label_factory.call("该职业尚未招募。", 16))
		var back_button := Button.new()
		back_button.text = "返回"
		back_button.custom_minimum_size = Vector2(160, 44)
		back_button.pressed.connect(close_callback)
		root.add_child(back_button)
		return

	var highest_floor := int(roster_player.get("highest_floor", 0))
	root.add_child(label_factory.call("最高记录：第 %d 层" % highest_floor, 16))

	_render_skill_summary(root, roster_player, label_factory)
	_render_equipment_summary(root, roster_player, label_factory)

	root.add_child(label_factory.call("", 10))

	var mgmt_row := HBoxContainer.new()
	mgmt_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for action in [["技能管理", "skill_manage"], ["装备管理", "equipment_manage"], ["物品查看", "item_collection"]]:
		var btn := Button.new()
		btn.text = action[0]
		btn.custom_minimum_size = Vector2(100, 40)
		btn.pressed.connect(func(): manage_callback.call(action[1], class_key))
		mgmt_row.add_child(btn)
	root.add_child(mgmt_row)

	var back_button := Button.new()
	back_button.text = "返回营地"
	back_button.custom_minimum_size = Vector2(160, 44)
	back_button.pressed.connect(close_callback)
	root.add_child(back_button)


func _avatar_for(class_key: String) -> TextureRect:
	var path := "res://img/warrior.png" if class_key == "warrior" else "res://img/archer.png"
	var avatar := TextureRect.new()
	avatar.texture = load(path)
	avatar.custom_minimum_size = Vector2(64, 64)
	avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return avatar


func _render_skill_summary(parent: Control, roster_player: Dictionary, label_factory: Callable) -> void:
	var equipped: Array = roster_player.get("equipped_skills", [])
	var unlocked: Array = roster_player.get("unlocked_skills", [])
	parent.add_child(label_factory.call("已装备技能：%d/4" % equipped.size(), 18))
	if equipped.is_empty():
		parent.add_child(label_factory.call("  未装备任何技能", 14))
	else:
		for skill_id in equipped:
			if DataCatalog.SKILLS.has(skill_id):
				var skill: Dictionary = DataCatalog.SKILLS[skill_id]
				parent.add_child(label_factory.call("  %s" % skill["name"], 15))
	parent.add_child(label_factory.call("已解锁技能：%d 个" % unlocked.size(), 14))


func _render_equipment_summary(parent: Control, roster_player: Dictionary, label_factory: Callable) -> void:
	var equipment: Dictionary = roster_player.get("equipment", {})
	var equipment_ids: Array = roster_player.get("equipment_ids", [])
	parent.add_child(label_factory.call("已装备：%d 件 / 已收集：%d 件" % [equipment.size(), equipment_ids.size()], 18))