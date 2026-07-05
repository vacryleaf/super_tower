extends RefCounted
class_name EndScreenView


func render(root: Control, title: String, subtitle: String, return_callback: Callable, label_factory: Callable) -> void:
	root.add_child(label_factory.call(title, 30))
	root.add_child(label_factory.call(subtitle, 18))
	var button := Button.new()
	button.text = "返回主菜单"
	button.custom_minimum_size = Vector2(132, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(return_callback)
	root.add_child(button)
