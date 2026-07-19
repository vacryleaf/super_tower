extends Control

var DataCatalog
var PlaySession
var DebugLogger
var UIHelpers
var BattleView
var RewardView
var EquipmentOverlay
var CampView
var SkillShopView
var SkillManageView
var EquipmentManageView
var ItemCollectionView
var EncyclopediaView
var BestiaryView
var ClassDetailView
var PreRunView
var ActionBarView
var CombatLogView
var EquipmentView
var RunHudView
var EndScreenView
var TraitCatalog
var CombatFeedback

@onready var root: VBoxContainer = $Root

var debug_mode := OS.is_debug_build()
var session
var debug_logger
var combat_feedback
var battle_view
var reward_view
var equipment_overlay
var camp_view
var skill_shop_view
var skill_manage_view
var equipment_manage_view
var item_collection_view
var encyclopedia_view
var bestiary_view
var class_detail_view
var pre_run_view
var camp_screen := ""
var selected_class_key := ""
var action_bar_view
var combat_log_view
var equipment_view
var run_hud_view
var end_screen_view
var trait_catalog
var selected_target := 0
var selected_heal_target := -1
var render_queued := false
var input_locked := false
var equipment_open := false
var enemy_card_nodes: Dictionary = {}
var ally_card_nodes: Dictionary = {}
var player_status_node: Control = null
var player_status_labels: Dictionary = {}
var message_label_node: Label = null
var pending_state_label_node: Label = null
var action_buttons: Array[Button] = []
var skill_buttons: Array[Button] = []
var charge_buttons: Array[Button] = []
var log_text_node: RichTextLabel = null


func _ready() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_position(Vector2i(40, 40))
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_title("Super Tower (DEBUG)" if debug_mode else "Super Tower")
	DataCatalog = load("res://scripts/core/data_catalog.gd")
	PlaySession = load("res://scripts/core/play_session.gd")
	DebugLogger = load("res://scripts/core/debug_logger.gd")
	UIHelpers = load("res://scripts/ui/ui_helpers.gd")
	BattleView = load("res://scripts/ui/battle_view.gd")
	RewardView = load("res://scripts/ui/reward_view.gd")
	EquipmentOverlay = load("res://scripts/ui/equipment_overlay.gd")
	CampView = load("res://scripts/ui/camp_view.gd")
	SkillShopView = load("res://scripts/ui/skill_shop_view.gd")
	SkillManageView = load("res://scripts/ui/skill_manage_view.gd")
	EquipmentManageView = load("res://scripts/ui/equipment_manage_view.gd")
	ItemCollectionView = load("res://scripts/ui/item_collection_view.gd")
	EncyclopediaView = load("res://scripts/ui/encyclopedia_view.gd")
	BestiaryView = load("res://scripts/ui/bestiary_view.gd")
	ClassDetailView = load("res://scripts/ui/class_detail_view.gd")
	PreRunView = load("res://scripts/ui/pre_run_view.gd")
	ActionBarView = load("res://scripts/ui/action_bar_view.gd")
	CombatLogView = load("res://scripts/ui/combat_log_view.gd")
	EquipmentView = load("res://scripts/ui/equipment_view.gd")
	RunHudView = load("res://scripts/ui/run_hud_view.gd")
	EndScreenView = load("res://scripts/ui/end_screen_view.gd")
	TraitCatalog = load("res://scripts/core/trait_catalog.gd")
	CombatFeedback = load("res://scripts/ui/combat_feedback.gd")
	_install_default_theme()
	debug_logger = DebugLogger.new()
	debug_logger.configure("main", debug_mode)
	session = PlaySession.new()
	session.debug_mode = debug_mode
	session.debug_logger = debug_logger
	_debug_log("main ready debug_mode=%s" % str(debug_mode))
	battle_view = BattleView.new()
	reward_view = RewardView.new()
	equipment_overlay = EquipmentOverlay.new()
	camp_view = CampView.new()
	skill_shop_view = SkillShopView.new()
	skill_manage_view = SkillManageView.new()
	equipment_manage_view = EquipmentManageView.new()
	item_collection_view = ItemCollectionView.new()
	encyclopedia_view = EncyclopediaView.new()
	bestiary_view = BestiaryView.new()
	class_detail_view = ClassDetailView.new()
	pre_run_view = PreRunView.new()
	action_bar_view = ActionBarView.new()
	combat_log_view = CombatLogView.new()
	equipment_view = EquipmentView.new()
	run_hud_view = RunHudView.new()
	end_screen_view = EndScreenView.new()
	trait_catalog = TraitCatalog.new()
	combat_feedback = CombatFeedback.new(self)
	_debug_log("views initialized")
	_render_menu()


func _unhandled_input(event: InputEvent) -> void:
	if camp_screen == "pre_run" and event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
			get_viewport().set_input_as_handled()
			_on_manage_close()


func _install_default_theme() -> void:
	var font: Font = load("res://fonts/Arial Unicode.ttf")
	if font == null:
		return
	var inherited_theme := Theme.new()
	for type_name in ["Label", "Button", "RichTextLabel", "LineEdit", "TextEdit", "CheckBox", "OptionButton"]:
		inherited_theme.set_font("font", type_name, font)
	theme = inherited_theme


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


func _add_camp_background() -> void:
	_add_fullscreen_background("res://img/营地.png", Color(0.13, 0.12, 0.16))


func _add_battle_background() -> void:
	_add_fullscreen_background("res://img/boss_arena.png", Color(0.18, 0.09, 0.09))


func _add_fullscreen_background(path: String, fallback_color: Color) -> void:
	var texture: Texture2D = UIHelpers.texture_from_png(path) if UIHelpers != null else null
	var bg: Control
	if texture != null:
		var image_bg := TextureRect.new()
		image_bg.texture = texture
		image_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg = image_bg
	else:
		var color_bg := ColorRect.new()
		color_bg.color = fallback_color
		bg = color_bg
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)


func _render_menu() -> void:
	render_queued = false
	_debug_log("render_menu camp_screen=%s" % camp_screen)
	_clear_root()
	if camp_screen != "":
		_render_camp_screen()
		return
	_add_camp_background()
	camp_view.render(root, session, Callable(self, "_label"), Callable(self, "_on_continue_pressed"), Callable(self, "_on_shop_pressed"), Callable(self, "_on_encyclopedia_pressed"), Callable(self, "_on_class_detail"), Callable(self, "_on_pre_run_pressed"), Callable(self, "_on_manage_action"), Callable(self, "_on_bestiary_from_encyclopedia"))


func _render_game() -> void:
	render_queued = false
	_debug_log("render_game phase=%s floor=%d battle=%d message=%s" % [session.phase, session.floor_index, session.battle_index, session.message])
	_clear_root()
	if session.is_boss_battle():
		_add_battle_background()
	run_hud_view.render(root, session, input_locked, Callable(self, "_on_end_run_to_camp_pressed"), Callable(self, "_status_badge"), Callable(self, "_spacer"))
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
		"skill_shop":
			_render_skill_shop()
		"victory":
			_render_end_screen("已通关第 10 层", "你已经完成当前可玩版本的目标。")
		"game_over":
			_render_end_screen("本局结束", session.message)


func _render_battle() -> void:
	_debug_log("render_battle enemies=%d allies=%d" % [session.enemies.size(), session.allies.size()])
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
	enemy_row.alignment = BoxContainer.ALIGNMENT_CENTER
	combat_area.add_child(enemy_row)
	for i in range(session.enemies.size()):
		enemy_row.add_child(_enemy_card(i))

	if not session.allies.is_empty():
		combat_area.add_child(_label("友方", 20))
		var ally_row := HBoxContainer.new()
		ally_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ally_row.alignment = BoxContainer.ALIGNMENT_CENTER
		combat_area.add_child(ally_row)
		for i in range(session.allies.size()):
			ally_row.add_child(_ally_card(i))

	combat_area.add_child(_spacer_vertical())
	pending_state_label_node = _status_badge(_pending_state_text(), 16, Vector2(220, 44))
	combat_area.add_child(pending_state_label_node)

	var bottom_bar := HBoxContainer.new()
	bottom_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	combat_area.add_child(bottom_bar)
	_render_player_status(bottom_bar)
	var equip_button := _action_button("装备", Callable(self, "_on_equipment_toggle_pressed"))
	equip_button.custom_minimum_size = Vector2(74, 46)
	equip_button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
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
	var button: Button = battle_view.enemy_card(
		session,
		index,
		selected_target,
		Callable(self, "_rank_label"),
		Callable(trait_catalog, "labels"),
		Callable(trait_catalog, "tooltip"),
		Callable(self, "_on_enemy_card_pressed")
	)
	enemy_card_nodes[index] = button
	return button


func _enemy_card_text(index: int, selected: String = "") -> String:
	return battle_view.enemy_card_text(session, index, selected, Callable(self, "_rank_label"), Callable(trait_catalog, "labels"))


func _ally_card(index: int) -> Control:
	var button: Button = battle_view.ally_card(
		session,
		index,
		Callable(self, "_rank_label"),
		Callable(trait_catalog, "labels"),
		Callable(trait_catalog, "tooltip")
	)
	ally_card_nodes[index] = button
	return button


func _ally_card_text(index: int) -> String:
	return battle_view.ally_card_text(session, index, Callable(self, "_rank_label"), Callable(trait_catalog, "labels"))


func _render_player_status(parent: Control) -> void:
	var class_data: Dictionary = DataCatalog.CLASSES.get(session.class_id, {})
	var player_class_name := String(class_data.get("name", "角色"))
	var status: Dictionary = battle_view.player_status(session, player_class_name, Callable(self, "_label"), session.class_id)
	player_status_node = status["panel"]
	player_status_labels = status["labels"]
	player_status_node.gui_input.connect(_on_player_status_clicked)
	parent.add_child(player_status_node)


func _render_actions(parent: Control) -> void:
	var controls: Dictionary = action_bar_view.render(
		parent,
		session,
		input_locked,
		Callable(self, "_on_attack_pressed"),
		Callable(self, "_on_defend_pressed"),
		Callable(self, "_on_dodge_pressed"),
		Callable(self, "_on_end_turn_pressed"),
		Callable(self, "_on_skill_pressed"),
		Callable(self, "_on_charge_pressed")
	)
	action_buttons = controls["action_buttons"]
	skill_buttons = controls["skill_buttons"]
	charge_buttons = controls["charge_buttons"]


func _show_equipment_overlay() -> void:
	equipment_overlay.show(self, equipment_view.panel(session, Callable(self, "_label"), Callable(self, "_on_equipment_close_pressed")))


func _on_continue_pressed() -> void:
	_debug_log("continue pressed")
	if session.load_game():
		selected_target = 0
		equipment_open = false
		_request_game_render()


func _on_class_detail(class_key: String) -> void:
	camp_screen = "class_detail:" + class_key
	selected_class_key = class_key
	_request_menu_render()


func _on_end_run_to_camp_pressed() -> void:
	if input_locked:
		return
	_debug_log("end_run_to_camp pressed")
	session.end_run_to_camp()
	selected_target = 0
	equipment_open = false
	input_locked = false
	_request_menu_render()


func _on_equipment_toggle_pressed() -> void:
	equipment_open = not equipment_open
	_debug_log("equipment_toggle open=%s" % str(equipment_open))
	_request_game_render()


func _on_equipment_close_pressed() -> void:
	equipment_open = false
	_request_game_render()


func _on_enemy_card_pressed(index: int) -> void:
	selected_target = index
	selected_heal_target = -1
	_debug_log("enemy_selected index=%d" % index)


func _on_player_status_clicked(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		selected_heal_target = 0
		selected_target = -1
	call_deferred("_refresh_battle_ui")


func _on_attack_pressed() -> void:
	_debug_log("ui_attack target=%d" % selected_target)
	_run_action(Callable(session, "player_attack").bind(selected_target))


func _on_defend_pressed() -> void:
	_debug_log("ui_defend")
	_run_action(Callable(session, "player_defend"))


func _on_dodge_pressed() -> void:
	_debug_log("ui_dodge")
	_run_action(Callable(session, "player_dodge"))


func _on_end_turn_pressed() -> void:
	_debug_log("ui_end_turn")
	_run_action(Callable(session, "end_turn"))


func _on_skill_pressed(index: int) -> void:
	_debug_log("ui_skill slot=%d" % index)
	var skill_id: String = session.player["equipped_skills"][index]
	var skill: Dictionary = DataCatalog.SKILLS.get(skill_id, {})
	if String(skill.get("type", "")) == "heal":
		if selected_heal_target < 0:
			session.message = "请先点击角色面板选择治疗目标。"
			_request_game_render()
			return
		_run_action(Callable(session, "use_skill").bind(index, selected_heal_target))
	else:
		_run_action(Callable(session, "use_skill").bind(index, selected_target))


func _on_charge_pressed(charge_id: String) -> void:
	_debug_log("ui_charge %s" % charge_id)
	_run_action(Callable(session, "use_charge").bind(charge_id))


func _on_reward_pressed(index: int) -> void:
	_debug_log("reward_pressed index=%d" % index)
	session.choose_reward(index)
	_persist_session()
	selected_target = 0
	_request_game_render()


func _on_reward_target_pressed(index: int) -> void:
	_debug_log("reward_target_pressed index=%d" % index)
	session.choose_reward_target(index)
	_persist_session()
	selected_target = 0
	_request_game_render()


func _on_return_to_menu_pressed() -> void:
	_debug_log("return_to_menu pressed")
	session = PlaySession.new()
	session.debug_mode = debug_mode
	session.debug_logger = debug_logger
	_request_menu_render()


func _run_action(action: Callable) -> void:
	if input_locked:
		return
	_debug_log("run_action begin phase=%s" % session.phase)
	input_locked = true
	action.call()
	await combat_feedback.play_action_feedback(session.last_events.duplicate(true), enemy_card_nodes, player_status_node, Callable(self, "_label"))
	input_locked = false
	selected_heal_target = -1
	_debug_log("run_action end phase=%s message=%s" % [session.phase, session.message])
	if session.phase == "battle":
		_refresh_battle_ui()
	else:
		_persist_session()
		_request_game_render()


func _render_reward() -> void:
	reward_view.render_reward(root, session.reward_options, Callable(self, "_on_reward_pressed"), Callable(self, "_label"))


func _render_reward_target() -> void:
	reward_view.render_reward_target(
		root,
		String(session.message),
		session.reward_targets,
		Callable(self, "_on_reward_target_pressed"),
		Callable(self, "_label"),
		Callable(equipment_view, "target_label"),
		Callable(self, "_attachment_summary")
	)


func _render_end_screen(title: String, subtitle: String) -> void:
	end_screen_view.render(root, title, subtitle, Callable(self, "_on_return_to_menu_pressed"), Callable(self, "_label"))


func _render_log(parent: Control) -> void:
	log_text_node = combat_log_view.render(parent, session.battle_log, Callable(self, "_label"))


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
			button.tooltip_text = trait_catalog.tooltip(session.enemies[index]["traits"])
			button.disabled = int(session.enemies[index]["hp"]) <= 0
	for index in ally_card_nodes.keys():
		var ally_button: Button = ally_card_nodes[index]
		if is_instance_valid(ally_button) and index < session.allies.size():
			ally_button.text = _ally_card_text(int(index))
			ally_button.tooltip_text = trait_catalog.tooltip(session.allies[index]["traits"])
			ally_button.disabled = int(session.allies[index]["hp"]) <= 0
	if player_status_labels.has("action"):
		player_status_labels["action"].text = "能量 %d/%d" % [session.energy, DataCatalog.ENERGY_MAX]
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
	if player_status_node != null and is_instance_valid(player_status_node):
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.12, 0.40, 0.18, 0.85) if selected_heal_target == 0 else Color(0.15, 0.15, 0.15, 0.85)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = Color(0.35, 0.85, 0.55, 1) if selected_heal_target == 0 else Color(0.3, 0.3, 0.3, 1)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		player_status_node.add_theme_stylebox_override("panel", style)
	if pending_state_label_node != null and is_instance_valid(pending_state_label_node):
		pending_state_label_node.text = _pending_state_text()
	_refresh_action_buttons()
	combat_log_view.refresh(log_text_node, session.battle_log)


func _refresh_action_buttons() -> void:
	action_bar_view.refresh(session, input_locked, action_buttons, skill_buttons, charge_buttons)


func _pending_state_text() -> String:
	if session.pending_state_card == "":
		return "状态 Buff：无"
	return "状态 Buff：%s" % DataCatalog.STATE_CARDS[session.pending_state_card]["name"]


func _persist_session() -> void:
	_debug_log("persist_session phase=%s floor=%d battle=%d" % [session.phase, session.floor_index, session.battle_index])
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


func _rank_label(rank: String) -> String:
	match rank:
		"normal":
			return "普通"
		"elite":
			return "精英"
		"boss":
			return "首领"
	return rank


func _debug_log(message: String) -> void:
	if debug_logger != null and debug_mode and debug_logger.has_method("log"):
		debug_logger.log(message)


func _on_shop_pressed() -> void:
	session.phase = "skill_shop"
	_request_game_render()


func _render_skill_shop() -> void:
	skill_shop_view.render(root, session, Callable(self, "_label"), Callable(self, "_on_buy_skill"), Callable(self, "_on_skill_shop_back"))


func _on_buy_skill(skill_id: String) -> void:
	session.buy_common_skill(skill_id)
	_clear_root()
	_render_skill_shop()


func _on_skill_shop_back() -> void:
	_request_menu_render()


func _render_camp_screen() -> void:
	var parts := camp_screen.split(":")
	var screen_type := parts[0]
	var class_key := parts[1] if parts.size() > 1 else ""
	var roster_player := _get_roster_player(class_key) if class_key != "" else {}
	match screen_type:
		"class_detail":
			class_detail_view.render(root, class_key, roster_player, Callable(self, "_label"), Callable(self, "_on_manage_action"), Callable(self, "_on_manage_close"))
		"skill_manage":
			skill_manage_view.render(root, class_key, roster_player, Callable(self, "_label"), Callable(self, "_on_skill_toggle"), Callable(self, "_on_manage_close"))
		"equipment_manage":
			equipment_manage_view.render(root, class_key, roster_player, Callable(self, "_label"), Callable(self, "_on_equipment_swap"), Callable(self, "_on_manage_close"))
		"item_collection":
			item_collection_view.render(root, class_key, roster_player, Callable(self, "_label"), Callable(self, "_on_manage_close"))
		"encyclopedia":
			encyclopedia_view.render(root, Callable(self, "_label"), Callable(self, "_on_manage_close"), Callable(self, "_on_bestiary_from_encyclopedia"))
		"bestiary":
			bestiary_view.render(root, Callable(self, "_label"), Callable(self, "_on_bestiary_back"), session.get_bestiary())
		"pre_run":
			pre_run_view.render(root, session, Callable(self, "_label"), Callable(self, "_on_pre_run_action"), Callable(self, "_on_manage_close"))


func _on_manage_action(action: String, class_key: String) -> void:
	camp_screen = action + ":" + class_key
	selected_class_key = class_key
	equipment_manage_view.selected_slot = ""
	_request_menu_render()


func _on_pre_run_pressed() -> void:
	pre_run_view.reset()
	camp_screen = "pre_run"
	_request_menu_render()


func _on_pre_run_action(action: String, arg: String) -> void:
	if action == "select_class":
		pre_run_view.selected_class = arg
		pre_run_view.browse_mode = "equipment"
		pre_run_view.selected_equipment_tab = "head"
		pre_run_view.selected_equipment_slot = "head"
		pre_run_view.selected_skill_filter = "skill_1"
		pre_run_view.selected_consumable_slot = 1
		pre_run_view.floor_menu_open = false
		pre_run_view.hover_kind = ""
		pre_run_view.hover_id = ""
		pre_run_view.hover_slot = ""
		var roster: Dictionary = session.get_roster_player(arg)
		if roster.is_empty() and session.simulator != null:
			roster = session.simulator.create_character(arg)
		pre_run_view.start_floor = maxi(1, int(roster.get("highest_floor", 0)) - 3)
	elif action == "focus_equipment_slot":
		pre_run_view.browse_mode = "equipment"
		pre_run_view.selected_equipment_slot = arg
		pre_run_view.selected_equipment_tab = "ring" if arg.begins_with("ring") else arg
		pre_run_view.floor_menu_open = false
		pre_run_view.hover_kind = ""
	elif action == "focus_skill_filter":
		pre_run_view.browse_mode = "skills"
		pre_run_view.selected_skill_filter = arg
		pre_run_view.floor_menu_open = false
		pre_run_view.hover_kind = ""
	elif action == "focus_consumable_slot":
		pre_run_view.browse_mode = "consumable"
		pre_run_view.selected_equipment_tab = "consumable"
		pre_run_view.selected_consumable_slot = maxi(1, int(arg))
		pre_run_view.floor_menu_open = false
		pre_run_view.hover_kind = ""
	elif action == "hover_equipment":
		var parts := arg.split("|")
		if parts.size() >= 2:
			pre_run_view.hover_kind = "equipment"
			pre_run_view.hover_slot = pre_run_view.selected_equipment_slot if pre_run_view.selected_equipment_slot != "" else String(parts[0])
			pre_run_view.hover_id = String(parts[1])
	elif action == "hover_skill":
		pre_run_view.hover_kind = "skill"
		pre_run_view.hover_slot = ""
		pre_run_view.hover_id = arg
	elif action == "hover_consumable":
		pre_run_view.hover_kind = "consumable"
		pre_run_view.hover_slot = ""
		pre_run_view.hover_id = arg
	elif action == "equip_item":
		if pre_run_view.selected_class != "" and arg != "":
			var slot: String = pre_run_view.selected_equipment_slot
			if slot == "":
				slot = pre_run_view.selected_equipment_tab
			session.swap_equipment(pre_run_view.selected_class, slot, arg)
	elif action == "equip_skill":
		if pre_run_view.selected_class != "" and pre_run_view.selected_skill_filter.begins_with("skill_"):
			var slot_index := int(pre_run_view.selected_skill_filter.replace("skill_", ""))
			session.set_skill_slot(pre_run_view.selected_class, slot_index, arg)
	elif action == "equip_consumable":
		if pre_run_view.selected_class != "" and arg != "":
			session.set_consumable_slot(pre_run_view.selected_class, pre_run_view.selected_consumable_slot, arg)
	elif action == "select_floor":
		pre_run_view.start_floor = maxi(1, int(arg))
		pre_run_view.floor_menu_open = false
	elif action == "toggle_floor_menu":
		pass
	elif action == "start_game":
		if pre_run_view.selected_class == "":
			_request_menu_render()
			return
		session.start_new_game(pre_run_view.selected_class, pre_run_view.start_floor)
		pre_run_view.reset()
		camp_screen = ""
		selected_target = 0
		_request_game_render()
		return
	_request_menu_render()


func _on_encyclopedia_pressed() -> void:
	camp_screen = "encyclopedia"
	_request_menu_render()


func _on_bestiary_from_encyclopedia() -> void:
	camp_screen = "bestiary"
	_request_menu_render()


func _on_bestiary_back() -> void:
	camp_screen = "encyclopedia"
	_request_menu_render()


func _on_manage_close() -> void:
	camp_screen = ""
	equipment_manage_view.selected_slot = ""
	pre_run_view.reset()
	_request_menu_render()


func _on_skill_toggle(class_key: String, slot: int, skill_id: String) -> void:
	session.set_skill_slot(class_key, slot, skill_id)
	_render_camp_screen()


func _on_equipment_swap(class_key: String, slot: String, item_id: String) -> void:
	session.swap_equipment(class_key, slot, item_id)
	_render_camp_screen()


func _get_roster_player(class_key: String) -> Dictionary:
	return session.get_roster_player(class_key)



func _attachment_summary(target_type: String, target_id: String) -> String:
	return equipment_view.attachment_summary(session, target_type, target_id)
