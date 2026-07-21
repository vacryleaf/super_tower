extends SceneTree

var failures: Array[String] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var main := scene.instantiate()
	root.add_child(main)
	await _wait_for_render()
	main.session.delete_save()
	await _wait_for_render()

	_press_button(main, "开始游戏")
	await _wait_for_render()
	_press_button_containing(main, "槽位 1")
	await _wait_for_render()
	_assert_label_exists(main, "选择职业")
	_press_button_with_child_label(main, "战士")
	await _wait_for_animation()
	_assert_button_exists(main, "开始教程")
	_press_button(main, "开始教程")
	await _wait_for_render()
	main.session.end_run_to_camp()
	main._request_menu_render()
	await _wait_for_render()
	_assert_label_exists(main, "营地")
	_press_button(main, "爬塔")
	await _wait_for_render()
	_assert_label_exists(main, "准备")
	_assert_label_missing(main, "职业卡片")
	_assert_label_missing(main, "装备栏")
	_assert_label_missing(main, "技能栏")
	_assert_label_missing(main, "消耗品栏")
	_assert_label_missing(main, "仓库")

	_press_button_with_child_label(main, "战士")
	await _wait_for_animation()
	_assert_class_card_shape(main)
	_assert_equipment_slots_are_square(main)
	_assert_skill_slots_visible(main)
	_assert_button_containing(main, "层数")
	_assert_button_exists(main, "出发")
	_press_button(main, "攻")
	await _wait_for_render()
	_assert_button_exists(root, "普通攻击")
	_press_button(main, "1")
	await _wait_for_render()
	_assert_button_exists(root, "???")

	_press_button_containing(main, "层数")
	await _wait_for_render()
	_assert_button_exists(main, "MAX")

	_press_button(main, "出发")
	await _wait_for_render()
	_assert_phase(main, "battle")

	main.session.delete_save()
	if failures.is_empty():
		print("PRE RUN UI SMOKE TEST PASSED")
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


func _press_button_containing(node: Node, text_value: String) -> void:
	var button := _find_button_containing(node, text_value)
	if button == null:
		failures.append("missing button containing: %s" % text_value)
		return
	button.pressed.emit()


func _press_button_with_child_label(node: Node, label_text: String) -> void:
	var button := _find_button_with_child_label(node, label_text)
	if button == null:
		failures.append("missing card button with label: %s" % label_text)
		return
	button.pressed.emit()


func _assert_button_exists(node: Node, text_value: String) -> void:
	if _find_button(node, text_value) == null:
		failures.append("missing button: %s" % text_value)


func _assert_button_containing(node: Node, text_value: String) -> void:
	if _find_button_containing(node, text_value) == null:
		failures.append("missing button containing: %s" % text_value)


func _assert_label_exists(node: Node, text_value: String) -> void:
	if _find_label_containing(node, text_value) == null:
		failures.append("missing label containing: %s" % text_value)


func _assert_label_missing(node: Node, text_value: String) -> void:
	if _find_label_containing(node, text_value) != null:
		failures.append("unexpected label before class selection: %s" % text_value)


func _assert_phase(main: Node, phase: String) -> void:
	if String(main.session.phase) != phase:
		failures.append("expected phase %s, got %s" % [phase, String(main.session.phase)])


func _find_button(node: Node, text_value: String) -> Button:
	if node is Button and String(node.text) == text_value:
		return node
	for child in node.get_children():
		var found := _find_button(child, text_value)
		if found != null:
			return found
	return null


func _find_button_containing(node: Node, text_value: String) -> Button:
	if node is Button and String(node.text).contains(text_value):
		return node
	for child in node.get_children():
		var found := _find_button_containing(child, text_value)
		if found != null:
			return found
	return null


func _find_button_with_child_label(node: Node, label_text: String) -> Button:
	if node is Button and _node_has_label(node, label_text):
		return node
	for child in node.get_children():
		var found := _find_button_with_child_label(child, label_text)
		if found != null:
			return found
	return null


func _node_has_label(node: Node, label_text: String) -> bool:
	if node is Label and String(node.text).contains(label_text):
		return true
	for child in node.get_children():
		if _node_has_label(child, label_text):
			return true
	return false


func _find_label_containing(node: Node, text_value: String) -> Label:
	if node is Label and String(node.text).contains(text_value):
		return node
	for child in node.get_children():
		var found := _find_label_containing(child, text_value)
		if found != null:
			return found
	return null


func _wait_for_render() -> void:
	await process_frame
	await process_frame


func _wait_for_animation() -> void:
	await create_timer(0.35).timeout
	await _wait_for_render()


func _assert_class_card_shape(node: Node) -> void:
	var button := _find_button_with_child_label(node, "战士")
	if button == null:
		failures.append("missing selected class card")
		return
	var ratio := button.custom_minimum_size.x / button.custom_minimum_size.y
	var expected_ratio := 150.0 / 210.0
	if absf(ratio - expected_ratio) > 0.01:
		failures.append("class card should keep poker-like ratio")


func _assert_equipment_slots_are_square(node: Node) -> void:
	var button := _find_button_containing(node, "训练铁盔")
	if button == null:
		button = _find_button(node, "头部")
	if button == null:
		failures.append("missing head equipment slot")
		return
	if absf(button.custom_minimum_size.x - button.custom_minimum_size.y) > 0.1:
		failures.append("equipment slots should be square")


func _assert_skill_slots_visible(node: Node) -> void:
	for text_value in ["攻", "防", "躲", "1", "2", "3", "4"]:
		if _find_button(node, text_value) == null:
			failures.append("missing skill slot: %s" % text_value)
