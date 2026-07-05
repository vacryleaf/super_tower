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
var deck_node: Control = null
var hand_row_node: Control = null


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
	for child in root.get_children():
		child.queue_free()


func _render_menu() -> void:
	render_queued = false
	_clear_root()
	var title := _label("无限高塔", 30)
	root.add_child(title)
	root.add_child(_label("可玩版本：新手引导、手动战斗、奖励选择、装备、技能和 1-10 层流程。", 16))
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
	box.add_child(_label("生命 %d  攻击 %d  护甲 %d" % [int(data["max_hp"]), int(data["base_attack"]), int(data["base_defense"])], 16))
	box.add_child(_label("第一个技能：%s" % DataCatalog.SKILLS[data["first_skill"]]["name"], 16))
	var button := Button.new()
	button.text = "开始：%s" % data["name"]
	button.custom_minimum_size = Vector2(180, 56)
	button.pressed.connect(func() -> void:
		session.start_new_game(class_key)
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
	message_label.custom_minimum_size = Vector2(0, 30)
	root.add_child(message_label)

	match session.phase:
		"battle":
			_render_battle()
		"reward":
			_render_reward()
		"victory":
			_render_end_screen("已通关第 10 层", "你已经完成当前可玩版本的目标。")
		"game_over":
			_render_end_screen("本局结束", session.message)


func _render_battle() -> void:
	enemy_card_nodes.clear()
	player_status_node = null
	deck_node = null
	hand_row_node = null
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
	combat_area.add_child(_label("手牌", 18))
	var state_row := HBoxContainer.new()
	state_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hand_row_node = state_row
	combat_area.add_child(state_row)
	for i in range(session.state_cards.size()):
		var card_id: String = session.state_cards[i]
		var button := Button.new()
		button.text = DataCatalog.STATE_CARDS[card_id]["name"]
		button.custom_minimum_size = Vector2(136, 56)
		button.disabled = input_locked
		button.pressed.connect(func(index := i) -> void:
			session.use_state_card(index)
			_request_game_render()
		)
		state_row.add_child(button)
	if session.pending_state_card != "":
		combat_area.add_child(_label("已准备：%s" % DataCatalog.STATE_CARDS[session.pending_state_card]["name"], 16))

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

	if equipment_open:
		body.add_child(_equipment_panel())

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(340, 0)
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	_render_deck(right)
	_render_log(right)
	if not session.last_drawn_cards.is_empty():
		var cards := session.last_drawn_cards.duplicate()
		session.last_drawn_cards.clear()
		call_deferred("_animate_draw_cards", cards)


func _enemy_card(index: int) -> Control:
	var enemy: Dictionary = session.enemies[index]
	var button := Button.new()
	button.custom_minimum_size = Vector2(220, 160)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var selected := ">" if index == selected_target else ""
	button.text = "%s %s\n%s\n生命 %d/%d\n攻击 %d  护甲 %d\n意图：攻击\n特性：%s" % [
		selected,
		enemy["name"],
		_rank_label(enemy["rank"]),
		int(enemy["hp"]),
		int(enemy["max_hp"]),
		int(enemy["attack"]),
		int(enemy["armor"]),
		_trait_labels(enemy["traits"])
	]
	button.disabled = int(enemy["hp"]) <= 0
	button.pressed.connect(func() -> void:
		selected_target = index
		_request_game_render()
	)
	enemy_card_nodes[index] = button
	return button


func _render_player_status(parent: Control) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(180, 132)
	panel.size_flags_vertical = Control.SIZE_SHRINK_END
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_label(DataCatalog.CLASSES[session.class_id]["name"], 18))
	box.add_child(_label("行动力 %d" % session.action_points, 15))
	box.add_child(_label("hp %d/%d" % [int(session.player["hp"]), int(session.player["max_hp"])], 15))
	box.add_child(_label("攻击 %d" % int(session.player["attack"]), 15))
	box.add_child(_label("护甲 %d" % int(session.player["defense"]), 15))
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
	for i in range(3):
		var button := basic_row.get_child(i) as Button
		button.disabled = input_locked or session.action_points < 1

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


func _equipment_panel() -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var outer := VBoxContainer.new()
	panel.add_child(outer)
	outer.add_child(_label("装备", 22))
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
			bag.add_child(_label("%s\n%s  生命+%d 攻击+%d 护甲+%d" % [
				item["name"],
				_slot_label(item["slot"]),
				int(item["hp"]),
				int(item["attack"]),
				int(item["armor"])
			], 12))
	return panel


func _render_deck(parent: Control) -> void:
	deck_node = PanelContainer.new()
	deck_node.custom_minimum_size = Vector2(320, 96)
	var box := VBoxContainer.new()
	deck_node.add_child(box)
	box.add_child(_label("卡堆", 18))
	box.add_child(_label("回合开始从这里抽取状态卡到手牌。", 13))
	parent.add_child(deck_node)
	parent.add_child(_spacer_vertical())


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


func _run_action(action: Callable) -> void:
	if input_locked:
		return
	input_locked = true
	action.call()
	await _play_action_feedback()
	input_locked = false
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
			_float_number(enemy_card_nodes.get(target_index, null), "-%d" % int(event.get("amount", 0)), "center_bottom")
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


func _animate_draw_cards(cards: Array) -> void:
	if deck_node == null or hand_row_node == null:
		return
	for i in range(cards.size()):
		var card_id: String = cards[i]
		var label := _label(DataCatalog.STATE_CARDS[card_id]["name"], 16)
		label.modulate = Color(0.8, 0.95, 1.0, 1)
		label.z_index = 100
		add_child(label)
		label.global_position = deck_node.global_position + Vector2(20, 20)
		var target := hand_row_node.global_position + Vector2(20 + i * 88, 8)
		var tween := create_tween()
		tween.tween_property(label, "global_position", target, 0.45)
		tween.tween_property(label, "modulate:a", 0.0, 0.2)
		tween.finished.connect(func() -> void:
			if is_instance_valid(label):
				label.queue_free()
		)


func _render_reward() -> void:
	root.add_child(_label("选择奖励", 24))
	for i in range(session.reward_options.size()):
		var reward: Dictionary = session.reward_options[i]
		var button := Button.new()
		button.text = reward["label"]
		button.custom_minimum_size = Vector2(760, 56)
		button.pressed.connect(func(index := i) -> void:
			session.choose_reward(index)
			selected_target = 0
			_request_game_render()
		)
		root.add_child(button)
	_render_character_panel(root)


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
	box.add_child(_label("攻击 %d  护甲 %d  生命上限 %d" % [int(session.player["attack"]), int(session.player["defense"]), int(session.player["max_hp"])], 14))
	box.add_child(_label("装备", 16))
	for item_id in session.player["equipment_ids"]:
		var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
		box.add_child(_label("%s：%s  生命+%d 攻击+%d 护甲+%d" % [_slot_label(item["slot"]), item["name"], int(item["hp"]), int(item["attack"]), int(item["armor"])], 12))
	box.add_child(_label("已解锁技能", 16))
	for skill_id in session.player["unlocked_skills"]:
		box.add_child(_label("- %s" % DataCatalog.SKILLS[skill_id]["name"], 12))
	parent.add_child(panel)


func _render_log(parent: Control) -> void:
	parent.add_child(_label("战斗日志", 18))
	var log_text := RichTextLabel.new()
	log_text.custom_minimum_size = Vector2(320, 180)
	log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var start: int = maxi(0, session.battle_log.size() - 8)
	var lines: Array[String] = []
	for i in range(start, session.battle_log.size()):
		lines.append(session.battle_log[i])
	log_text.text = "\n".join(lines)
	parent.add_child(log_text)


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


func _trait_labels(traits: Array) -> String:
	if traits.is_empty():
		return "无"
	var labels := {
		"swarm": "群袭",
		"claw": "利爪",
		"thick_skin": "厚皮",
		"break_armor": "破甲",
		"first_strike": "先手",
		"mark": "标记",
		"curse": "诅咒",
		"guard": "护卫",
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
