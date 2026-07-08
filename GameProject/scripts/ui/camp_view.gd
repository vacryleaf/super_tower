extends RefCounted
class_name CampView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

var _label_factory: Callable
var _manage_callback: Callable
var _session: Variant
var _detail_container: Control
var _class_buttons: Array[Button] = []
var _class_keys: Array[String] = []


func render(
	root: Control,
	session: Variant,
	label_factory: Callable,
	continue_callback: Callable,
	shop_callback: Callable,
	encyclopedia_callback: Callable,
	class_detail_callback: Callable,
	pre_run_callback: Callable,
	manage_callback: Callable
) -> void:
	_label_factory = label_factory
	_manage_callback = manage_callback
	_session = session
	_class_buttons.clear()
	_class_keys.clear()

	root.add_child(label_factory.call("塔下营地", 30))
	root.add_child(label_factory.call("可玩版本：新手引导、手动战斗、奖励选择、装备、技能和 1-10 层流程。", 16))

	if session.has_active_run():
		var continue_button := Button.new()
		continue_button.text = "继续当前派遣"
		continue_button.custom_minimum_size = Vector2(190, 46)
		continue_button.pressed.connect(continue_callback)
		root.add_child(continue_button)

	root.add_child(label_factory.call("塔币：%d" % session.tower_coins, 18))

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	_render_class_list(body)
	_render_detail_panel(body)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var bottom_row := HBoxContainer.new()
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(bottom_row)

	var util_row := HBoxContainer.new()
	util_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bottom_row.add_child(util_row)

	if _is_shop_unlocked(session):
		var shop_button := Button.new()
		shop_button.text = "技能商人"
		shop_button.custom_minimum_size = Vector2(160, 44)
		shop_button.pressed.connect(shop_callback)
		util_row.add_child(shop_button)
	var encyclopedia_button := Button.new()
	encyclopedia_button.text = "百科"
	encyclopedia_button.custom_minimum_size = Vector2(160, 44)
	encyclopedia_button.pressed.connect(encyclopedia_callback)
	util_row.add_child(encyclopedia_button)

	var pre_run_button := Button.new()
	pre_run_button.text = "爬塔"
	pre_run_button.custom_minimum_size = Vector2(180, 54)
	pre_run_button.pressed.connect(pre_run_callback)
	bottom_row.add_child(pre_run_button)

	if not _class_keys.is_empty():
		_select_class(_class_keys[0])


func _render_class_list(parent: Control) -> void:
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(140, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(left)

	left.add_child(_label_factory.call("职业", 18))

	for class_key in DataCatalog.CLASSES.keys():
		var data: Dictionary = DataCatalog.CLASSES[class_key]
		var btn := Button.new()
		btn.text = data["name"]
		btn.custom_minimum_size = Vector2(120, 40)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_class_button_pressed.bind(class_key))
		_class_buttons.append(btn)
		_class_keys.append(class_key)
		left.add_child(btn)


func _render_detail_panel(parent: Control) -> void:
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(right)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)

	_detail_container = VBoxContainer.new()
	_detail_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_detail_container)

	_detail_container.add_child(_label_factory.call("请从左侧选择职业", 16))


func _on_class_button_pressed(class_key: String) -> void:
	_select_class(class_key)


func _select_class(class_key: String) -> void:
	for i in range(_class_buttons.size()):
		_class_buttons[i].flat = (_class_keys[i] != class_key)

	for child in _detail_container.get_children():
		child.queue_free()

	var data: Dictionary = DataCatalog.CLASSES[class_key]
	var roster_player: Dictionary = _session.get_roster_player(class_key)

	_detail_container.add_child(_avatar_for(class_key))
	_detail_container.add_child(_label_factory.call(String(data["name"]), 24))
	_detail_container.add_child(_label_factory.call("生命%d  攻击%d  护甲%d  格挡%d" % [
		int(data["max_hp"]), int(data["base_attack"]), int(data["base_defense"]), int(data.get("base_block", 1))
	], 16))

	if roster_player.is_empty():
		_detail_container.add_child(_label_factory.call("该职业尚未招募。", 14))
		return

	var highest_floor := int(roster_player.get("highest_floor", 0))
	_detail_container.add_child(_label_factory.call("最高记录：第 %d 层" % highest_floor, 16))

	_render_skill_summary(roster_player)
	_render_equipment_summary(roster_player)

	_detail_container.add_child(_label_factory.call("", 10))

	var mgmt_row := HBoxContainer.new()
	mgmt_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	for action in [["技能管理", "skill_manage"], ["装备管理", "equipment_manage"], ["物品查看", "item_collection"]]:
		var btn := Button.new()
		btn.text = action[0]
		btn.custom_minimum_size = Vector2(100, 40)
		btn.pressed.connect(func(): _manage_callback.call(action[1], class_key))
		mgmt_row.add_child(btn)
	_detail_container.add_child(mgmt_row)


func _render_skill_summary(roster_player: Dictionary) -> void:
	var equipped: Array = roster_player.get("equipped_skills", [])
	var unlocked: Array = roster_player.get("unlocked_skills", [])
	_detail_container.add_child(_label_factory.call("已装备技能：%d/4" % equipped.size(), 16))
	if equipped.is_empty():
		_detail_container.add_child(_label_factory.call("  未装备任何技能", 14))
	else:
		for skill_id in equipped:
			if DataCatalog.SKILLS.has(skill_id):
				var skill: Dictionary = DataCatalog.SKILLS[skill_id]
				_detail_container.add_child(_label_factory.call("  %s" % skill["name"], 14))
	_detail_container.add_child(_label_factory.call("已解锁技能：%d 个" % unlocked.size(), 14))


func _render_equipment_summary(roster_player: Dictionary) -> void:
	var equipment: Dictionary = roster_player.get("equipment", {})
	var equipment_ids: Array = roster_player.get("equipment_ids", [])
	_detail_container.add_child(_label_factory.call("已装备：%d 件 / 已收集：%d 件" % [equipment.size(), equipment_ids.size()], 16))


func _avatar_for(class_key: String) -> TextureRect:
	var path := "res://img/warrior.png" if class_key == "warrior" else "res://img/archer.png"
	var avatar := TextureRect.new()
	avatar.texture = load(path)
	avatar.custom_minimum_size = Vector2(64, 64)
	avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	return avatar


func _is_shop_unlocked(session: Variant) -> bool:
	var profile = session.save_profile.read_profile(Callable(session, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	for class_key in roster.keys():
		if int(roster[class_key].get("highest_floor", 0)) >= 10:
			return true
	return false