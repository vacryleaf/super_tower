extends RefCounted
class_name BestiaryView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const TraitCatalog = preload("res://scripts/core/trait_catalog.gd")

const PAGE_SIZE := 10

var _all_units: Array[Dictionary] = []
var _bestiary: Dictionary = {}
var _current_page := 0
var _selected_index := -1
var _label_factory: Callable
var _close_callback: Callable
var _root: Control
var _list_container: Control
var _detail_container: Control
var _page_label: Label


func render(root: Control, label_factory: Callable, close_callback: Callable, bestiary: Dictionary) -> void:
	_label_factory = label_factory
	_close_callback = close_callback
	_bestiary = bestiary
	_root = root
	_current_page = 0
	_selected_index = -1

	_build_unit_list()
	root.add_child(label_factory.call("怪物图鉴", 30))

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	_build_left_panel(body)
	_build_right_panel(body)

	var back_btn := Button.new()
	back_btn.text = "返回百科"
	back_btn.custom_minimum_size = Vector2(160, 44)
	back_btn.pressed.connect(close_callback)
	root.add_child(back_btn)


func _build_unit_list() -> void:
	_all_units.clear()
	for unit in DataCatalog.NORMAL_UNITS:
		_all_units.append(_unit_with_rank(unit, "normal"))
	for unit in DataCatalog.ELITE_UNITS:
		_all_units.append(_unit_with_rank(unit, "elite"))
	for unit in DataCatalog.BOSS_UNITS:
		_all_units.append(_unit_with_rank(unit, "boss"))


func _unit_with_rank(unit: Dictionary, rank: String) -> Dictionary:
	return {
		"id": String(unit.get("id", "")),
		"name": String(unit.get("name", "")),
		"rank": rank,
		"hp": float(unit.get("hp", 1.0)),
		"attack": float(unit.get("attack", 1.0)),
		"defense": float(unit.get("defense", 1.0)),
		"traits": unit.get("traits", []),
		"skills": unit.get("skills", [])
	}


func _build_left_panel(parent: Control) -> void:
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(220, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(left)

	var unlocked := 0
	for unit in _all_units:
		if _bestiary.has(unit["id"]):
			unlocked += 1
	left.add_child(_label_factory.call("已解锁 %d/%d" % [unlocked, _all_units.size()], 14))

	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(list_scroll)

	_list_container = VBoxContainer.new()
	list_scroll.add_child(_list_container)

	var page_row := HBoxContainer.new()
	page_row.alignment = BoxContainer.ALIGNMENT_CENTER
	left.add_child(page_row)

	var prev_btn := Button.new()
	prev_btn.text = "< 上一页"
	prev_btn.custom_minimum_size = Vector2(90, 32)
	prev_btn.pressed.connect(_on_prev_page)
	page_row.add_child(prev_btn)

	_page_label = _label_factory.call("", 14)
	page_row.add_child(_page_label)

	var next_btn := Button.new()
	next_btn.text = "下一页 >"
	next_btn.custom_minimum_size = Vector2(90, 32)
	next_btn.pressed.connect(_on_next_page)
	page_row.add_child(next_btn)

	_refresh_list()


func _build_right_panel(parent: Control) -> void:
	var right := PanelContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.custom_minimum_size = Vector2(350, 0)
	parent.add_child(right)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_child(scroll)

	_detail_container = VBoxContainer.new()
	_detail_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_detail_container)

	_refresh_detail()


func _refresh_list() -> void:
	for child in _list_container.get_children():
		child.queue_free()

	var total_pages := maxi(1, ceili(float(_all_units.size()) / float(PAGE_SIZE)))
	_current_page = clampi(_current_page, 0, total_pages - 1)
	_page_label.text = "%d/%d" % [_current_page + 1, total_pages]

	var start := _current_page * PAGE_SIZE
	var end := mini(start + PAGE_SIZE, _all_units.size())

	for i in range(start, end):
		var unit: Dictionary = _all_units[i]
		var unlocked := _bestiary.has(unit["id"])
		var name_text := String(unit["name"]) if unlocked else "？？？"
		var rank_text := _rank_label(unit["rank"])
		var text := "%s  %s" % [name_text, rank_text]

		var button := Button.new()
		button.text = text
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size = Vector2(190, 32)
		button.disabled = not unlocked
		if i == _selected_index:
			button.flat = false
		button.pressed.connect(_on_select_unit.bind(i))
		_list_container.add_child(button)


func _refresh_detail() -> void:
	for child in _detail_container.get_children():
		child.queue_free()

	if _selected_index < 0 or _selected_index >= _all_units.size():
		_detail_container.add_child(_label_factory.call("请从左侧列表选择怪物", 16))
		return

	var unit: Dictionary = _all_units[_selected_index]
	var unlocked := _bestiary.has(unit["id"])

	if not unlocked:
		_detail_container.add_child(_label_factory.call("？？？", 24))
		_detail_container.add_child(_label_factory.call("尚未击败该敌人", 14))
		return

	var entry: Dictionary = _bestiary[unit["id"]]
	_detail_container.add_child(_label_factory.call(unit["name"], 24))
	var avatar_path := _enemy_avatar_path(unit["id"])
	if avatar_path != "":
		var avatar := TextureRect.new()
		avatar.texture = load(avatar_path)
		avatar.custom_minimum_size = Vector2(64, 64)
		avatar.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		avatar.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_detail_container.add_child(avatar)
	_detail_container.add_child(_label_factory.call("等级：%s" % _rank_name(unit["rank"]), 16))
	_detail_container.add_child(_label_factory.call("生命×%.2f  攻击×%.2f  护甲×%.2f" % [unit["hp"], unit["attack"], unit["defense"]], 14))

	var traits: Array = unit["traits"]
	_detail_container.add_child(_label_factory.call("特性：%s" % TraitCatalog.labels(traits), 15))
	for trait_id in traits:
		var desc := String(TraitCatalog.DESCRIPTIONS.get(trait_id, ""))
		if desc != "":
			_detail_container.add_child(_label_factory.call("  %s" % desc, 13))

	var skills: Array = unit["skills"]
	if not skills.is_empty():
		var skill_names: Array[String] = []
		for skill_id in skills:
			var skill: Dictionary = DataCatalog.SKILLS.get(skill_id, {})
			skill_names.append(String(skill.get("name", skill_id)))
		_detail_container.add_child(_label_factory.call("技能：%s" % "、".join(skill_names), 15))

	_detail_container.add_child(_label_factory.call("击败次数：%d" % int(entry.get("defeated_count", 0)), 14))


func _enemy_avatar_path(enemy_id: String) -> String:
	match enemy_id:
		"normal_rat_01":
			return "res://img/rot_rat.png"
		"normal_rat_02":
			return "res://img/fang_rat.png"
	return ""


func _on_select_unit(index: int) -> void:
	_selected_index = index
	_refresh_list()
	_refresh_detail()


func _on_prev_page() -> void:
	if _current_page > 0:
		_current_page -= 1
		_selected_index = -1
		_refresh_list()
		_refresh_detail()


func _on_next_page() -> void:
	var total_pages := maxi(1, ceili(float(_all_units.size()) / float(PAGE_SIZE)))
	if _current_page < total_pages - 1:
		_current_page += 1
		_selected_index = -1
		_refresh_list()
		_refresh_detail()


func _rank_label(rank: String) -> String:
	match rank:
		"elite":
			return "精英"
		"boss":
			return "首领"
		_:
			return "普通"


func _rank_name(rank: String) -> String:
	match rank:
		"elite":
			return "精英"
		"boss":
			return "首领"
		_:
			return "普通"