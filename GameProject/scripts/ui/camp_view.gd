extends RefCounted
class_name CampView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func render(
	root: Control,
	session: Variant,
	label_factory: Callable,
	continue_callback: Callable,
	dispatch_callback: Callable
) -> void:
	root.add_child(label_factory.call("塔下营地", 30))
	root.add_child(label_factory.call("可玩版本：新手引导、手动战斗、奖励选择、装备、技能和 1-10 层流程。", 16))
	if session.has_active_run():
		var continue_button := Button.new()
		continue_button.text = "继续当前派遣"
		continue_button.custom_minimum_size = Vector2(190, 46)
		continue_button.pressed.connect(continue_callback)
		root.add_child(continue_button)
	var class_row := HBoxContainer.new()
	class_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(class_row)
	class_row.add_child(_class_panel(session, "warrior", label_factory, dispatch_callback))
	class_row.add_child(_class_panel(session, "archer", label_factory, dispatch_callback))


func _class_panel(session: Variant, class_key: String, label_factory: Callable, dispatch_callback: Callable) -> Control:
	var data: Dictionary = DataCatalog.CLASSES[class_key]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(330, 210)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var box := VBoxContainer.new()
	box.add_child(label_factory.call(String(data["name"]), 24))
	box.add_child(label_factory.call("生命%d 攻击%d 护甲%d 格挡%d" % [
		int(data["max_hp"]),
		int(data["base_attack"]),
		int(data["base_defense"]),
		int(data.get("base_block", 1))
	], 16))
	box.add_child(label_factory.call("第一个技能：%s" % DataCatalog.SKILLS[data["first_skill"]]["name"], 16))
	var roster_player: Dictionary = session.get_roster_player(class_key)
	if roster_player.is_empty():
		box.add_child(label_factory.call("队伍状态：未招募", 14))
	else:
		box.add_child(label_factory.call("队伍状态：装备 %d  技能 %d" % [
			roster_player.get("equipment_ids", []).size(),
			roster_player.get("unlocked_skills", []).size()
		], 14))

	var highest_floor := int(roster_player.get("highest_floor", 0))
	var max_skip_floor := highest_floor - 4
	var floor_selector: OptionButton = null
	if max_skip_floor >= 2:
		box.add_child(label_factory.call("最高记录：第 %d 层" % highest_floor, 14))
		var selector_row := HBoxContainer.new()
		selector_row.add_child(label_factory.call("跳关至：", 14))
		floor_selector = OptionButton.new()
		floor_selector.custom_minimum_size = Vector2(110, 34)
		for f in range(2, max_skip_floor + 1):
			floor_selector.add_item("第 %d 层" % f, f)
		floor_selector.selected = max_skip_floor - 2
		selector_row.add_child(floor_selector)
		box.add_child(selector_row)

	var button := Button.new()
	button.text = "派遣：%s" % data["name"]
	button.custom_minimum_size = Vector2(160, 44)
	if floor_selector:
		button.pressed.connect(func(): dispatch_callback.call(class_key, int(floor_selector.get_selected_id())))
	else:
		button.pressed.connect(dispatch_callback.bind(class_key, 0))
	box.add_child(button)
	panel.add_child(box)
	return panel
