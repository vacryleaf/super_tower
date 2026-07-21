extends RefCounted
class_name CampView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const TraitCatalog = preload("res://scripts/core/trait_catalog.gd")
const UIHelpers = preload("res://scripts/ui/ui_helpers.gd")

var _label_factory: Callable
var _manage_callback: Callable
var _bestiary_callback: Callable
var _session: Variant
var _detail_container: Control
var _left_container: Control
var _class_section: Control
var _encyclopedia_section: Control
var _class_buttons: Array[Button] = []
var _class_keys: Array[String] = []
var _encyclopedia_buttons: Array[Button] = []
var _class_visible := false
var _encyclopedia_visible := false
var _profession_button: Button
var _encyclopedia_button: Button


func render(
	root: Control,
	session: Variant,
	label_factory: Callable,
	continue_callback: Callable,
	shop_callback: Callable,
	encyclopedia_callback: Callable,
	class_detail_callback: Callable,
	pre_run_callback: Callable,
	manage_callback: Callable,
	bestiary_callback: Callable
) -> void:
	_label_factory = label_factory
	_manage_callback = manage_callback
	_bestiary_callback = bestiary_callback
	_session = session
	_class_buttons.clear()
	_class_keys.clear()
	_encyclopedia_buttons.clear()
	_class_visible = false
	_encyclopedia_visible = false

	root.add_child(label_factory.call("营地", 30))

	if session.has_active_run():
		var continue_button := Button.new()
		continue_button.text = "继续作战"
		continue_button.custom_minimum_size = Vector2(190, 46)
		continue_button.pressed.connect(continue_callback)
		root.add_child(continue_button)

	root.add_child(label_factory.call("塔币：%d" % session.tower_coins, 18))

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	_render_left_panel(body)
	_render_detail_panel(body)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var bottom_row := HBoxContainer.new()
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(bottom_row)

	if session.is_shop_unlocked():
		var shop_button := Button.new()
		shop_button.text = "技能商人"
		shop_button.custom_minimum_size = Vector2(160, 44)
		shop_button.pressed.connect(shop_callback)
		bottom_row.add_child(shop_button)

	var pre_run_button := Button.new()
	pre_run_button.text = "爬塔"
	pre_run_button.custom_minimum_size = Vector2(180, 54)
	pre_run_button.pressed.connect(pre_run_callback)
	bottom_row.add_child(pre_run_button)


func _render_left_panel(parent: Control) -> void:
	_left_container = VBoxContainer.new()
	_left_container.custom_minimum_size = Vector2(180, 0)
	_left_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(_left_container)

	# 职业
	_profession_button = Button.new()
	_profession_button.text = "职业"
	_profession_button.custom_minimum_size = Vector2(160, 40)
	_profession_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_profession_button.pressed.connect(_toggle_class_list)
	_left_container.add_child(_profession_button)

	_class_section = VBoxContainer.new()
	_left_container.add_child(_class_section)

	# 百科
	_encyclopedia_button = Button.new()
	_encyclopedia_button.text = "百科"
	_encyclopedia_button.custom_minimum_size = Vector2(160, 40)
	_encyclopedia_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_encyclopedia_button.flat = true
	_encyclopedia_button.pressed.connect(_toggle_encyclopedia)
	_left_container.add_child(_encyclopedia_button)

	_encyclopedia_section = VBoxContainer.new()
	_left_container.add_child(_encyclopedia_section)


func _toggle_class_list() -> void:
	_class_visible = not _class_visible
	_profession_button.flat = not _class_visible
	if _class_visible:
		_encyclopedia_visible = false
		_encyclopedia_button.flat = true
		_refresh_encyclopedia_section()
	_refresh_class_section()


func _toggle_encyclopedia() -> void:
	_encyclopedia_visible = not _encyclopedia_visible
	_encyclopedia_button.flat = not _encyclopedia_visible
	if _encyclopedia_visible:
		_class_visible = false
		_profession_button.flat = true
		_refresh_class_section()
	_refresh_encyclopedia_section()


func _refresh_class_section() -> void:
	for child in _class_section.get_children():
		child.queue_free()
	_class_buttons.clear()
	_class_keys.clear()

	if not _class_visible:
		return

	for class_key in DataCatalog.CLASSES.keys():
		var data: Dictionary = DataCatalog.CLASSES[class_key]
		var btn := Button.new()
		btn.text = "  " + data["name"]
		btn.custom_minimum_size = Vector2(160, 40)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.flat = true
		btn.pressed.connect(_on_class_button_pressed.bind(class_key))
		_class_buttons.append(btn)
		_class_keys.append(class_key)
		_class_section.add_child(btn)


func _refresh_encyclopedia_section() -> void:
	for child in _encyclopedia_section.get_children():
		child.queue_free()
	_encyclopedia_buttons.clear()

	if not _encyclopedia_visible:
		return

	for i in range(UIHelpers.CATEGORIES.size()):
		var cat: Array = UIHelpers.CATEGORIES[i]
		var btn := Button.new()
		btn.text = "  " + cat[0]
		btn.custom_minimum_size = Vector2(160, 40)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.flat = true
		btn.pressed.connect(_on_encyclopedia_category_pressed.bind(i))
		_encyclopedia_buttons.append(btn)
		_encyclopedia_section.add_child(btn)


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

	_detail_container.add_child(_label_factory.call("请从左侧选择职业或百科", 16))


func _on_class_button_pressed(class_key: String) -> void:
	_clear_detail()
	for i in range(_class_buttons.size()):
		_class_buttons[i].flat = (_class_keys[i] != class_key)
	for btn in _encyclopedia_buttons:
		btn.flat = true

	var data: Dictionary = DataCatalog.CLASSES[class_key]
	var roster_player: Dictionary = _session.get_roster_player(class_key)

	_detail_container.add_child(UIHelpers.avatar_for(class_key))
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


func _on_encyclopedia_category_pressed(index: int) -> void:
	_clear_detail()
	for i in range(_encyclopedia_buttons.size()):
		_encyclopedia_buttons[i].flat = (i != index)
	for btn in _class_buttons:
		btn.flat = true

	var cat_id: String = UIHelpers.CATEGORIES[index][1]
	if cat_id == "bestiary":
		_detail_container.add_child(_label_factory.call("怪物图鉴", 22))
		var btn := Button.new()
		btn.text = "进入怪物图鉴"
		btn.custom_minimum_size = Vector2(200, 44)
		btn.pressed.connect(_bestiary_callback)
		_detail_container.add_child(btn)
		return

	match cat_id:
		"state_cards":
			_render_state_cards()
		"set_effects":
			_render_set_effects()
		"skills":
			_render_skills()
		"classes":
			_render_class_info()
		"traits":
			_render_traits()


func _clear_detail() -> void:
	for child in _detail_container.get_children():
		child.queue_free()


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


# === 百科内容渲染 ===

func _render_state_cards() -> void:
	_detail_container.add_child(_label_factory.call("状态卡 Buff", 22))
	var tag_explain := {
		"numeric": "数值类：提升所有数值效果",
		"attack": "攻击类：仅提升攻击效果",
		"dodge": "闪避类：仅提升闪避效果",
		"defense": "防御类：仅提升防御效果",
		"hybrid": "混合类：攻击后附加小格挡，未攻击则不减行动力"
	}
	for card_id in DataCatalog.STATE_CARDS.keys():
		var card: Dictionary = DataCatalog.STATE_CARDS[card_id]
		var tag := String(card.get("tag", ""))
		var text := "%s（权重：%d，倍率：x%.2f）" % [card["name"], int(card["weight"]), float(card["multiplier"])]
		_detail_container.add_child(_label_factory.call(text, 15))
		_detail_container.add_child(_label_factory.call("  %s" % tag_explain.get(tag, ""), 13))


func _render_set_effects() -> void:
	_detail_container.add_child(_label_factory.call("套装效果", 22))
	for set_id in DataCatalog.EQUIPMENT_SETS.keys():
		var set_data: Dictionary = DataCatalog.EQUIPMENT_SETS[set_id]
		_detail_container.add_child(_label_factory.call(set_data["name"], 18))
		var bonuses: Dictionary = set_data.get("bonuses", {})
		for threshold in bonuses.keys():
			var bonus: Dictionary = bonuses[threshold]
			_detail_container.add_child(_label_factory.call("  %d 件套：%s" % [int(threshold), String(bonus.get("label", ""))], 14))


func _render_skills() -> void:
	_detail_container.add_child(_label_factory.call("技能", 22))
	_detail_container.add_child(_label_factory.call("先天技能（所有职业通用）：", 16))
	for skill_id in DataCatalog.INNATE_SKILLS.keys():
		var skill: Dictionary = DataCatalog.INNATE_SKILLS[skill_id]
		_detail_container.add_child(_label_factory.call("  %s - %s，费用 %d" % [skill["name"], UIHelpers.skill_type_name(skill), int(skill["cost"])], 14))
	_detail_container.add_child(_label_factory.call("职业技能与通用技能：", 16))
	for skill_id in DataCatalog.SKILLS.keys():
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		var cls_name := String(skill.get("class", ""))
		var class_label := ""
		match cls_name:
			"warrior":
				class_label = "战士"
			"archer":
				class_label = "弓箭手"
			"common":
				class_label = "通用"
		_detail_container.add_child(_label_factory.call("  %s [%s] - %s，费用 %d" % [skill["name"], class_label, UIHelpers.skill_type_name(skill), int(skill["cost"])], 14))


func _render_class_info() -> void:
	_detail_container.add_child(_label_factory.call("职业", 22))
	for class_id in DataCatalog.CLASSES.keys():
		var data: Dictionary = DataCatalog.CLASSES[class_id]
		var resource_name := "怒气" if data.get("resource", "") == "rage" else "专注"
		var text := "%s：HP %d，攻击 %d，护甲 %d，格挡 %d，资源：%s" % [
			data["name"], int(data["max_hp"]), int(data["base_attack"]), int(data["base_defense"]), int(data.get("base_block", 1)), resource_name
		]
		_detail_container.add_child(_label_factory.call(text, 15))


func _render_traits() -> void:
	_detail_container.add_child(_label_factory.call("被动技能", 22))
	var all_traits: Array[String] = []
	for trait_id in TraitCatalog.LABELS.keys():
		all_traits.append(String(trait_id))
	all_traits.sort()
	for trait_id in all_traits:
		var label_text := "%s：%s" % [TraitCatalog.LABELS.get(trait_id, trait_id), TraitCatalog.DESCRIPTIONS.get(trait_id, "暂无说明。")]
		_detail_container.add_child(_label_factory.call(label_text, 14))




