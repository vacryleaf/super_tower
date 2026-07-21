extends RefCounted
class_name PreRunView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const UIHelpers = preload("res://scripts/ui/ui_helpers.gd")

const CLASS_ORDER := ["warrior", "archer"]
const CLASS_CARD_SIZE := Vector2(150, 210)
const EQUIPMENT_SLOT_SIZE := Vector2(58, 58)
const SKILL_SLOT_SIZE := Vector2(62, 62)
const WAREHOUSE_CELL_SIZE := Vector2(86, 118)
const DESIGN_VIEWPORT_SIZE := Vector2(1280, 720)

var selected_class := ""
var start_floor := 1
var floor_menu_open := false
var browse_mode := "equipment"
var selected_equipment_tab := "head"
var selected_equipment_slot := "head"
var selected_skill_filter := "skill_1"
var selected_consumable_slot := 1
var hover_kind := ""
var hover_id := ""
var hover_slot := ""
var tooltip_panel: Control = null
var skill_popup: Control = null
var layout_scale := 1.0


func reset() -> void:
	selected_class = ""
	start_floor = 1
	floor_menu_open = false
	browse_mode = "equipment"
	selected_equipment_tab = "head"
	selected_equipment_slot = "head"
	selected_skill_filter = "skill_1"
	selected_consumable_slot = 1
	hover_kind = ""
	hover_id = ""
	hover_slot = ""


func render(root: Control, session: Variant, label_factory: Callable, action_callback: Callable, close_callback: Callable) -> void:
	_hide_tooltip()
	_hide_skill_popup()
	layout_scale = _layout_scale(root)
	var outer := VBoxContainer.new()
	outer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(outer)

	outer.add_child(_build_header(label_factory, close_callback))

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	outer.add_child(body)

	body.add_child(_build_class_column(session, label_factory, action_callback))
	if selected_class != "":
		body.add_child(_build_loadout_column(session, label_factory, action_callback))
		body.add_child(_build_warehouse_column(session, label_factory, action_callback))


func _build_header(label_factory: Callable, close_callback: Callable) -> Control:
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var title: Label = label_factory.call("准备", 26)
	_configure_nowrap_label(title, 150)
	header.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close_button := Button.new()
	close_button.text = "X"
	close_button.custom_minimum_size = _scaled_size(Vector2(36, 36))
	close_button.pressed.connect(close_callback)
	header.add_child(close_button)
	return header


func _build_class_column(session: Variant, label_factory: Callable, action_callback: Callable) -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size = _scaled_size(Vector2(176, 0)) if selected_class != "" else Vector2(0, 0)
	column.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN if selected_class != "" else Control.SIZE_EXPAND_FILL
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL

	if selected_class != "":
		column.add_child(_build_selected_class_card(session, label_factory))
		return column

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	var list := HBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	for class_key in CLASS_ORDER:
		list.add_child(_build_class_card(session, class_key, label_factory, action_callback, false))

	return column


func _build_selected_class_card(session: Variant, label_factory: Callable) -> Control:
	var roster := _player_snapshot(session, selected_class)
	var data: Dictionary = DataCatalog.CLASSES[selected_class]
	var card := Button.new()
	card.text = ""
	card.disabled = true
	_lock_proportional_size(card, _scaled_size(CLASS_CARD_SIZE))
	_apply_card_style(card, true, false)
	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	card.add_child(inner)
	inner.add_child(UIHelpers.avatar_for(selected_class))
	inner.add_child(label_factory.call(String(data["name"]), 20))
	inner.add_child(label_factory.call("生命 %d  攻击 %d  护甲 %d  格挡 %d" % [
		int(data["max_hp"]), int(data["base_attack"]), int(data["base_defense"]), int(data.get("base_block", 1))
	], 13))
	var highest_floor := int(roster.get("highest_floor", 0))
	inner.add_child(label_factory.call("最高记录：%s" % (str(highest_floor) if highest_floor > 0 else "无"), 13))
	_set_mouse_ignore_recursive(inner)
	return card


func _build_class_card(session: Variant, class_key: String, label_factory: Callable, action_callback: Callable, selected: bool) -> Control:
	var roster := _player_snapshot(session, class_key)
	var data: Dictionary = DataCatalog.CLASSES[class_key]
	var button := Button.new()
	_lock_proportional_size(button, _scaled_size(CLASS_CARD_SIZE))
	button.text = ""
	_apply_card_style(button, selected, false)
	button.pressed.connect(func(): _animate_class_selection(button, class_key, action_callback))

	var inner := VBoxContainer.new()
	inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	inner.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inner.add_theme_constant_override("separation", 3)
	button.add_child(inner)
	inner.add_child(UIHelpers.avatar_for(class_key))
	inner.add_child(label_factory.call(String(data["name"]), 18))
	inner.add_child(label_factory.call("生命 %d  攻击 %d  护甲 %d  格挡 %d" % [
		int(data["max_hp"]), int(data["base_attack"]), int(data["base_defense"]), int(data.get("base_block", 1))
	], 12))
	var highest_floor := int(roster.get("highest_floor", 0))
	var floor_label := "未记录"
	if highest_floor > 0:
		floor_label = "最高第 %d 层" % highest_floor
	inner.add_child(label_factory.call(floor_label, 12))
	_set_mouse_ignore_recursive(inner)
	return button


func _build_loadout_column(session: Variant, label_factory: Callable, action_callback: Callable) -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size = _scaled_size(Vector2(370, 0))
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)

	column.add_child(_nowrap_label(label_factory, "装备 / 技能 / 消耗品", 18, 220))
	if selected_class == "":
		column.add_child(label_factory.call("先选择一个职业，再配置装束与出发内容。", 14))
		return column

	var roster := _player_snapshot(session, selected_class)
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	column.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	scroll.add_child(content)

	content.add_child(_build_equipment_panel(session, roster, label_factory, action_callback))
	content.add_child(_build_skill_panel(session, roster, label_factory, action_callback))
	content.add_child(_build_consumable_panel(session, roster, label_factory, action_callback))
	return column


func _build_equipment_panel(session: Variant, roster: Dictionary, label_factory: Callable, action_callback: Callable) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(_nowrap_label(label_factory, "装备栏", 16, 90))

	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	box.add_child(grid)

	for slot_data in [
		["head", "头部"], ["necklace", "项链"], ["ring", "戒指1"], ["ring2", "戒指2"], ["weapon", "武器"], ["offhand", "副手"],
		["body", "上身"], ["waist", "腰部"], ["legs", "下身"], ["hands", "手部"], ["leggings", "护腿"], ["feet", "脚部"]
	]:
		grid.add_child(_build_slot_button(session, roster, String(slot_data[0]), String(slot_data[1]), action_callback, false))
	return box


func _build_skill_panel(session: Variant, roster: Dictionary, label_factory: Callable, action_callback: Callable) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	box.add_child(_nowrap_label(label_factory, "技能栏", 16, 90))

	var basic_row := HBoxContainer.new()
	basic_row.add_theme_constant_override("separation", 8)
	box.add_child(basic_row)

	var current_map: Dictionary = roster.get("innate_skills", {})
	basic_row.add_child(_build_skill_circle(session, roster, "attack", "攻", String(current_map.get("attack_1", "innate_attack_1")), action_callback))
	basic_row.add_child(_build_skill_circle(session, roster, "defense", "防", String(current_map.get("defend", "innate_defend")), action_callback))
	basic_row.add_child(_build_skill_circle(session, roster, "dodge", "躲", String(current_map.get("dodge", "innate_dodge")), action_callback))

	var skill_row := HBoxContainer.new()
	skill_row.add_theme_constant_override("separation", 8)
	box.add_child(skill_row)
	for i in range(1, 5):
		var skill_id := ""
		var equipped: Array = roster.get("equipped_skills", [])
		if i - 1 < equipped.size():
			skill_id = String(equipped[i - 1])
		skill_row.add_child(_build_skill_circle(session, roster, "skill_%d" % i, str(i), skill_id, action_callback))

	return box


func _build_consumable_panel(session: Variant, roster: Dictionary, label_factory: Callable, action_callback: Callable) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.add_child(_nowrap_label(label_factory, "消耗品栏（最多 5 个）", 16, 180))

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	box.add_child(row)

	var equipped: Array = roster.get("consumables", [])
	while equipped.size() < 5:
		equipped.append("")
	for i in range(5):
		var item_id := String(equipped[i])
		row.add_child(_build_consumable_slot(session, roster, i + 1, item_id, action_callback))

	return box


func _build_warehouse_column(session: Variant, label_factory: Callable, action_callback: Callable) -> Control:
	var column := VBoxContainer.new()
	column.custom_minimum_size = _scaled_size(Vector2(560, 0))
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 10)

	column.add_child(_nowrap_label(label_factory, "仓库", 18, 80))
	if selected_class == "":
		column.add_child(label_factory.call("选中职业后，仓库才会显示可用物品。", 14))
		return column

	var grid_scroll := ScrollContainer.new()
	grid_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(grid_scroll)

	var grid := GridContainer.new()
	grid.columns = 6
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid_scroll.add_child(grid)

	var roster := _player_snapshot(session, selected_class)
	var items := _warehouse_items(session, roster)
	var visible_items := _filtered_items(items)
	for item in visible_items:
		grid.add_child(_build_warehouse_item(session, roster, item, label_factory, action_callback))
	for _i in range(maxi(0, 30 - visible_items.size())):
		grid.add_child(_build_empty_item_card())

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)
	column.add_child(_build_floor_and_start_row(session, label_factory, action_callback))
	return column


func _build_floor_and_start_row(session: Variant, label_factory: Callable, action_callback: Callable) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)

	var roster := _player_snapshot(session, selected_class)
	var max_floor := _floor_limit(roster)
	if start_floor < 1 or start_floor > max_floor:
		start_floor = max_floor

	var floor_button := Button.new()
	floor_button.text = "层数：%s" % _floor_label(start_floor, max_floor)
	floor_button.custom_minimum_size = _scaled_size(Vector2(180, 38))
	floor_button.pressed.connect(func():
		floor_menu_open = not floor_menu_open
		action_callback.call("toggle_floor_menu", "")
	)
	box.add_child(_build_floor_menu(session, label_factory, action_callback, max_floor))
	box.add_child(floor_button)

	var start_button := Button.new()
	start_button.text = "出发"
	start_button.custom_minimum_size = _scaled_size(Vector2(180, 48))
	start_button.pressed.connect(func(): action_callback.call("start_game", ""))
	box.add_child(start_button)
	return box


func _build_floor_menu(session: Variant, label_factory: Callable, action_callback: Callable, max_floor: int) -> Control:
	var container := VBoxContainer.new()
	container.visible = floor_menu_open
	container.add_theme_constant_override("separation", 4)
	if not floor_menu_open:
		return container

	var options := VBoxContainer.new()
	options.custom_minimum_size = _scaled_size(Vector2(180, 0))
	options.add_theme_constant_override("separation", 4)
	container.add_child(options)

	var max_button := Button.new()
	max_button.text = "MAX"
	max_button.custom_minimum_size = _scaled_size(Vector2(180, 32))
	max_button.pressed.connect(func():
		start_floor = max_floor
		floor_menu_open = false
		action_callback.call("select_floor", str(max_floor))
	)
	options.add_child(max_button)

	for floor in range(1, max_floor + 1):
		var captured_floor := floor
		var floor_button := Button.new()
		floor_button.text = "第 %d 层" % captured_floor
		floor_button.custom_minimum_size = _scaled_size(Vector2(180, 32))
		floor_button.pressed.connect(func():
			start_floor = captured_floor
			floor_menu_open = false
			action_callback.call("select_floor", str(captured_floor))
		)
		options.add_child(floor_button)

	return container


func _build_slot_button(session: Variant, roster: Dictionary, slot_key: String, label: String, action_callback: Callable, small: bool) -> Control:
	var equipped := String(roster.get("equipment", {}).get(slot_key, ""))
	var text := label
	if equipped != "" and DataCatalog.EQUIPMENT.has(equipped):
		text = _short_name(String(DataCatalog.EQUIPMENT[equipped]["name"]), 4)
	var button := Button.new()
	button.text = text
	_lock_proportional_size(button, _scaled_square(EQUIPMENT_SLOT_SIZE.x))
	button.tooltip_text = String(DataCatalog.EQUIPMENT[equipped]["name"]) if equipped != "" and DataCatalog.EQUIPMENT.has(equipped) else label
	button.add_theme_font_size_override("font_size", 12)
	button.pressed.connect(func():
		selected_equipment_slot = slot_key
		selected_equipment_tab = "ring" if slot_key.begins_with("ring") else slot_key
		browse_mode = "equipment"
		selected_consumable_slot = 1
		floor_menu_open = false
		action_callback.call("focus_equipment_slot", slot_key)
	)
	if selected_equipment_slot == slot_key:
		_apply_card_style(button, true, false)
	else:
		_apply_card_style(button, false, false)
	return button


func _build_skill_circle(session: Variant, roster: Dictionary, key: String, label: String, skill_id: String, action_callback: Callable) -> Control:
	var skill_name := _skill_name(skill_id)
	var button := Button.new()
	button.text = label
	_lock_proportional_size(button, _scaled_square(SKILL_SLOT_SIZE.x))
	button.tooltip_text = skill_name
	button.pressed.connect(func():
		selected_skill_filter = key
		floor_menu_open = false
		_show_skill_popup(button, roster, key, skill_id, action_callback)
	)
	if selected_skill_filter == key:
		_apply_card_style(button, true, true)
	else:
		_apply_card_style(button, false, true)
	return button


func _build_consumable_slot(session: Variant, roster: Dictionary, slot_index: int, item_id: String, action_callback: Callable) -> Control:
	var text := "空"
	if item_id != "" and DataCatalog.CONSUMABLES.has(item_id):
		text = String(DataCatalog.CONSUMABLES[item_id]["name"])
	var button := Button.new()
	button.text = "%d\n%s" % [slot_index, text]
	_lock_proportional_size(button, _scaled_size(Vector2(88, 54)))
	button.pressed.connect(func():
		selected_consumable_slot = slot_index
		selected_equipment_tab = "consumable"
		browse_mode = "consumable"
		floor_menu_open = false
		action_callback.call("focus_consumable_slot", str(slot_index))
	)
	if selected_consumable_slot == slot_index:
		_apply_card_style(button, true, false)
	return button


func _build_warehouse_item(session: Variant, roster: Dictionary, item: Dictionary, label_factory: Callable, action_callback: Callable) -> Control:
	var item_id := String(item.get("id", ""))
	var button := Button.new()
	button.text = _warehouse_item_text(item)
	_lock_proportional_size(button, _scaled_size(WAREHOUSE_CELL_SIZE))
	button.tooltip_text = String(item.get("name", ""))
	_apply_card_style(button, false, false)

	var kind := String(item.get("kind", "equipment"))
	if kind == "skill":
		if not bool(item.get("unlocked", false)):
			button.modulate = Color(0.55, 0.55, 0.55, 1.0)
		button.pressed.connect(func():
			hover_kind = "skill"
			hover_id = item_id
			hover_slot = ""
			if browse_mode == "skills" and selected_skill_filter.begins_with("skill_"):
				action_callback.call("equip_skill", item_id)
			else:
				action_callback.call("hover_skill", item_id)
		)
		button.mouse_entered.connect(func():
			hover_kind = "skill"
			hover_id = item_id
			hover_slot = ""
			_show_item_tooltip(button, _skill_preview_lines(session, roster, item_id))
		)
		button.mouse_exited.connect(func(): _hide_tooltip())
	elif kind == "consumable":
		button.pressed.connect(func():
			hover_kind = "consumable"
			hover_id = item_id
			hover_slot = ""
			action_callback.call("equip_consumable", item_id)
		)
		button.mouse_entered.connect(func():
			hover_kind = "consumable"
			hover_id = item_id
			hover_slot = ""
			_show_item_tooltip(button, _consumable_preview_lines(item_id))
		)
		button.mouse_exited.connect(func(): _hide_tooltip())
	else:
		var slot_key := String(item.get("slot", ""))
		button.pressed.connect(func():
			hover_kind = "equipment"
			hover_id = item_id
			hover_slot = slot_key
			action_callback.call("equip_item", item_id)
		)
		button.mouse_entered.connect(func():
			hover_kind = "equipment"
			hover_id = item_id
			hover_slot = slot_key
			_show_item_tooltip(button, _equipment_preview_lines(session, roster, selected_equipment_slot, item_id))
		)
		button.mouse_exited.connect(func(): _hide_tooltip())
	return button


func _build_empty_item_card() -> Control:
	var panel := PanelContainer.new()
	_lock_proportional_size(panel, _scaled_size(WAREHOUSE_CELL_SIZE))
	return panel


func _filtered_items(items: Array[Dictionary]) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in items:
		var kind := String(item.get("kind", "equipment"))
		if browse_mode == "consumable" or selected_equipment_tab == "consumable":
			if kind == "consumable":
				result.append(item)
			continue
		if kind == "equipment" and _slot_accepts_item(selected_equipment_slot, item):
			result.append(item)
	return result


func _warehouse_items(session: Variant, roster: Dictionary) -> Array[Dictionary]:
	var items: Array[Dictionary] = []
	if browse_mode == "consumable" or selected_equipment_tab == "consumable":
		for item_id in roster.get("consumable_ids", []):
			if not DataCatalog.CONSUMABLES.has(String(item_id)):
				continue
			var item: Dictionary = DataCatalog.CONSUMABLES[String(item_id)].duplicate(true)
			item["id"] = String(item_id)
			item["kind"] = "consumable"
			items.append(item)
		return items

	var equipped_ids := _equipped_item_ids(roster)
	for item_id in roster.get("equipment_ids", []):
		if not DataCatalog.EQUIPMENT.has(String(item_id)):
			continue
		if equipped_ids.has(String(item_id)):
			continue
		var item: Dictionary = DataCatalog.EQUIPMENT[String(item_id)].duplicate(true)
		var item_class := String(item.get("class", "common"))
		if item_class != "common" and item_class != selected_class:
			continue
		item["id"] = String(item_id)
		item["kind"] = "equipment"
		items.append(item)
	return items


func _equipment_preview_lines(session: Variant, roster: Dictionary, slot_key: String, item_id: String) -> PackedStringArray:
	var result := PackedStringArray()
	if not DataCatalog.EQUIPMENT.has(item_id):
		return result
	var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
	var current := _preview_stats(session, roster)
	var preview := _preview_equipment(roster, slot_key, item_id)
	var preview_stats := _preview_stats(session, preview)
	result.append("装备：%s" % String(item["name"]))
	result.append("部位：%s" % _slot_label(slot_key))
	result.append("基础：生命 +%d / 攻击 +%d / 护甲 +%d / 格挡 +%d" % [
		int(item.get("hp", 0)),
		int(item.get("attack", 0)),
		int(item.get("armor", 0)),
		int(item.get("block", 0))
	])
	var set_id := String(item.get("set_id", ""))
	if set_id != "" and DataCatalog.EQUIPMENT_SETS.has(set_id):
		result.append("套装：%s" % String(DataCatalog.EQUIPMENT_SETS[set_id]["name"]))
	else:
		result.append("套装：无")
	result.append("更换后：生命 %d (%s) / 攻击 %d (%s) / 护甲 %d (%s) / 格挡 %d (%s)" % [
		int(preview_stats.get("max_hp", 0)), _delta_text(int(preview_stats.get("max_hp", 0)) - int(current.get("max_hp", 0))),
		int(preview_stats.get("attack", 0)), _delta_text(int(preview_stats.get("attack", 0)) - int(current.get("attack", 0))),
		int(preview_stats.get("defense", 0)), _delta_text(int(preview_stats.get("defense", 0)) - int(current.get("defense", 0))),
		int(preview_stats.get("block_power", 0)), _delta_text(int(preview_stats.get("block_power", 0)) - int(current.get("block_power", 0)))
	])
	var current_sets: Dictionary = current.get("set_counts", {})
	var preview_sets: Dictionary = preview_stats.get("set_counts", {})
	var set_changes := _set_change_lines(current_sets, preview_sets)
	if set_changes.is_empty():
		result.append("套装变化：无")
	else:
		for line in set_changes:
			result.append(line)
	return result


func _skill_preview_lines(session: Variant, roster: Dictionary, skill_id: String) -> PackedStringArray:
	var result := PackedStringArray()
	if not DataCatalog.SKILLS.has(skill_id):
		return result
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	result.append("技能：%s" % String(skill["name"]))
	result.append("类型：%s" % String(skill.get("type", "")))
	result.append("槽位：%d" % int(skill.get("slot", 0)))
	result.append("消耗：%d" % int(skill.get("energy_cost", 0)))
	if skill.has("multiplier"):
		result.append("倍率：x%.2f" % float(skill.get("multiplier", 1.0)))
	if skill.has("hits"):
		result.append("段数：%d" % int(skill.get("hits", 1)))
	if roster.get("unlocked_skills", []).has(skill_id):
		result.append("状态：已解锁")
	else:
		result.append("状态：未解锁")
	return result


func _consumable_preview_lines(item_id: String) -> PackedStringArray:
	var result := PackedStringArray()
	if not DataCatalog.CONSUMABLES.has(item_id):
		return result
	var item: Dictionary = DataCatalog.CONSUMABLES[item_id]
	result.append("消耗品：%s" % String(item["name"]))
	result.append("类型：%s" % String(item.get("kind", "")))
	result.append("效果值：%s" % str(item.get("value", 0)))
	if item.has("uses"):
		result.append("使用次数：%d" % int(item.get("uses", 1)))
	result.append(String(item.get("desc", "")))
	return result


func _preview_stats(session: Variant, roster: Dictionary) -> Dictionary:
	var snapshot := roster.duplicate(true)
	var class_id := String(snapshot.get("class_id", selected_class))
	if class_id == "":
		class_id = selected_class
	if class_id == "" and DataCatalog.CLASSES.has("warrior"):
		class_id = "warrior"
	if not snapshot.has("class_id"):
		snapshot["class_id"] = class_id
	if snapshot.is_empty():
		return {"max_hp": 0, "attack": 0, "defense": 0, "block_power": 0, "set_counts": {}}
	snapshot["equipment_attachments"] = snapshot.get("equipment_attachments", {})
	snapshot["skill_attachments"] = snapshot.get("skill_attachments", {})
	snapshot["statuses"] = []
	if not snapshot.has("equipped_skills"):
		snapshot["equipped_skills"] = []
	while snapshot["equipped_skills"].size() < 4:
		snapshot["equipped_skills"].append("")
	if not snapshot.has("consumables"):
		snapshot["consumables"] = []
	while snapshot["consumables"].size() < 5:
		snapshot["consumables"].append("")
	if session != null and session.simulator != null:
		session.simulator._recalculate_player_stats(snapshot, true)
	return {
		"max_hp": int(snapshot.get("max_hp", 0)),
		"attack": int(snapshot.get("attack", 0)),
		"defense": int(snapshot.get("defense", 0)),
		"block_power": int(snapshot.get("block_power", 0)),
		"set_counts": snapshot.get("set_counts", {})
	}


func _preview_equipment(roster: Dictionary, slot_key: String, item_id: String) -> Dictionary:
	var preview := roster.duplicate(true)
	if not preview.has("equipment"):
		preview["equipment"] = {}
	var equipment: Dictionary = preview.get("equipment", {})
	var previous := String(equipment.get(slot_key, ""))
	var displaced_slot := ""
	for existing_slot in equipment.keys():
		if String(equipment[existing_slot]) == item_id:
			displaced_slot = String(existing_slot)
			break
	if displaced_slot != "":
		if previous != "":
			equipment[displaced_slot] = previous
		else:
			equipment.erase(displaced_slot)
	else:
		equipment[slot_key] = item_id
	preview["equipment"] = equipment
	return preview


func _set_change_lines(current_sets: Dictionary, preview_sets: Dictionary) -> PackedStringArray:
	var result := PackedStringArray()
	var keys := []
	for key in current_sets.keys():
		if not keys.has(String(key)):
			keys.append(String(key))
	for key in preview_sets.keys():
		if not keys.has(String(key)):
			keys.append(String(key))
	for set_id in keys:
		var before := int(current_sets.get(set_id, 0))
		var after := int(preview_sets.get(set_id, 0))
		if before == after:
			continue
		var set_name: String = set_id
		if DataCatalog.EQUIPMENT_SETS.has(set_id):
			set_name = String(DataCatalog.EQUIPMENT_SETS[set_id]["name"])
		result.append("套装：%s %d -> %d" % [set_name, before, after])
	return result


func _skill_name(skill_id: String) -> String:
	if DataCatalog.SKILLS.has(skill_id):
		return String(DataCatalog.SKILLS[skill_id]["name"])
	if DataCatalog.INNATE_SKILLS.has(skill_id):
		return String(DataCatalog.INNATE_SKILLS[skill_id]["name"])
	return "空"


func _slot_label(slot_key: String) -> String:
	match slot_key:
		"head":
			return "头部"
		"body":
			return "上身"
		"waist":
			return "腰部"
		"legs":
			return "下身"
		"hands":
			return "手部"
		"leggings":
			return "护腿"
		"feet":
			return "脚部"
		"weapon":
			return "武器"
		"offhand":
			return "副手"
		"necklace":
			return "项链"
		"ring":
			return "戒指"
		"ring2":
			return "戒指2"
	return slot_key


func _floor_limit(roster: Dictionary) -> int:
	var highest := int(roster.get("highest_floor", 0))
	return maxi(1, highest - 3)


func _floor_label(floor: int, max_floor: int) -> String:
	if floor >= max_floor:
		return "MAX"
	return "第 %d 层" % floor


func _player_snapshot(session: Variant, class_key: String) -> Dictionary:
	if class_key == "":
		return {}
	if session == null:
		return {}
	var roster_player: Dictionary = session.get_roster_player(class_key)
	if roster_player.is_empty() and session.simulator != null:
		roster_player = session.simulator.create_character(class_key)
	return roster_player


func _warehouse_item_text(item: Dictionary) -> String:
	var kind := String(item.get("kind", "equipment"))
	if kind == "skill":
		var unlocked := bool(item.get("unlocked", false))
		return "%s\n%s" % [String(item.get("name", "")), "已解锁" if unlocked else "未解锁"]
	if kind == "consumable":
		return "%s\n%s" % [String(item.get("name", "")), "消耗品"]
	return "%s\n%s" % [String(item.get("name", "")), _slot_label(String(item.get("slot", "")))]


func _apply_card_style(button: Button, selected: bool, round_shape: bool) -> void:
	var base := Color(0.18, 0.19, 0.22, 1.0)
	var border := Color(0.36, 0.38, 0.44, 1.0)
	if selected:
		base = Color(0.24, 0.31, 0.42, 1.0)
		border = Color(0.60, 0.76, 0.92, 1.0)
	var normal := StyleBoxFlat.new()
	normal.bg_color = base
	normal.border_color = border
	normal.border_width_left = 1
	normal.border_width_top = 1
	normal.border_width_right = 1
	normal.border_width_bottom = 1
	normal.corner_radius_top_left = 999 if round_shape else 8
	normal.corner_radius_top_right = 999 if round_shape else 8
	normal.corner_radius_bottom_left = 999 if round_shape else 8
	normal.corner_radius_bottom_right = 999 if round_shape else 8

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = base.lightened(0.08)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = base.darkened(0.08)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", normal)


func _delta_text(value: int) -> String:
	if value > 0:
		return "+%d" % value
	if value < 0:
		return "%d" % value
	return "±0"


func _animate_class_selection(button: Button, class_key: String, action_callback: Callable) -> void:
	button.disabled = true
	var parent := button.get_parent()
	var tween := button.create_tween()
	tween.set_parallel(true)
	for child in parent.get_children():
		if child is Control and child != button:
			tween.tween_property(child, "modulate:a", 0.0, 0.18)
	tween.tween_property(button, "scale", Vector2(1.04, 1.04), 0.12).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.chain().tween_callback(func(): action_callback.call("select_class", class_key))


func _show_skill_popup(anchor: Control, roster: Dictionary, key: String, current_skill_id: String, action_callback: Callable) -> void:
	_hide_skill_popup()
	var popup := PanelContainer.new()
	popup.custom_minimum_size = _scaled_size(Vector2(230, 0))
	popup.set_as_top_level(true)
	skill_popup = popup
	_popup_parent(anchor).add_child(popup)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 4)
	popup.add_child(inner)

	var title := Label.new()
	title.text = _skill_popup_title(key)
	title.add_theme_font_size_override("font_size", 14)
	inner.add_child(title)

	var has_visible := false
	for item in _skill_popup_items(roster, key, current_skill_id):
		var skill_id := String(item.get("id", ""))
		var label := String(item.get("label", "???"))
		var locked := bool(item.get("locked", false))
		var row := Button.new()
		row.text = label
		row.custom_minimum_size = _scaled_size(Vector2(210, 34))
		row.disabled = locked or skill_id == ""
		if not row.disabled and key.begins_with("skill_"):
			row.pressed.connect(func():
				_hide_skill_popup()
				action_callback.call("equip_skill", skill_id)
			)
		inner.add_child(row)
		has_visible = true
	if not has_visible:
		var unknown := Button.new()
		unknown.text = "???"
		unknown.disabled = true
		unknown.custom_minimum_size = _scaled_size(Vector2(210, 34))
		inner.add_child(unknown)

	var size := _scaled_size(Vector2(230, 120))
	var pos := anchor.global_position + _scaled_size(Vector2(0, -120 - 8))
	if pos.y < 8:
		pos.y = anchor.global_position.y + anchor.size.y + _scaled_value(8)
	popup.global_position = pos


func _hide_skill_popup() -> void:
	if skill_popup != null and is_instance_valid(skill_popup):
		skill_popup.queue_free()
	skill_popup = null


func _skill_popup_title(key: String) -> String:
	match key:
		"attack":
			return "攻击"
		"defense":
			return "防御"
		"dodge":
			return "躲避"
	return "技能槽 %s" % key.replace("skill_", "")


func _skill_popup_items(roster: Dictionary, key: String, current_skill_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if key == "attack" or key == "defense" or key == "dodge":
		var skill_id := current_skill_id
		var name := _skill_name(skill_id)
		result.append({"id": "", "label": name, "locked": true})
		return result

	if not key.begins_with("skill_"):
		return [{"id": "", "label": "???", "locked": true}]

	var slot := int(key.replace("skill_", ""))
	var unlocked: Array = roster.get("unlocked_skills", [])
	var hidden_locked := false
	for skill_id in DataCatalog.SKILLS.keys():
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		var skill_class := String(skill.get("class", ""))
		if skill_class != selected_class and skill_class != "common":
			continue
		if int(skill.get("slot", 0)) != slot:
			continue
		if unlocked.has(skill_id):
			var label := String(skill["name"])
			if String(current_skill_id) == String(skill_id):
				label += "（已装备）"
			result.append({"id": String(skill_id), "label": label, "locked": false})
		else:
			hidden_locked = true
	if hidden_locked:
		result.append({"id": "", "label": "???", "locked": true})
	return result


func _show_item_tooltip(anchor: Control, lines: PackedStringArray) -> void:
	_hide_tooltip()
	var panel := PanelContainer.new()
	panel.custom_minimum_size = _scaled_size(Vector2(260, 0))
	panel.set_as_top_level(true)
	tooltip_panel = panel
	_popup_parent(anchor).add_child(panel)

	var inner := VBoxContainer.new()
	inner.add_theme_constant_override("separation", 3)
	panel.add_child(inner)
	for line in lines:
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", 12)
		inner.add_child(label)

	var viewport_size := anchor.get_viewport_rect().size
	var width := _scaled_value(260.0)
	var estimated_height := _scaled_value(28.0 + float(lines.size()) * 20.0)
	var pos := anchor.global_position + Vector2(anchor.size.x + _scaled_value(10.0), 0)
	if pos.x + width > viewport_size.x - _scaled_value(8.0):
		pos.x = anchor.global_position.x - width - _scaled_value(10.0)
	if pos.y + estimated_height > viewport_size.y - _scaled_value(8.0):
		pos.y = maxf(_scaled_value(8.0), viewport_size.y - estimated_height - _scaled_value(8.0))
	panel.global_position = pos


func _hide_tooltip() -> void:
	if tooltip_panel != null and is_instance_valid(tooltip_panel):
		tooltip_panel.queue_free()
	tooltip_panel = null


func _slot_accepts_item(slot_key: String, item: Dictionary) -> bool:
	var item_slot := String(item.get("slot", ""))
	if slot_key == "ring2":
		return item_slot == "ring"
	if slot_key == "ring":
		return item_slot == "ring"
	return item_slot == slot_key


func _equipped_item_ids(roster: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var equipment: Dictionary = roster.get("equipment", {})
	for item_id in equipment.values():
		var id := String(item_id)
		if id != "" and not result.has(id):
			result.append(id)
	return result


func _short_name(text: String, max_chars: int) -> String:
	if text.length() <= max_chars:
		return text
	return text.substr(0, max_chars)


func _layout_scale(root: Control) -> float:
	var viewport_size := root.get_viewport_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return 1.0
	var scale_x := viewport_size.x / DESIGN_VIEWPORT_SIZE.x
	var scale_y := viewport_size.y / DESIGN_VIEWPORT_SIZE.y
	return clampf(minf(scale_x, scale_y), 0.78, 1.16)


func _scaled_value(value: float) -> float:
	return value * layout_scale


func _scaled_size(size: Vector2) -> Vector2:
	return Vector2(size.x * layout_scale, size.y * layout_scale)


func _scaled_square(value: float) -> Vector2:
	var side := value * layout_scale
	return Vector2(side, side)


func _nowrap_label(label_factory: Callable, text_value: String, font_size: int, min_width: float) -> Label:
	var label: Label = label_factory.call(text_value, font_size)
	_configure_nowrap_label(label, min_width)
	return label


func _configure_nowrap_label(label: Label, min_width: float) -> void:
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.custom_minimum_size = _scaled_size(Vector2(min_width, 0))
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN


func _lock_proportional_size(control: Control, size: Vector2) -> void:
	control.custom_minimum_size = size
	control.size = size
	control.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	control.size_flags_vertical = Control.SIZE_SHRINK_CENTER


func _popup_parent(anchor: Control) -> Node:
	var tree := anchor.get_tree()
	if tree != null and tree.current_scene != null:
		return tree.current_scene
	if tree != null:
		return tree.root
	return anchor


func _set_mouse_ignore_recursive(node: Node) -> void:
	if node is Control:
		(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child in node.get_children():
		_set_mouse_ignore_recursive(child)
