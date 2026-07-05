extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	main.session.delete_save()
	_press_button(main, "派遣：战士")
	await process_frame
	_assert_enemy_tooltip(main)
	_press_button(main, "普通攻击")
	await _wait_seconds(1.1)
	_press_button(main, "普通攻击")
	await _wait_seconds(1.1)
	main.session.delete_save()
	if failures.is_empty():
		print("UI CLICK SMOKE TEST PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _press_button(node: Node, text_value: String) -> void:
	var button := _find_button(node, text_value)
	if button == null:
		failures.append("missing button: %s" % text_value)
		return
	button.pressed.emit()


func _find_button(node: Node, text_value: String) -> Button:
	if node is Button and String(node.text) == text_value:
		return node
	for child in node.get_children():
		var found := _find_button(child, text_value)
		if found != null:
			return found
	return null


func _assert_enemy_tooltip(node: Node) -> void:
	var enemy_button := _find_button_containing(node, "特性：")
	if enemy_button == null:
		failures.append("missing enemy card with traits")
		return
	if String(enemy_button.tooltip_text).is_empty():
		failures.append("enemy traits tooltip should not be empty")


func _find_button_containing(node: Node, text_value: String) -> Button:
	if node is Button and String(node.text).contains(text_value):
		return node
	for child in node.get_children():
		var found := _find_button_containing(child, text_value)
		if found != null:
			return found
	return null


func _wait_seconds(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = seconds
	root.add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()
