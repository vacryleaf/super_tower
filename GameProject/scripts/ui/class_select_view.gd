extends RefCounted
class_name ClassSelectView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const UIHelpers = preload("res://scripts/ui/ui_helpers.gd")

var selected_class := ""


func reset() -> void:
	selected_class = ""


func render(
	root: Control,
	label_factory: Callable,
	slot_index: int,
	select_callback: Callable,
	start_callback: Callable,
	back_callback: Callable
) -> void:
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 12)
	root.add_child(outer)

	outer.add_child(label_factory.call("选择职业", 30))
	outer.add_child(label_factory.call("当前槽位：%d" % slot_index, 16))

	var row := HBoxContainer.new()
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 14)
	outer.add_child(row)

	for class_key in DataCatalog.CLASSES.keys():
		row.add_child(_class_button(class_key, label_factory, select_callback))

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(spacer)

	var bottom := HBoxContainer.new()
	bottom.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom.add_theme_constant_override("separation", 10)
	outer.add_child(bottom)

	var back_button := Button.new()
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(160, 44)
	back_button.pressed.connect(back_callback)
	bottom.add_child(back_button)

	var start_button := Button.new()
	start_button.text = "开始教程"
	start_button.custom_minimum_size = Vector2(180, 44)
	start_button.disabled = selected_class == ""
	start_button.pressed.connect(func():
		if selected_class != "":
			start_callback.call(selected_class)
	)
	bottom.add_child(start_button)


func _class_button(class_key: String, label_factory: Callable, select_callback: Callable) -> Control:
	var captured_class_key := class_key
	var data: Dictionary = DataCatalog.CLASSES[class_key]
	var button := Button.new()
	button.text = ""
	button.custom_minimum_size = Vector2(240, 220)
	button.pressed.connect(func():
		selected_class = captured_class_key
		select_callback.call(captured_class_key)
	)

	var inner := VBoxContainer.new()
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("separation", 4)
	button.add_child(inner)
	inner.add_child(UIHelpers.avatar_for(class_key))
	inner.add_child(label_factory.call(String(data["name"]), 22))
	inner.add_child(label_factory.call("生命 %d" % int(data["max_hp"]), 16))
	inner.add_child(label_factory.call("攻击 %d  护甲 %d  格挡 %d" % [
		int(data["base_attack"]), int(data["base_defense"]), int(data.get("base_block", 1))
	], 14))
	if selected_class == captured_class_key:
		button.add_theme_color_override("font_color", Color(1, 0.95, 0.5))
	return button
