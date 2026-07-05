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
		continue_button.custom_minimum_size = Vector2(220, 56)
		continue_button.pressed.connect(continue_callback)
		root.add_child(continue_button)
	var class_row := HBoxContainer.new()
	class_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(class_row)
	class_row.add_child(_class_panel(session, "warrior", label_factory, dispatch_callback))
	class_row.add_child(_class_panel(session, "archer", label_factory, dispatch_callback))


func _class_panel(session: Variant, class_key: String, label_factory: Callable, dispatch_callback: Callable) -> Control:
	var data: Dictionary = DataCatalog.CLASSES[class_key]
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_child(label_factory.call(String(data["name"]), 24))
	box.add_child(label_factory.call("生命 %d  攻击 %d  护甲 %d  格挡 %d" % [
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
	var button := Button.new()
	button.text = "派遣：%s" % data["name"]
	button.custom_minimum_size = Vector2(180, 56)
	button.pressed.connect(dispatch_callback.bind(class_key))
	box.add_child(button)
	panel.add_child(box)
	return panel
