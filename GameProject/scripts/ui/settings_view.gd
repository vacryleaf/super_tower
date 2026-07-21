extends RefCounted
class_name SettingsView


func render(root: Control, label_factory: Callable, select_callback: Callable, back_callback: Callable, current_resolution: Vector2i) -> void:
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_theme_constant_override("separation", 10)
	root.add_child(outer)

	outer.add_child(label_factory.call("设置", 30))
	outer.add_child(label_factory.call("分辨率", 18))
	outer.add_child(label_factory.call("当前：%d x %d" % [current_resolution.x, current_resolution.y], 16))

	for resolution in [Vector2i(1980, 1080), Vector2i(1280, 720)]:
		var captured_resolution: Vector2i = resolution
		var button := Button.new()
		button.text = "%d x %d" % [captured_resolution.x, captured_resolution.y]
		button.custom_minimum_size = Vector2(220, 44)
		button.pressed.connect(func(): select_callback.call(captured_resolution))
		outer.add_child(button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(spacer)

	var back_button := Button.new()
	back_button.text = "返回"
	back_button.custom_minimum_size = Vector2(160, 44)
	back_button.pressed.connect(back_callback)
	outer.add_child(back_button)
