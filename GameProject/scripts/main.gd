extends Control

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const PlaySession = preload("res://scripts/core/play_session.gd")

@onready var root: VBoxContainer = $Root

var session := PlaySession.new()
var selected_target := 0
var render_queued := false
var input_locked := false
var equipment_open := false
var enemy_card_nodes: Dictionary = {}
var player_status_node: Control = null
var player_status_labels: Dictionary = {}
var message_label_node: Label = null
var pending_state_label_node: Label = null
var action_buttons: Array[Button] = []
var skill_buttons: Array[Button] = []
var charge_buttons: Array[Button] = []
var log_text_node: RichTextLabel = null


func _ready() -> void:
	_render_menu()


func _request_game_render() -> void:
	if render_queued:
		return
	render_queued = true
	call_deferred("_render_game")


func _request_menu_render() -> void:
	if render_queued:
		return
	render_queued = true
	call_deferred("_render_menu")


func _clear_root() -> void:
	_clear_overlay_layers()
	for child in root.get_children():
		child.queue_free()


func _clear_overlay_layers() -> void:
	for child in get_children():
		if child != root:
			child.queue_free()


func _render_menu() -> void:
	render_queued = false
	_clear_root()
	var title := _label("无限高塔", 30)
	root.add_child(title)
	root.add_child(_label("可玩版本：新手引导、手动战斗、奖励选择、装备、技能和 1-10 层流程。", 16))
	if session.has_active_run():
		var continue_button := Button.new()
		continue_button.text = "继续当前派遣"
		continue_button.custom_minimum_size = Vector2(220, 56)
		continue_button.pressed.connect(func() -> void:
			if session.load_game():
				selected_target = 0
				equipment_open = false
				_request_game_render()
		)
		root.add_child(continue_button)
	var class_row := HBoxContainer.new()
	class_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(class_row)
	class_row.add_child(_class_panel("warrior"))
	class_row.add_child(_class_panel("archer"))


func _class_panel(class_key: String) -> Control:
	var data: Dictionary = DataCatalog.CLASSES[class_key]
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_child(_label(String(data["name"]), 24))
	box.add_child(_label("生命 %d  攻击 %d  护甲 %d  格挡 %d" % [int(data["max_hp"]), int(data["base_attack"]), int(data["base_defense"]), int(data.get("base_block", 1))], 16))
	box.add_child(_label("第一个技能：%s" % DataCatalog.SKILLS[data["first_skill"]]["name"], 16))
	var roster_player := session.get_roster_player(class_key)
	if roster_player.is_empty():
		box.add_child(_label("队伍状态：未招募", 14))
	else:
		box.add_child(_label("队伍状态：装备 %d  技能 %d" % [
			roster_player.get("equipment_ids", []).size(),
			roster_player.get("unlocked_skills", []).size()
		], 14))
	var button := Button.new()
	button.text = "派遣：%s" % data["name"]
	button.custom_minimum_size = Vector2(180, 56)
	button.pressed.connect(func() -> void:
		session.start_new_game(class_key)
		_persist_session()
		selected_target = 0
		_request_game_render()
	)
	box.add_child(button)
	panel.add_child(box)
	return panel


func _render_game() -> void:
	render_queued = false
	_clear_root()
	var top := HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_status_badge("第 %d 层" % session.floor_index, 22, Vector2(110, 42)))
	top.add_child(_status_badge("第 %d 场" % session.battle_index, 22, Vector2(110, 42)))
	top.add_child(_spacer())
	root.add_child(top)
	var message_label := _label(session.message, 16)
	message_label_node = message_label
	message_label.custom_minimum_size = Vector2(0, 30)
	root.add_child(message_label)

	match session.phase:
		"battle":
			_render_battle()
		"reward":
			_render_reward()
		"reward_target":
			_render_reward_target()
		"victory":
			_render_end_screen("已通关第 10 层", "你已经完成当前可玩版本的目标。")
		"game_over":
			_render_end_screen("本局结束", session.message)


func _render_battle() -> void:
	enemy_card_nodes.clear()
	player_status_node = null
	player_status_labels.clear()
	pending_state_label_node = null
	action_buttons.clear()
	skill_buttons.clear()
	charge_buttons.clear()
	log_text_node = null
	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var combat_area := VBoxContainer.new()
	combat_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	combat_area.custom_minimum_size = Vector2(650, 0)
	body.add_child(combat_area)
	combat_area.add_child(_label("敌人", 20))
	var enemy_row := HBoxContainer.new()
	enemy_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_area.add_child(enemy_row)
	for i in range(session.enemies.size()):
		enemy_row.add_child(_enemy_card(i))

	combat_area.add_child(_spacer_vertical())
	pending_state_label_node = _status_badge(_pending_state_text(), 16, Vector2(220, 44))
	combat_area.add_child(pending_state_label_node)

	var bottom_bar := HBoxContainer.new()
	bottom_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_area.add_child(bottom_bar)
	_render_player_status(bottom_bar)
	var equip_button := _action_button("装备", func() -> void:
		equipment_open = not equipment_open
		_request_game_render()
	)
	equip_button.custom_minimum_size = Vector2(96, 92)
	bottom_bar.add_child(equip_button)
	_render_actions(bottom_bar)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(340, 0)
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	_render_log(right)
	if equipment_open:
		_show_equipment_overlay()


func _enemy_card(index: int) -> Control:
	var enemy: Dictionary = session.enemies[index]
	var button := Button.new()
	button.custom_minimum_size = Vector2(220, 160)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var selected := ">" if index == selected_target else ""
	button.text = _enemy_card_text(index, selected)
	button.tooltip_text = _trait_tooltip(enemy["traits"])
	button.disabled = int(enemy["hp"]) <= 0
	button.pressed.connect(func() -> void:
		selected_target = index
		call_deferred("_refresh_battle_ui")
	)
	enemy_card_nodes[index] = button
	return button


func _enemy_card_text(index: int, selected: String = "") -> String:
	var enemy: Dictionary = session.enemies[index]
	return "%s %s\n%s\n生命 %d/%d\n攻击 %d  护甲 %d\n意图：%s\n特性：%s" % [
		selected,
		enemy["name"],
		_rank_label(enemy["rank"]),
		int(enemy["hp"]),
		int(enemy["max_hp"]),
		int(enemy["attack"]),
		int(enemy["armor"]),
		session.enemy_intent_text(index),
		_trait_labels(enemy["traits"])
	]


func _render_player_status(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(190, 178)
	panel.size_flags_vertical = Control.SIZE_SHRINK_END
	var box := VBoxContainer.new()
	panel.add_child(box)
	player_status_labels["class"] = _label(DataCatalog.CLASSES[session.class_id]["name"], 18)
	player_status_labels["action"] = _label("行动力 %d/%d" % [session.action_points, session.max_action_points], 15)
	player_status_labels["hp"] = _label("hp %d/%d" % [int(session.player["hp"]), int(session.player["max_hp"])], 15)
	player_status_labels["block"] = _label("格挡 %d" % session.player_block, 15)
	player_status_labels["block_power"] = _label("格挡值 %d" % int(session.player["block_power"]), 15)
	player_status_labels["attack"] = _label("攻击 %d" % int(session.player["attack"]), 15)
	player_status_labels["armor"] = _label("护甲 %d" % int(session.player["defense"]), 15)
	for key in ["class", "action", "hp", "block", "block_power", "attack", "armor"]:
		box.add_child(player_status_labels[key])
	player_status_node = panel
	parent.add_child(panel)


func _render_actions(parent: Control) -> void:
	var actions := VBoxContainer.new()
	actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(actions)
	var basic_row := HBoxContainer.new()
	basic_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(basic_row)
	basic_row.add_child(_action_button("普通攻击", Callable(self, "_on_attack_pressed")))
	basic_row.add_child(_action_button("防御", Callable(self, "_on_defend_pressed")))
	basic_row.add_child(_action_button("躲避", Callable(self, "_on_dodge_pressed")))
	basic_row.add_child(_action_button("结束回合", Callable(self, "_on_end_turn_pressed")))
	for child in basic_row.get_children():
		action_buttons.append(child as Button)
	_refresh_action_buttons()

	var skill_row := HBoxContainer.new()
	skill_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(skill_row)
	for i in range(4):
		var button := Button.new()
		button.custom_minimum_size = Vector2(140, 48)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.disabled = input_locked or i >= session.player["equipped_skills"].size()
		if i < session.player["equipped_skills"].size():
			var skill_id: String = session.player["equipped_skills"][i]
			var skill: Dictionary = DataCatalog.SKILLS[skill_id]
			button.text = "%s（%d）" % [skill["name"], int(skill.get("cost", 0))]
			button.disabled = input_locked or session.action_points < int(skill.get("cost", 0))
			button.pressed.connect(func(index := i) -> void:
				_on_skill_pressed(index)
			)
		else:
			button.text = "未解锁"
		skill_row.add_child(button)
		skill_buttons.append(button)
	var charges := session.available_charges()
	if not charges.is_empty():
		var charge_grid := GridContainer.new()
		charge_grid.columns = 4
		charge_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(charge_grid)
		for charge in charges:
			var button := Button.new()
			var charge_id := String(charge.get("charge_id", ""))
			button.set_meta("charge_id", charge_id)
			button.custom_minimum_size = Vector2(150, 72)
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.text = "%s\n%s" % [_charge_button_label(charge), String(charge.get("source_label", ""))]
			button.disabled = input_locked or bool(charge.get("used", false)) or not bool(charge.get("ready", false))
			button.pressed.connect(func(id := charge_id) -> void:
				_on_charge_pressed(id)
			)
			charge_grid.add_child(button)
			charge_buttons.append(button)
	_refresh_action_buttons()


func _equipment_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 460)
	var outer := VBoxContainer.new()
	panel.add_child(outer)
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(header)
	header.add_child(_label("装备", 22))
	header.add_child(_spacer())
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(84, 38)
	close_button.pressed.connect(func() -> void:
		equipment_open = false
		_request_game_render()
	)
	header.add_child(close_button)
	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(columns)

	var body_slots := VBoxContainer.new()
	body_slots.custom_minimum_size = Vector2(230, 0)
	columns.add_child(body_slots)
	body_slots.add_child(_label("人体装备栏", 16))
	for slot in ["head", "body", "waist", "legs", "hands", "leggings", "feet", "weapon", "offhand", "necklace", "ring"]:
		body_slots.add_child(_label("%s：%s" % [_slot_label(slot), _equipped_name(slot)], 13))

	var bag_scroll := ScrollContainer.new()
	bag_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	columns.add_child(bag_scroll)
	var bag := VBoxContainer.new()
	bag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_scroll.add_child(bag)
	bag.add_child(_label("本局背包", 16))
	if session.player["equipment_ids"].is_empty():
		bag.add_child(_label("暂无本局装备。", 13))
	else:
		for item_id in session.player["equipment_ids"]:
			var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
			bag.add_child(_label("%s\n%s  生命+%d 攻击+%d 护甲+%d 格挡+%d\n%s" % [
				item["name"],
				_slot_label(item["slot"]),
				int(item["hp"]),
				int(item["attack"]),
				int(item["armor"]),
				int(item.get("block", 0)),
				_attachment_summary("equipment", item_id)
			], 12))
	bag.add_child(_label("技能附着", 16))
	for skill_id in session.player["equipped_skills"]:
		bag.add_child(_label("%s\n%s" % [
			DataCatalog.SKILLS[skill_id]["name"],
			_attachment_summary("skill", skill_id)
		], 12))
	return panel


func _show_equipment_overlay() -> void:
	var overlay := Control.new()
	overlay.name = "EquipmentOverlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 200
	add_child(overlay)

	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.45)
	overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.add_child(_equipment_panel())
	overlay.add_child(center)


func _on_attack_pressed() -> void:
	_run_action(func() -> void:
		session.player_attack(selected_target)
	)


func _on_defend_pressed() -> void:
	_run_action(func() -> void:
		session.player_defend()
	)


func _on_dodge_pressed() -> void:
	_run_action(func() -> void:
		session.player_dodge()
	)


func _on_end_turn_pressed() -> void:
	_run_action(func() -> void:
		session.end_turn()
	)


func _on_skill_pressed(index: int) -> void:
	_run_action(func() -> void:
		session.use_skill(index, selected_target)
	)


func _on_charge_pressed(charge_id: String) -> void:
	_run_action(func() -> void:
		session.use_charge(charge_id)
	)


func _run_action(action: Callable) -> void:
	if input_locked:
		return
	input_locked = true
	action.call()
	await _play_action_feedback()
	input_locked = false
	_persist_session()
	if session.phase == "battle":
		_refresh_battle_ui()
	else:
		_request_game_render()


func _play_action_feedback() -> void:
	var events := session.last_events.duplicate(true)
	if events.is_empty():
		await get_tree().create_timer(0.15).timeout
		return
	for event in events:
		if event.get("target", "") == "enemy":
			var target_index := int(event.get("target_index", 0))
			_shake_node(enemy_card_nodes.get(target_index, null))
			var enemy_prefix := "+" if event.get("kind", "") in ["defense", "dodge"] else "-"
			if int(event.get("amount", 0)) > 0:
				_float_number(enemy_card_nodes.get(target_index, null), "%s%d" % [enemy_prefix, int(event.get("amount", 0))], "center_bottom")
		elif event.get("target", "") == "player":
			_shake_node(player_status_node)
			if int(event.get("amount", 0)) > 0:
				var prefix := "+" if event.get("kind", "") in ["defense", "heal", "dodge"] else "-"
				_float_number(player_status_node, "%s%d" % [prefix, int(event.get("amount", 0))], "center_top")
	await get_tree().create_timer(0.9).timeout


func _shake_node(node: Variant) -> void:
	if node == null or not (node is Control):
		return
	var control: Control = node
	var origin := control.position
	var tween := create_tween()
	tween.tween_property(control, "position", origin + Vector2(8, 0), 0.05)
	tween.tween_property(control, "position", origin + Vector2(-8, 0), 0.05)
	tween.tween_property(control, "position", origin + Vector2(4, 0), 0.05)
	tween.tween_property(control, "position", origin, 0.05)


func _float_number(node: Variant, text_value: String, placement: String) -> void:
	if node == null or not (node is Control):
		return
	var control: Control = node
	var label := _label(text_value, 22)
	label.custom_minimum_size = Vector2(120, 34)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.modulate = Color(1, 0.25, 0.2, 1) if text_value.begins_with("-") else Color(0.35, 1.0, 0.55, 1)
	label.z_index = 100
	add_child(label)
	label.global_position = _float_number_position(control, label.custom_minimum_size, placement)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "global_position", label.global_position + Vector2(0, -36), 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8)
	tween.finished.connect(func() -> void:
		if is_instance_valid(label):
			label.queue_free()
	)


func _float_number_position(control: Control, popup_size: Vector2, placement: String) -> Vector2:
	var x := control.global_position.x + (control.size.x - popup_size.x) * 0.5
	var y := control.global_position.y + (control.size.y - popup_size.y) * 0.5
	if placement == "center_bottom":
		y = control.global_position.y + control.size.y * 0.62
	elif placement == "center_top":
		y = control.global_position.y + control.size.y * 0.18
	return Vector2(x, y)


func _render_reward() -> void:
	var reward_area := CenterContainer.new()
	reward_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reward_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(reward_area)

	var options := VBoxContainer.new()
	options.custom_minimum_size = Vector2(460, 0)
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	reward_area.add_child(options)
	var title := _label("选择奖励", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options.add_child(title)
	for i in range(session.reward_options.size()):
		var reward: Dictionary = session.reward_options[i]
		var button := Button.new()
		button.text = String(reward["label"]).replace("塔内附着：", "")
		button.custom_minimum_size = Vector2(460, 64)
		button.pressed.connect(func(index := i) -> void:
			session.choose_reward(index)
			_persist_session()
			selected_target = 0
			_request_game_render()
		)
		options.add_child(button)


func _render_reward_target() -> void:
	var target_area := CenterContainer.new()
	target_area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	target_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(target_area)

	var options := VBoxContainer.new()
	options.custom_minimum_size = Vector2(500, 0)
	options.alignment = BoxContainer.ALIGNMENT_CENTER
	target_area.add_child(options)
	var title := _label("选择附着目标", 24)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options.add_child(title)
	var subtitle := _label(String(session.message), 15)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	options.add_child(subtitle)
	for i in range(session.reward_targets.size()):
		var target: Dictionary = session.reward_targets[i]
		var button := Button.new()
		button.text = "%s\n%s" % [_target_label(target), _attachment_summary(String(target["type"]), String(target["id"]))]
		button.custom_minimum_size = Vector2(500, 72)
		button.pressed.connect(func(index := i) -> void:
			session.choose_reward_target(index)
			_persist_session()
			selected_target = 0
			_request_game_render()
		)
		options.add_child(button)


func _render_end_screen(title: String, subtitle: String) -> void:
	root.add_child(_label(title, 30))
	root.add_child(_label(subtitle, 18))
	root.add_child(_action_button("返回主菜单", func() -> void:
		session = PlaySession.new()
		_request_menu_render()
	))


func _render_character_panel(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(box)
	box.add_child(_label("角色", 18))
	box.add_child(_label("职业：%s" % DataCatalog.CLASSES[session.class_id]["name"], 14))
	box.add_child(_label("攻击 %d  护甲 %d  格挡值 %d  生命上限 %d" % [int(session.player["attack"]), int(session.player["defense"]), int(session.player["block_power"]), int(session.player["max_hp"])], 14))
	box.add_child(_label("装备", 16))
	for item_id in session.player["equipment_ids"]:
		var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
		box.add_child(_label("%s：%s  生命+%d 攻击+%d 护甲+%d 格挡+%d" % [_slot_label(item["slot"]), item["name"], int(item["hp"]), int(item["attack"]), int(item["armor"]), int(item.get("block", 0))], 12))
	box.add_child(_label("已解锁技能", 16))
	for skill_id in session.player["unlocked_skills"]:
		box.add_child(_label("- %s" % DataCatalog.SKILLS[skill_id]["name"], 12))
	parent.add_child(panel)


func _render_log(parent: Control) -> void:
	parent.add_child(_label("战斗日志", 18))
	var log_text := RichTextLabel.new()
	log_text_node = log_text
	log_text.custom_minimum_size = Vector2(320, 180)
	log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_text.text = _battle_log_text()
	parent.add_child(log_text)


func _battle_log_text() -> String:
	var start: int = maxi(0, session.battle_log.size() - 8)
	var lines: Array[String] = []
	for i in range(start, session.battle_log.size()):
		lines.append(session.battle_log[i])
	return "\n".join(lines)


func _refresh_battle_ui() -> void:
	if session.phase != "battle":
		_request_game_render()
		return
	if message_label_node != null and is_instance_valid(message_label_node):
		message_label_node.text = session.message
	for index in enemy_card_nodes.keys():
		var button: Button = enemy_card_nodes[index]
		if is_instance_valid(button) and index < session.enemies.size():
			var selected := ">" if int(index) == selected_target else ""
			button.text = _enemy_card_text(int(index), selected)
			button.tooltip_text = _trait_tooltip(session.enemies[index]["traits"])
			button.disabled = int(session.enemies[index]["hp"]) <= 0
	if player_status_labels.has("action"):
		player_status_labels["action"].text = "行动力 %d/%d" % [session.action_points, session.max_action_points]
	if player_status_labels.has("hp"):
		player_status_labels["hp"].text = "hp %d/%d" % [int(session.player["hp"]), int(session.player["max_hp"])]
	if player_status_labels.has("attack"):
		player_status_labels["attack"].text = "攻击 %d" % int(session.player["attack"])
	if player_status_labels.has("armor"):
		player_status_labels["armor"].text = "护甲 %d" % int(session.player["defense"])
	if player_status_labels.has("block"):
		player_status_labels["block"].text = "格挡 %d" % session.player_block
	if player_status_labels.has("block_power"):
		player_status_labels["block_power"].text = "格挡值 %d" % int(session.player["block_power"])
	if pending_state_label_node != null and is_instance_valid(pending_state_label_node):
		pending_state_label_node.text = _pending_state_text()
	_refresh_action_buttons()
	if log_text_node != null and is_instance_valid(log_text_node):
		log_text_node.text = _battle_log_text()


func _refresh_action_buttons() -> void:
	for i in range(action_buttons.size()):
		var button := action_buttons[i]
		if button == null or not is_instance_valid(button):
			continue
		if i < 3:
			button.disabled = input_locked or session.action_points < 1
		else:
			button.disabled = input_locked
	for i in range(skill_buttons.size()):
		var button := skill_buttons[i]
		if button == null or not is_instance_valid(button):
			continue
		if i >= session.player["equipped_skills"].size():
			button.disabled = true
			continue
		var skill_id: String = session.player["equipped_skills"][i]
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		button.disabled = input_locked or session.action_points < int(skill.get("cost", 0))
	for button in charge_buttons:
		if button == null or not is_instance_valid(button):
			continue
		var charge_id := String(button.get_meta("charge_id", ""))
		button.disabled = input_locked or bool(session.charge_used.get(charge_id, false)) or not bool(session.charge_ready.get(charge_id, false))


func _pending_state_text() -> String:
	if session.pending_state_card == "":
		return "状态 Buff：无"
	return "状态 Buff：%s" % DataCatalog.STATE_CARDS[session.pending_state_card]["name"]


func _persist_session() -> void:
	session.save_game()


func _action_button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(132, 52)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.disabled = input_locked
	button.pressed.connect(callback)
	return button


func _label(text_value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _status_badge(text_value: String, font_size: int, min_size: Vector2) -> Label:
	var label := Label.new()
	label.text = text_value
	label.custom_minimum_size = min_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer


func _spacer_vertical() -> Control:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return spacer


func _equipped_name(slot: String) -> String:
	var equipment: Dictionary = session.player.get("equipment", {})
	if equipment.has(slot):
		var item_id: String = equipment[slot]
		return DataCatalog.EQUIPMENT[item_id]["name"]
	return "空"


func _rank_label(rank: String) -> String:
	match rank:
		"normal":
			return "普通"
		"elite":
			return "精英"
		"boss":
			return "首领"
	return rank


func _slot_label(slot: String) -> String:
	var labels := {
		"head": "头部",
		"body": "上身",
		"waist": "腰部",
		"legs": "下身",
		"hands": "手部",
		"leggings": "护腿",
		"feet": "脚部",
		"weapon": "武器",
		"offhand": "副手",
		"necklace": "项链",
		"ring": "戒指"
	}
	return labels.get(slot, slot)


func _target_label(target: Dictionary) -> String:
	var target_type := String(target.get("type", ""))
	var target_id := String(target.get("id", ""))
	if target_type == "equipment" and DataCatalog.EQUIPMENT.has(target_id):
		var item: Dictionary = DataCatalog.EQUIPMENT[target_id]
		return "装备：%s（%s）" % [item["name"], _slot_label(item["slot"])]
	if target_type == "skill" and DataCatalog.SKILLS.has(target_id):
		var skill: Dictionary = DataCatalog.SKILLS[target_id]
		return "技能：%s" % skill["name"]
	return target_id


func _attachment_summary(target_type: String, target_id: String) -> String:
	var key := "equipment_attachments" if target_type == "equipment" else "skill_attachments"
	var groups: Dictionary = session.player.get(key, {})
	var attachments: Array = groups.get(target_id, [])
	if attachments.is_empty():
		return "附着：无"
	var labels: Array[String] = []
	for attachment in attachments:
		labels.append(String(attachment.get("label", attachment.get("kind", ""))).replace("状态卡", "状态 Buff"))
	return "附着：" + "、".join(labels)


func _charge_button_label(charge: Dictionary) -> String:
	var label := String(charge.get("label", "充能"))
	label = label.replace("充能：", "")
	var state := "已使用" if bool(charge.get("used", false)) else ("已充能" if bool(charge.get("ready", false)) else "未充能")
	return "%s\n%s" % [label, state]


func _trait_labels(traits: Array) -> String:
	if traits.is_empty():
		return "无"
	var labels := {
		"swarm": "群袭",
		"claw": "利爪",
		"thick_skin": "厚皮",
		"break_armor": "破甲",
		"first_strike": "先手",
		"cunning": "狡诈",
		"mark": "标记",
		"curse": "诅咒",
		"guard": "护卫",
		"tank": "肉盾",
		"taunt": "嘲讽",
		"backline": "后排",
		"fortify": "固守",
		"summon": "召唤",
		"revive": "复苏",
		"enrage": "狂暴",
		"evade": "闪身",
		"spell_shield": "法盾",
		"charge": "充能",
		"split": "裂变",
		"corrode": "腐蚀",
		"support": "辅助",
		"phase": "阶段"
	}
	var result: Array[String] = []
	for trait_id in traits:
		result.append(labels.get(trait_id, trait_id))
	return "、".join(result)


func _trait_tooltip(traits: Array) -> String:
	if traits.is_empty():
		return "特性：无\n该敌人没有额外战斗规则。"
	var descriptions := {
		"swarm": "群袭：攻击时追加一段小额伤害。",
		"claw": "利爪：攻击伤害提高。",
		"thick_skin": "厚皮：入场获得额外护甲。",
		"break_armor": "破甲：设计定位为削弱护甲的攻击型敌人。",
		"first_strike": "先手：战斗开始时会先进行一次削弱后的攻击。",
		"cunning": "狡诈：隐藏真实意图，界面只显示狡诈而不会显示攻击、防守或闪避。",
		"mark": "标记：设计定位为提高后续输出压力。",
		"curse": "诅咒：每隔数回合对玩家造成直接伤害。",
		"guard": "护卫：会交替攻击与防守。",
		"tank": "肉盾：倾向于防守，保护队伍后排。",
		"taunt": "嘲讽：部分回合会嘲讽并防守，强制玩家优先攻击它。",
		"backline": "后排：队伍中的输出手，通常由前排保护。",
		"fortify": "固守：偶数回合会增加护甲。",
		"summon": "召唤：每隔数回合追加一段伤害压力。",
		"revive": "复苏：每隔数回合恢复少量生命。",
		"enrage": "狂暴：低生命时攻击伤害提高。",
		"evade": "闪身：部分回合准备闪避，抵消下一次命中。",
		"spell_shield": "法盾：设计定位为抵御技能爆发。",
		"charge": "充能：设计定位为蓄力后的高压行动。",
		"split": "裂变：设计定位为多阶段或分裂战斗。",
		"corrode": "腐蚀：设计定位为持续削弱玩家防御。",
		"support": "辅助：队伍中的辅助单位。",
		"phase": "阶段：首领拥有阶段变化。"
	}
	var lines: Array[String] = ["特性说明"]
	for trait_id in traits:
		lines.append(descriptions.get(trait_id, "%s：暂无说明。" % trait_id))
	return "\n".join(lines)
