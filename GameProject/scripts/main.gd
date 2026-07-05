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
		child.queue_free()


func _render_menu() -> void:
	_clear_root()
	var title := _label("SUPER TOWER", 30)
	root.add_child(title)
	root.add_child(_label("Playable MVP: tutorial, manual combat, rewards, equipment, skills, and floors 1-10.", 16))
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
	box.add_child(_label("HP %d  ATK %d  ARMOR %d" % [int(data["max_hp"]), int(data["base_attack"]), int(data["base_defense"])], 16))
	box.add_child(_label("First skill: %s" % DataCatalog.SKILLS[data["first_skill"]]["name"], 16))
	var button := Button.new()
	button.text = "Start %s" % data["name"]
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
	top.add_child(_label("Floor %d / Battle %d" % [session.floor_index, session.battle_index], 22))
	top.add_child(_spacer())
	top.add_child(_label("HP %d/%d  Armor %d  Dodge %d  AP %d" % [
		int(session.player.get("hp", 0)),
		int(session.player.get("max_hp", 0)),
		session.player_armor,
		session.dodge_layers,
		session.action_points
	], 18))
	root.add_child(top)
	root.add_child(_label(session.message, 16))

	match session.phase:
		"battle":
			_render_battle()
		"reward":
			_render_reward()
		"victory":
			_render_end_screen("Floor 10 cleared", "You completed the playable MVP route.")
		"game_over":
			_render_end_screen("Run ended", session.message)


func _render_battle() -> void:
	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	left.add_child(_label("Enemies", 20))
	var enemy_row := HBoxContainer.new()
	left.add_child(enemy_row)
	for i in range(session.enemies.size()):
		enemy_row.add_child(_enemy_card(i))

	left.add_child(_label("State Cards", 18))
	var state_row := HBoxContainer.new()
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
		left.add_child(_label("Readied: %s" % DataCatalog.STATE_CARDS[session.pending_state_card]["name"], 16))

	var action_row := HBoxContainer.new()
	left.add_child(action_row)
	action_row.add_child(_action_button("Attack", func() -> void:
		session.player_attack(selected_target)
		_render_game()
	))
	action_row.add_child(_action_button("Defend", func() -> void:
		session.player_defend()
		_render_game()
	))
	action_row.add_child(_action_button("Dodge", func() -> void:
		session.player_dodge()
		_render_game()
	))
	action_row.add_child(_action_button("End Turn", func() -> void:
		session.end_turn()
		_render_game()
	))

	left.add_child(_label("Skills", 18))
	var skill_row := HBoxContainer.new()
	left.add_child(skill_row)
	for i in range(4):
		var button := Button.new()
		button.custom_minimum_size = Vector2(150, 52)
		if i < session.player["equipped_skills"].size():
			var skill_id: String = session.player["equipped_skills"][i]
			var skill: Dictionary = DataCatalog.SKILLS[skill_id]
			button.text = "%s (%d AP)" % [skill["name"], int(skill.get("cost", 0))]
			button.pressed.connect(func(index := i) -> void:
				session.use_skill(index, selected_target)
				_render_game()
			)
		else:
			button.text = "Locked"
			button.disabled = true
		skill_row.add_child(button)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(320, 0)
	body.add_child(right)
	_render_character_panel(right)
	_render_log(right)


func _enemy_card(index: int) -> Control:
	var enemy: Dictionary = session.enemies[index]
	var button := Button.new()
	button.custom_minimum_size = Vector2(190, 140)
	var selected := ">" if index == selected_target else ""
	button.text = "%s %s\n%s\nHP %d/%d\nArmor %d\nTraits: %s" % [
		selected,
		enemy["name"],
		enemy["rank"],
		int(enemy["hp"]),
		int(enemy["max_hp"]),
		int(enemy["armor"]),
		", ".join(enemy["traits"])
	]
	button.disabled = int(enemy["hp"]) <= 0
	button.pressed.connect(func() -> void:
		selected_target = index
		_render_game()
	)
	return button


func _render_reward() -> void:
	root.add_child(_label("Choose Reward", 24))
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
	root.add_child(_action_button("Back to Main Menu", func() -> void:
		session = PlaySession.new()
		_render_menu()
	))


func _render_character_panel(parent: Control) -> void:
	var panel := PanelContainer.new()
	var box := VBoxContainer.new()
	panel.add_child(box)
	box.add_child(_label("Character", 18))
	box.add_child(_label("Class: %s" % DataCatalog.CLASSES[session.class_id]["name"], 14))
	box.add_child(_label("ATK %d  DEF %d  Max HP %d" % [int(session.player["attack"]), int(session.player["defense"]), int(session.player["max_hp"])], 14))
	box.add_child(_label("Equipment", 16))
	for item_id in session.player["equipment_ids"]:
		var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
		box.add_child(_label("%s: %s  HP+%d ATK+%d ARM+%d" % [item["slot"], item["name"], int(item["hp"]), int(item["attack"]), int(item["armor"])], 12))
	box.add_child(_label("Unlocked Skills", 16))
	for skill_id in session.player["unlocked_skills"]:
		box.add_child(_label("- %s" % DataCatalog.SKILLS[skill_id]["name"], 12))
	parent.add_child(panel)


func _render_log(parent: Control) -> void:
	parent.add_child(_label("Battle Log", 18))
	var log_text := RichTextLabel.new()
	log_text.custom_minimum_size = Vector2(300, 180)
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var start: int = maxi(0, session.battle_log.size() - 8)
	var lines: Array[String] = []
	for i in range(start, session.battle_log.size()):
		lines.append(session.battle_log[i])
	log_text.text = "\n".join(lines)
	parent.add_child(log_text)


func _action_button(text_value: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(120, 52)
	button.pressed.connect(callback)
	return button


func _label(text_value: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text_value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	return label


func _spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer
