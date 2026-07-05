extends RefCounted
class_name RunHudView


func render(root: Control, session: Variant, input_locked: bool, end_run_callback: Callable, badge_factory: Callable, spacer_factory: Callable) -> void:
	var top := HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(badge_factory.call("第 %d 层" % session.floor_index, 22, Vector2(110, 42)))
	top.add_child(badge_factory.call("第 %d 场" % session.battle_index, 22, Vector2(110, 42)))
	top.add_child(spacer_factory.call())
	if ["battle", "reward", "reward_target"].has(session.phase):
		var end_run_button := Button.new()
		end_run_button.text = "结束爬塔"
		end_run_button.custom_minimum_size = Vector2(120, 42)
		end_run_button.disabled = input_locked
		end_run_button.pressed.connect(end_run_callback)
		top.add_child(end_run_button)
	root.add_child(top)
