extends Control

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const PlaySession = preload("res://scripts/core/play_session.gd")
const BattleView = preload("res://scripts/ui/battle_view.gd")
const RewardView = preload("res://scripts/ui/reward_view.gd")
const EquipmentOverlay = preload("res://scripts/ui/equipment_overlay.gd")
const CampView = preload("res://scripts/ui/camp_view.gd")
const SkillShopView = preload("res://scripts/ui/skill_shop_view.gd")
const SkillManageView = preload("res://scripts/ui/skill_manage_view.gd")
const EquipmentManageView = preload("res://scripts/ui/equipment_manage_view.gd")
const ItemCollectionView = preload("res://scripts/ui/item_collection_view.gd")
const EncyclopediaView = preload("res://scripts/ui/encyclopedia_view.gd")
const ClassDetailView = preload("res://scripts/ui/class_detail_view.gd")
const PreRunView = preload("res://scripts/ui/pre_run_view.gd")
const ActionBarView = preload("res://scripts/ui/action_bar_view.gd")
const CombatLogView = preload("res://scripts/ui/combat_log_view.gd")
const EquipmentView = preload("res://scripts/ui/equipment_view.gd")
const RunHudView = preload("res://scripts/ui/run_hud_view.gd")
const EndScreenView = preload("res://scripts/ui/end_screen_view.gd")
const TraitCatalog = preload("res://scripts/core/trait_catalog.gd")

const CombatFeedback = preload("res://scripts/ui/combat_feedback.gd")

@onready var root: VBoxContainer = $Root

var session := PlaySession.new()
var combat_feedback := CombatFeedback.new(self)
var battle_view: BattleView = BattleView.new()
var reward_view: RewardView = RewardView.new()
var equipment_overlay: EquipmentOverlay = EquipmentOverlay.new()
var camp_view: CampView = CampView.new()
var skill_shop_view: SkillShopView = SkillShopView.new()
var skill_manage_view: SkillManageView = SkillManageView.new()
var equipment_manage_view: EquipmentManageView = EquipmentManageView.new()
var item_collection_view: ItemCollectionView = ItemCollectionView.new()
var encyclopedia_view: EncyclopediaView = EncyclopediaView.new()
var class_detail_view: ClassDetailView = ClassDetailView.new()
var pre_run_view: PreRunView = PreRunView.new()
var camp_screen := ""
var selected_class_key := ""
var action_bar_view: ActionBarView = ActionBarView.new()
var combat_log_view: CombatLogView = CombatLogView.new()
var equipment_view: EquipmentView = EquipmentView.new()
var run_hud_view: RunHudView = RunHudView.new()
var end_screen_view: EndScreenView = EndScreenView.new()
var trait_catalog: TraitCatalog = TraitCatalog.new()
var selected_target := 0
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
	if camp_screen != "":
		_render_camp_screen()
		return
	camp_view.render(root, session, Callable(self, "_label"), Callable(self, "_on_continue_pressed"), Callable(self, "_on_shop_pressed"), Callable(self, "_on_encyclopedia_pressed"), Callable(self, "_on_class_detail"), Callable(self, "_on_pre_run_pressed"))


func _render_game() -> void:
	render_queued = false
	_clear_root()
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
	var status: Dictionary = battle_view.player_status(session, DataCatalog.CLASSES[session.class_id]["name"], Callable(self, "_label"))
	player_status_node = status["panel"]
	player_status_labels = status["labels"]
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
	session.end_run_to_camp()
	selected_target = 0
	equipment_open = false
	input_locked = false
	_request_menu_render()


func _on_equipment_toggle_pressed() -> void:
	equipment_open = not equipment_open
	_request_game_render()


func _on_equipment_close_pressed() -> void:
	equipment_open = false
	_request_game_render()


func _on_enemy_card_pressed(index: int) -> void:
	selected_target = index
	call_deferred("_refresh_battle_ui")


func _on_attack_pressed() -> void:
	_run_action(Callable(session, "player_attack").bind(selected_target))


func _on_defend_pressed() -> void:
	_run_action(Callable(session, "player_defend"))


func _on_dodge_pressed() -> void:
	_run_action(Callable(session, "player_dodge"))


func _on_end_turn_pressed() -> void:
	_run_action(Callable(session, "end_turn"))


func _on_skill_pressed(index: int) -> void:
	_run_action(Callable(session, "use_skill").bind(index, selected_target))


func _on_charge_pressed(charge_id: String) -> void:
	_run_action(Callable(session, "use_charge").bind(charge_id))


func _on_reward_pressed(index: int) -> void:
	session.choose_reward(index)
	_persist_session()
	selected_target = 0
	_request_game_render()


func _on_reward_target_pressed(index: int) -> void:
	session.choose_reward_target(index)
	_persist_session()
	selected_target = 0
	_request_game_render()


func _on_return_to_menu_pressed() -> void:
	session = PlaySession.new()
	_request_menu_render()


func _run_action(action: Callable) -> void:
	if input_locked:
		return
	input_locked = true
	action.call()
	await combat_feedback.play_action_feedback(session.last_events.duplicate(true), enemy_card_nodes, player_status_node, Callable(self, "_label"))
	input_locked = false
	_persist_session()
	if session.phase == "battle":
		_refresh_battle_ui()
	else:
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
	combat_log_view.refresh(log_text_node, session.battle_log)


func _refresh_action_buttons() -> void:
	action_bar_view.refresh(session, input_locked, action_buttons, skill_buttons, charge_buttons)


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


func _rank_label(rank: String) -> String:
	match rank:
		"normal":
			return "普通"
		"elite":
			return "精英"
		"boss":
			return "首领"
	return rank

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
			encyclopedia_view.render(root, Callable(self, "_label"), Callable(self, "_on_manage_close"))
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
	match action:
		"select_class":
			pre_run_view.selected_class = arg
			pre_run_view.step = 1
		"next_step":
			pre_run_view.step = mini(4, pre_run_view.step + 1)
		"prev_step":
			pre_run_view.step = maxi(0, pre_run_view.step - 1)
			if pre_run_view.step == 0:
				pre_run_view.selected_class = ""
		"start_game":
			session.start_new_game(pre_run_view.selected_class, pre_run_view.start_floor)
			pre_run_view.reset()
			camp_screen = ""
			_persist_session()
			selected_target = 0
			_request_game_render()
			return
	_request_menu_render()


func _on_encyclopedia_pressed() -> void:
	camp_screen = "encyclopedia"
	_request_menu_render()


func _on_manage_close() -> void:
	camp_screen = ""
	equipment_manage_view.selected_slot = ""
	pre_run_view.reset()
	_request_menu_render()


func _on_skill_toggle(class_key: String, skill_id: String) -> void:
	var profile := session.save_profile.read_profile(Callable(session, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	if not roster.has(class_key):
		return
	var player: Dictionary = roster[class_key]
	var equipped: Array = player.get("equipped_skills", [])
	if equipped.has(skill_id):
		equipped.erase(skill_id)
	elif equipped.size() < 4:
		equipped.append(skill_id)
	player["equipped_skills"] = equipped
	roster[class_key] = player
	profile["roster"] = roster
	session.save_profile.write_profile(profile)
	_render_camp_screen()


func _on_equipment_swap(class_key: String, slot: String, item_id: String) -> void:
	var profile := session.save_profile.read_profile(Callable(session, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	if not roster.has(class_key):
		return
	var player: Dictionary = roster[class_key]
	var equipment: Dictionary = player.get("equipment", {})
	var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
	var item_slot := String(item.get("slot", ""))
	var target_slot := slot
	if item_slot == "ring" and slot == "ring" and equipment.has("ring"):
		target_slot = "ring2"
	var previous := String(equipment.get(target_slot, ""))
	var displaced_slot := ""
	for existing_slot in equipment.keys():
		if String(equipment[existing_slot]) == item_id:
			displaced_slot = existing_slot
			break
	if displaced_slot != "":
		if previous != "":
			equipment[displaced_slot] = previous
		else:
			equipment.erase(displaced_slot)
	else:
		equipment[target_slot] = item_id
	player["equipment"] = equipment
	roster[class_key] = player
	profile["roster"] = roster
	session.save_profile.write_profile(profile)
	_render_camp_screen()


func _get_roster_player(class_key: String) -> Dictionary:
	return session.get_roster_player(class_key)



func _attachment_summary(target_type: String, target_id: String) -> String:
	return equipment_view.attachment_summary(session, target_type, target_id)
