extends RefCounted
class_name TitleMenuView


func render(
	root: Control,
	label_factory: Callable,
	start_callback: Callable,
	continue_callback: Callable,
	settings_callback: Callable,
	exit_callback: Callable,
	has_save: bool
) -> void:
	var outer := CenterContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(outer)

	var panel := VBoxContainer.new()
	panel.custom_minimum_size = Vector2(360, 0)
	panel.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_theme_constant_override("separation", 12)
	outer.add_child(panel)

	panel.add_child(label_factory.call("Super Tower", 34))
	panel.add_child(label_factory.call("开始游戏、继续游戏、设置、退出", 16))

	var start_button := Button.new()
	start_button.text = "开始游戏"
	start_button.custom_minimum_size = Vector2(260, 48)
	start_button.pressed.connect(start_callback)
	panel.add_child(start_button)

	var continue_button := Button.new()
	continue_button.text = "继续游戏"
	continue_button.custom_minimum_size = Vector2(260, 48)
	continue_button.pressed.connect(continue_callback)
	continue_button.disabled = not has_save
	panel.add_child(continue_button)

	var settings_button := Button.new()
	settings_button.text = "设置"
	settings_button.custom_minimum_size = Vector2(260, 48)
	settings_button.pressed.connect(settings_callback)
	panel.add_child(settings_button)

	var exit_button := Button.new()
	exit_button.text = "退出"
	exit_button.custom_minimum_size = Vector2(260, 48)
	exit_button.pressed.connect(exit_callback)
	panel.add_child(exit_button)
