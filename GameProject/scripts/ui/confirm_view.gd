extends RefCounted
class_name ConfirmView


func render(root: Control, label_factory: Callable, title: String, message: String, confirm_callback: Callable, cancel_callback: Callable) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.65)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(overlay)

	var outer := CenterContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(outer)

	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	panel.add_theme_constant_override("separation", 12)
	outer.add_child(panel)

	panel.add_child(label_factory.call(title, 28))
	panel.add_child(label_factory.call(message, 18))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	panel.add_child(row)

	var confirm_button := Button.new()
	confirm_button.text = "覆盖"
	confirm_button.custom_minimum_size = Vector2(150, 44)
	confirm_button.pressed.connect(confirm_callback)
	row.add_child(confirm_button)

	var cancel_button := Button.new()
	cancel_button.text = "取消"
	cancel_button.custom_minimum_size = Vector2(150, 44)
	cancel_button.pressed.connect(cancel_callback)
	row.add_child(cancel_button)
