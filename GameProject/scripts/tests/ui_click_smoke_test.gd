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
	_press_button_with_label_descendant(main, "战士")
	await _wait_seconds(0.3)
	_assert_button_exists(main, "开始教程")
	_press_button(main, "开始教程")
	await _wait_for_render()
	_assert_phase(main, "battle")
	_assert_button_exists(main, "装备")
	_assert_button_exists(main, "攻击")
	_assert_button_exists(main, "防御")
	_assert_button_exists(main, "闪避")
	_assert_button_exists(main, "结束回合")
	_assert_button_exists(main, "结束爬塔")
	_assert_enemy_tooltip(main)

	_press_button(main, "装备")
	await _wait_for_render()
	_assert_button_exists(main, "关闭")
	_press_button(main, "关闭")
	await _wait_for_render()

	_press_button(main, "防御")
	await _wait_seconds(1.1)
	_press_button(main, "结束回合")
	await _wait_seconds(1.1)
	_assert_phase(main, "battle")

	_press_button(main, "闪避")
	await _wait_seconds(1.1)
	_press_button(main, "结束回合")
	await _wait_seconds(1.1)
	_assert_phase(main, "battle")

	_force_first_enemy_to_low_hp(main)
	_press_button(main, "攻击")
	await _wait_seconds(1.1)
	_assert_phase(main, "reward")
	_assert_label_exists(main, "选择奖励")
	_press_button_containing(main, "解锁")
	await _wait_for_render()
	_assert_phase(main, "battle")
	if main.session.player.get("equipment_ids", []).is_empty():
		main.session.simulator.equip_item(main.session.player, "warrior_training_sword")
		main.session.simulator._recalculate_player_stats(main.session.player, false)

	main.session.phase = "reward"
	main.session.reward_options.clear()
	main.session.reward_options.append({"kind": "attack", "label": "攻击 +3", "value": 3})
	main.session.reward_options.append({"kind": "hp", "label": "生命上限 +6", "value": 6})
	main._request_game_render()
	await _wait_for_render()
	_press_button_containing(main, "攻击 +3")
	await _wait_for_render()
	_assert_phase(main, "reward_target")
	_assert_label_exists(main, "选择附着目标")
	_press_any_reward_target(main)
	await _wait_for_render()
	_assert_phase(main, "battle")

	_press_button(main, "结束爬塔")
	await _wait_for_render()
	_assert_phase(main, "menu")
	_assert_label_exists(main, "营地")

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
	if button.disabled:
		failures.append("button is disabled: %s" % text_value)
		return
	button.pressed.emit()


func _press_button_containing(node: Node, text_value: String) -> void:
	var button := _find_button_containing(node, text_value)
	if button == null:
		failures.append("missing button containing: %s" % text_value)
		return
	if button.disabled:
		failures.append("button containing is disabled: %s" % text_value)
		return
	button.pressed.emit()


func _press_button_with_label_descendant(node: Node, text_value: String) -> void:
	var button := _find_button_with_label_descendant(node, text_value)
	if button == null:
		failures.append("missing button with descendant label: %s" % text_value)
		return
	if button.disabled:
		failures.append("button with descendant label is disabled: %s" % text_value)
		return
	button.pressed.emit()


func _press_any_reward_target(node: Node) -> void:
	var button := _find_button_containing(node, "装备：")
	if button == null:
		button = _find_button_containing(node, "技能：")
	if button == null:
		failures.append("missing reward target button")
		return
	if button.disabled:
		failures.append("reward target button is disabled")
		return
	button.pressed.emit()


func _assert_button_exists(node: Node, text_value: String) -> void:
	if _find_button(node, text_value) == null:
		failures.append("missing button: %s" % text_value)


func _assert_label_exists(node: Node, text_value: String) -> void:
	if _find_label_containing(node, text_value) == null:
		failures.append("missing label containing: %s" % text_value)


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


func _assert_enemy_tooltip(node: Node) -> void:
	var enemy_button := _find_button_containing(node, "被动技能：")
	if enemy_button == null:
		failures.append("missing enemy card with passive skills")
		return
	if String(enemy_button.tooltip_text).is_empty():
		failures.append("enemy passive skills tooltip should not be empty")


func _find_button_containing(node: Node, text_value: String) -> Button:
	if node is Button and String(node.text).contains(text_value):
		return node
	for child in node.get_children():
		var found := _find_button_containing(child, text_value)
		if found != null:
			return found
	return null


func _find_button_with_label_descendant(node: Node, text_value: String) -> Button:
	if node is Button and _node_has_label_containing(node, text_value):
		return node
	for child in node.get_children():
		var found := _find_button_with_label_descendant(child, text_value)
		if found != null:
			return found
	return null


func _find_label_containing(node: Node, text_value: String) -> Label:
	if node is Label and String(node.text).contains(text_value):
		return node
	for child in node.get_children():
		var found := _find_label_containing(child, text_value)
		if found != null:
			return found
	return null


func _node_has_label_containing(node: Node, text_value: String) -> bool:
	if node is Label and String(node.text).contains(text_value):
		return true
	for child in node.get_children():
		if _node_has_label_containing(child, text_value):
			return true
	return false


func _force_first_enemy_to_low_hp(main: Node) -> void:
	for i in range(main.session.enemies.size()):
		if int(main.session.enemies[i]["hp"]) > 0:
			main.session.enemies[i]["hp"] = 1
			main.session.enemies[i]["block"] = 0
			main.session.enemies[i]["dodge_layers"] = 0
			main.selected_target = i
			main._request_game_render()
			return
	failures.append("no living enemy to lower for reward test")


func _wait_for_render() -> void:
	await process_frame
	await process_frame


func _wait_seconds(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = seconds
	root.add_child(timer)
	timer.start()
	await timer.timeout
	timer.queue_free()
