extends RefCounted
class_name StoryCutsceneView


func render(root: Control, label_factory: Callable, text: String, continue_callback: Callable) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 1)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(bg)

	var button := Button.new()
	button.flat = true
	button.text = ""
	button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.pressed.connect(continue_callback)
	root.add_child(button)

	var outer := CenterContainer.new()
	outer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(outer)

	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(860, 0)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 14)
	outer.add_child(panel)

	panel.add_child(label_factory.call(text, 26))
	var hint: Label = label_factory.call("点击屏幕继续", 16)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(hint)

	button.move_to_front()
