extends RefCounted
class_name RewardView


func render_reward(root: Control, reward_options: Array[Dictionary], pressed_callback: Callable, label_factory: Callable) -> void:
	var reward_area := CenterContainer.new()
	reward_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(reward_area)

	var options := VBoxContainer.new()
	options.custom_minimum_size = Vector2(300, 0)
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_area.add_child(options)
	var title: Label = label_factory.call("选择奖励", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options.add_child(title)
	for i in range(reward_options.size()):
		var reward: Dictionary = reward_options[i]
		var button := Button.new()
		button.text = String(reward["label"]).replace("塔内附着：", "")
		button.custom_minimum_size = Vector2(300, 48)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(pressed_callback.bind(i))
		options.add_child(button)


func render_reward_target(
	root: Control,
	message: String,
	reward_targets: Array[Dictionary],
	pressed_callback: Callable,
	label_factory: Callable,
	target_label: Callable,
	attachment_summary: Callable
) -> void:
	var target_area := CenterContainer.new()
	target_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(target_area)

	var options := VBoxContainer.new()
	options.custom_minimum_size = Vector2(320, 0)
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	target_area.add_child(options)
	var title: Label = label_factory.call("选择附着目标", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options.add_child(title)
	var subtitle: Label = label_factory.call(message, 15)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options.add_child(subtitle)
	for i in range(reward_targets.size()):
		var target: Dictionary = reward_targets[i]
		var button := Button.new()
		button.text = "%s\n%s" % [
			target_label.call(target),
			attachment_summary.call(String(target["type"]), String(target["id"]))
		]
		button.custom_minimum_size = Vector2(320, 58)
		button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(pressed_callback.bind(i))
		options.add_child(button)
