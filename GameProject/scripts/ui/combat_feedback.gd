extends RefCounted
class_name CombatFeedback

var scene: Node


func _init(p_scene: Node) -> void:
	scene = p_scene


func play_action_feedback(events: Array, enemy_card_nodes: Dictionary, player_status_node: Control, label_fn: Callable) -> void:
	if events.is_empty():
		await scene.get_tree().create_timer(0.15).timeout
		return
	for event in events:
		_play_single_event_feedback(event, enemy_card_nodes, player_status_node, label_fn)
		await scene.get_tree().create_timer(0.85).timeout


func _play_single_event_feedback(event: Dictionary, enemy_card_nodes: Dictionary, player_status_node: Control, label_fn: Callable) -> void:
	if event.get("target", "") == "enemy":
		var target_index := int(event.get("target_index", 0))
		var target_node: Variant = enemy_card_nodes.get(target_index, null)
		_shake_node(target_node)
		var enemy_prefix := "+" if event.get("kind", "") in ["defense", "dodge"] else "-"
		if int(event.get("amount", 0)) > 0:
			_float_number(target_node, "%s%d" % [enemy_prefix, int(event.get("amount", 0))], "center_bottom", label_fn)
	elif event.get("target", "") == "player":
		_shake_node(player_status_node)
		if int(event.get("amount", 0)) > 0:
			var prefix := "+" if event.get("kind", "") in ["defense", "heal", "dodge"] else "-"
			_float_number(player_status_node, "%s%d" % [prefix, int(event.get("amount", 0))], "center_top", label_fn)


func _shake_node(node: Variant) -> void:
	if node == null or not (node is Control):
		return
	var control: Control = node
	var origin := control.position
	var tween := scene.create_tween()
	tween.tween_property(control, "position", origin + Vector2(8, 0), 0.05)
	tween.tween_property(control, "position", origin + Vector2(-8, 0), 0.05)
	tween.tween_property(control, "position", origin + Vector2(4, 0), 0.05)
	tween.tween_property(control, "position", origin, 0.05)


func _float_number(node: Variant, text_value: String, placement: String, label_fn: Callable) -> void:
	if node == null or not (node is Control):
		return
	var control: Control = node
	var label: Label = label_fn.call(text_value, 22)
	label.custom_minimum_size = Vector2(120, 34)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(1, 0.25, 0.2, 1) if text_value.begins_with("-") else Color(0.35, 1.0, 0.55, 1)
	label.z_index = 100
	scene.add_child(label)
	label.global_position = _float_number_position(control, label.custom_minimum_size, placement)
	var tween := scene.create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -36), 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.finished.connect(_on_float_number_finished.bind(label))


func _on_float_number_finished(label: Variant) -> void:
	if is_instance_valid(label):
		label.queue_free()


func _float_number_position(control: Control, popup_size: Vector2, placement: String) -> Vector2:
	var x := control.global_position.x + (control.size.x - popup_size.x) * 0.5
	var y := control.global_position.y + (control.size.y - popup_size.y) * 0.5
	if placement == "center_bottom":
		y = control.global_position.y + control.size.y * 0.62
	elif placement == "center_top":
		y = control.global_position.y + control.size.y * 0.18
	return Vector2(x, y)