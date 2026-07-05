extends Control

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const PlaySession = preload("res://scripts/core/play_session.gd")

@onready var root: VBoxContainer = $Root

var session := PlaySession.new()
var selected_target := 0


func _ready() -> void:
	_render_menu()


func _clear_root() -> void:
	for child in root.get_children():
		root.remove_child(child)
		child.free()


func _render_menu() -> void:
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
		_render_game()
	)
	box.add_child(button)
	panel.add_child(box)
	return panel


func _render_game() -> void:
	_clear_root()
	var top := HBoxContainer.new()
	top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_status_badge("第 %d 层" % session.floor_index, 22, Vector2(110, 42)))
	top.add_child(_status_badge("第 %d 场" % session.battle_index, 22, Vector2(110, 42)))
	top.add_child(_spacer())
	top.add_child(_status_badge("生命 %d/%d" % [int(session.player.get("hp", 0)), int(session.player.get("max_hp", 0))], 18, Vector2(150, 42)))
	top.add_child(_status_badge("护甲 %d" % session.player_armor, 18, Vector2(92, 42)))
	top.add_child(_status_badge("躲避 %d" % session.dodge_layers, 18, Vector2(92, 42)))
	top.add_child(_status_badge("行动力 %d" % session.action_points, 18, Vector2(110, 42)))
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
	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.custom_minimum_size = Vector2(760, 0)
	body.add_child(left)
	left.add_child(_label("敌人（第 1 场是单敌人教学，后续会出现多敌人编队）", 20))
	var enemy_row := HBoxContainer.new()
	enemy_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(enemy_row)
	for i in range(session.enemies.size()):
		enemy_row.add_child(_enemy_card(i))

	left.add_child(_label("状态卡", 18))
	var state_row := HBoxContainer.new()
	state_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(state_row)
	for i in range(session.state_cards.size()):
		var card_id: String = session.state_cards[i]
		var button := Button.new()
		button.text = DataCatalog.STATE_CARDS[card_id]["name"]
		button.custom_minimum_size = Vector2(130, 48)
		button.pressed.connect(func(index := i) -> void:
			session.use_state_card(index)
			_render_game()
		)
		state_row.add_child(button)
	if session.pending_state_card != "":
		left.add_child(_label("已准备：%s" % DataCatalog.STATE_CARDS[session.pending_state_card]["name"], 16))

	var action_row := HBoxContainer.new()
	action_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(action_row)
	action_row.add_child(_action_button("普通攻击", func() -> void:
		session.player_attack(selected_target)
		_render_game()
	))
	action_row.add_child(_action_button("防御", func() -> void:
		session.player_defend()
		_render_game()
	))
	action_row.add_child(_action_button("躲避", func() -> void:
		session.player_dodge()
		_render_game()
	))
	action_row.add_child(_action_button("结束回合", func() -> void:
		session.end_turn()
		_render_game()
	))

	left.add_child(_label("技能", 18))
	var skill_row := HBoxContainer.new()
	skill_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(skill_row)
	for i in range(4):
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 52)
		if i < session.player["equipped_skills"].size():
			var skill_id: String = session.player["equipped_skills"][i]
			var skill: Dictionary = DataCatalog.SKILLS[skill_id]
			button.text = "%s（%d 行动力）" % [skill["name"], int(skill.get("cost", 0))]
			button.pressed.connect(func(index := i) -> void:
				session.use_skill(index, selected_target)
				_render_game()
			)
		else:
			button.text = "未解锁"
			button.disabled = true
		skill_row.add_child(button)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(360, 0)
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(right)
	var right_scroll := ScrollContainer.new()
	right_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_child(right_scroll)
	var right_content := VBoxContainer.new()
	right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_scroll.add_child(right_content)
	_render_character_panel(right_content)
	_render_log(right_content)


func _enemy_card(index: int) -> Control:
	var enemy: Dictionary = session.enemies[index]
	var button := Button.new()
	button.custom_minimum_size = Vector2(210, 132)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var selected := ">" if index == selected_target else ""
	button.text = "%s %s\n%s\n生命 %d/%d\n护甲 %d\n特性：%s" % [
		selected,
		enemy["name"],
		_rank_label(enemy["rank"]),
		int(enemy["hp"]),
		int(enemy["max_hp"]),
		int(enemy["armor"]),
		_trait_labels(enemy["traits"])
	]
	button.disabled = int(enemy["hp"]) <= 0
	button.pressed.connect(func() -> void:
		selected_target = index
		_render_game()
	)
	return button


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
			_render_game()
		)
		root.add_child(button)
	_render_character_panel(root)


func _render_end_screen(title: String, subtitle: String) -> void:
	root.add_child(_label(title, 30))
	root.add_child(_label(subtitle, 18))
	root.add_child(_action_button("返回主菜单", func() -> void:
		session = PlaySession.new()
		_render_menu()
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
