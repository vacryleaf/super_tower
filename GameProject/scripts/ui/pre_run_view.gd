extends RefCounted
class_name PreRunView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

var step := 0
var selected_class := ""
var start_floor := 0


func render(root: Control, session: Variant, label_factory: Callable, action_callback: Callable, close_callback: Callable) -> void:
	match step:
		0:
			_render_class_select(root, session, label_factory, action_callback, close_callback)
		1:
			_render_confirm_loadout(root, session, label_factory, action_callback, close_callback)
		2:
			_render_item_select(root, label_factory, action_callback, close_callback)
		3:
			_render_floor_select(root, session, label_factory, action_callback, close_callback)
		4:
			_render_confirm(root, session, label_factory, action_callback, close_callback)


func reset() -> void:
	step = 0
	selected_class = ""
	start_floor = 0


func _render_class_select(root: Control, session: Variant, label_factory: Callable, action_callback: Callable, close_callback: Callable) -> void:
	root.add_child(label_factory.call("爬塔准备 — 选择职业", 28))

	for class_key in DataCatalog.CLASSES.keys():
		var data: Dictionary = DataCatalog.CLASSES[class_key]
		var roster_player: Dictionary = session.get_roster_player(class_key) if is_instance_valid(session) else {}
		var button := Button.new()
		var text := "%s（HP %d  攻击 %d  护甲 %d）" % [data["name"], int(data["max_hp"]), int(data["base_attack"]), int(data["base_defense"])]
		if roster_player.is_empty():
			text += " — 未招募"
		else:
			var highest := int(roster_player.get("highest_floor", 0))
			if highest > 0:
				text += " — 最高第 %d 层" % highest
		button.text = text
		button.custom_minimum_size = Vector2(400, 50)
		button.pressed.connect(func(): action_callback.call("select_class", class_key))
		root.add_child(button)

	var back_button := Button.new()
	back_button.text = "返回营地"
	back_button.custom_minimum_size = Vector2(160, 44)
	back_button.pressed.connect(close_callback)
	root.add_child(back_button)


func _render_confirm_loadout(root: Control, session: Variant, label_factory: Callable, action_callback: Callable, close_callback: Callable) -> void:
	var class_name := String(DataCatalog.CLASSES[selected_class]["name"])
	root.add_child(label_factory.call("爬塔准备 — %s — 确认装备与技能" % class_name, 24))

	var roster_player: Dictionary = session.get_roster_player(selected_class)

	root.add_child(label_factory.call("已装备技能：", 18))
	var equipped_skills: Array = roster_player.get("equipped_skills", [])
	if equipped_skills.is_empty():
		root.add_child(label_factory.call("  未装备任何技能", 14))
	else:
		for skill_id in equipped_skills:
			if DataCatalog.SKILLS.has(skill_id):
				root.add_child(label_factory.call("  %s" % DataCatalog.SKILLS[skill_id]["name"], 15))

	root.add_child(label_factory.call("已装备物品：", 18))
	var equipment: Dictionary = roster_player.get("equipment", {})
	if equipment.is_empty():
		root.add_child(label_factory.call("  未装备任何物品", 14))
	else:
		for slot in equipment.keys():
			var item_id := String(equipment[slot])
			if DataCatalog.EQUIPMENT.has(item_id):
				root.add_child(label_factory.call("  %s：%s" % [_slot_label(slot), DataCatalog.EQUIPMENT[item_id]["name"]], 15))

	var hint := label_factory.call("如需修改，请返回营地后进入职业详情页调整。", 13)
	hint.modulate = Color(0.6, 0.6, 0.6)
	root.add_child(hint)

	var button_row := HBoxContainer.new()
	button_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	root.add_child(button_row)

	var back_button := Button.new()
	back_button.text = "上一步"
	back_button.custom_minimum_size = Vector2(120, 44)
	back_button.pressed.connect(func(): action_callback.call("prev_step", ""))
	button_row.add_child(back_button)

	var next_button := Button.new()
	next_button.text = "下一步"
	next_button.custom_minimum_size = Vector2(120, 44)
	next_button.pressed.connect(func(): action_callback.call("next_step", ""))
	button_row.add_child(next_button)


func _render_item_select(root: Control, label_factory: Callable, action_callback: Callable, close_callback: Callable) -> void:
	root.add_child(label_factory.call("爬塔准备 — 选择物品", 24))
	root.add_child(label_factory.call("选择需要带入塔内的消耗品。", 16))

	var hint := label_factory.call("暂无可用消耗品（此功能将在后续版本开放）。", 14)
	hint.modulate = Color(0.6, 0.6, 0.6)
	root.add_child(hint)

	var button_row := HBoxContainer.new()
	button_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	root.add_child(button_row)

	var back_button := Button.new()
	back_button.text = "上一步"
	back_button.custom_minimum_size = Vector2(120, 44)
	back_button.pressed.connect(func(): action_callback.call("prev_step", ""))
	button_row.add_child(back_button)

	var next_button := Button.new()
	next_button.text = "下一步"
	next_button.custom_minimum_size = Vector2(120, 44)
	next_button.pressed.connect(func(): action_callback.call("next_step", ""))
	button_row.add_child(next_button)


func _render_floor_select(root: Control, session: Variant, label_factory: Callable, action_callback: Callable, close_callback: Callable) -> void:
	root.add_child(label_factory.call("爬塔准备 — 选择起始楼层", 24))

	var roster_player: Dictionary = session.get_roster_player(selected_class)
	var highest_floor := int(roster_player.get("highest_floor", 0))
	var max_skip_floor := highest_floor - 4

	if max_skip_floor < 2 or not roster_player.get("tutorial_completed", false):
		root.add_child(label_factory.call("最高记录第 %d 层，无法跳关。将从第 1 层开始。" % highest_floor, 16))
		start_floor = 0
	else:
		root.add_child(label_factory.call("最高记录：第 %d 层，可跳关至 2-%d 层。" % [highest_floor, max_skip_floor], 16))
		var floor_selector := OptionButton.new()
		floor_selector.custom_minimum_size = Vector2(150, 34)
		floor_selector.add_item("从第 1 层开始", 0)
		for f in range(2, max_skip_floor + 1):
			floor_selector.add_item("从第 %d 层开始" % f, f)
		floor_selector.selected = 0
		floor_selector.item_selected.connect(func(index: int): start_floor = floor_selector.get_item_id(index))
		root.add_child(floor_selector)

	var button_row := HBoxContainer.new()
	button_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	root.add_child(button_row)

	var back_button := Button.new()
	back_button.text = "上一步"
	back_button.custom_minimum_size = Vector2(120, 44)
	back_button.pressed.connect(func(): action_callback.call("prev_step", ""))
	button_row.add_child(back_button)

	var next_button := Button.new()
	next_button.text = "下一步"
	next_button.custom_minimum_size = Vector2(120, 44)
	next_button.pressed.connect(func(): action_callback.call("next_step", ""))
	button_row.add_child(next_button)


func _render_confirm(root: Control, session: Variant, label_factory: Callable, action_callback: Callable, close_callback: Callable) -> void:
	root.add_child(label_factory.call("爬塔准备 — 确认出发", 24))

	var class_name := String(DataCatalog.CLASSES[selected_class]["name"])
	root.add_child(label_factory.call("职业：%s" % class_name, 18))

	if start_floor >= 2:
		root.add_child(label_factory.call("起始楼层：第 %d 层" % start_floor, 18))
	else:
		root.add_child(label_factory.call("起始楼层：第 1 层", 18))

	var button_row := HBoxContainer.new()
	button_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	root.add_child(button_row)

	var back_button := Button.new()
	back_button.text = "上一步"
	back_button.custom_minimum_size = Vector2(120, 44)
	back_button.pressed.connect(func(): action_callback.call("prev_step", ""))
	button_row.add_child(back_button)

	var start_button := Button.new()
	start_button.text = "出发！"
	start_button.custom_minimum_size = Vector2(160, 50)
	start_button.pressed.connect(func(): action_callback.call("start_game", ""))
	button_row.add_child(start_button)


func _slot_label(slot: String) -> String:
	var labels := {
		"head": "头部", "body": "上身", "waist": "腰部", "legs": "腿部",
		"hands": "手套", "leggings": "护腿", "feet": "鞋子", "weapon": "武器",
		"offhand": "副手", "shoulders": "肩部", "cloak": "披风", "necklace": "项链",
		"ring": "戒指1", "ring2": "戒指2"
	}
	return labels.get(slot, slot)