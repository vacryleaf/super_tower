extends RefCounted
class_name BestiaryView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const TraitCatalog = preload("res://scripts/core/trait_catalog.gd")


func render(root: Control, label_factory: Callable, close_callback: Callable, bestiary: Dictionary) -> void:
	root.add_child(label_factory.call("敌人图鉴", 30))

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	_render_section(content, label_factory, "普通敌人", DataCatalog.NORMAL_UNITS, "normal", bestiary)
	_render_separator(content)
	_render_section(content, label_factory, "精英敌人", DataCatalog.ELITE_UNITS, "elite", bestiary)
	_render_separator(content)
	_render_section(content, label_factory, "Boss", DataCatalog.BOSS_UNITS, "boss", bestiary)

	var close_button := Button.new()
	close_button.text = "返回营地"
	close_button.custom_minimum_size = Vector2(160, 44)
	close_button.pressed.connect(close_callback)
	root.add_child(close_button)


func _render_section(parent: Control, label_factory: Callable, title: String, units: Array[Dictionary], rank: String, bestiary: Dictionary) -> void:
	parent.add_child(label_factory.call(title, 22))

	var unlocked_count := 0
	for unit in units:
		var enemy_id := String(unit.get("id", ""))
		if bestiary.has(enemy_id):
			unlocked_count += 1
	parent.add_child(label_factory.call("已解锁 %d/%d" % [unlocked_count, units.size()], 14))

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(grid)

	for unit in units:
		grid.add_child(_enemy_card(unit, rank, label_factory, bestiary))


func _enemy_card(unit: Dictionary, rank: String, label_factory: Callable, bestiary: Dictionary) -> Control:
	var enemy_id := String(unit.get("id", ""))
	var entry: Dictionary = bestiary.get(enemy_id, {})
	var unlocked := not entry.is_empty()

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(300, 130)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	panel.add_child(box)

	var name_text := String(unit.get("name", "???")) if unlocked else "？？？"
	var rank_label := _rank_name(rank)
	var defeated_text := ""
	if unlocked:
		defeated_text = "  击败 %d 次" % int(entry.get("defeated_count", 0))
	box.add_child(label_factory.call("%s  %s%s" % [name_text, rank_label, defeated_text], 18))

	if unlocked:
		var hp_mult := float(unit.get("hp", 1.0))
		var atk_mult := float(unit.get("attack", 1.0))
		var def_mult := float(unit.get("defense", 1.0))
		box.add_child(label_factory.call("生命×%.2f  攻击×%.2f  护甲×%.2f" % [hp_mult, atk_mult, def_mult], 14))

		var traits: Array = unit.get("traits", [])
		var trait_text := "特性：%s" % TraitCatalog.labels(traits)
		box.add_child(label_factory.call(trait_text, 13))

		var skills: Array = unit.get("skills", [])
		if not skills.is_empty():
			var skill_names: Array[String] = []
			for skill_id in skills:
				var skill: Dictionary = DataCatalog.SKILLS.get(skill_id, {})
				skill_names.append(String(skill.get("name", skill_id)))
			box.add_child(label_factory.call("技能：%s" % "、".join(skill_names), 13))
	else:
		box.add_child(label_factory.call("击败该敌人后解锁图鉴", 13))

	return panel


func _rank_name(rank: String) -> String:
	match rank:
		"elite":
			return "精英"
		"boss":
			return "首领"
		_:
			return "普通"


func _render_separator(parent: Control) -> void:
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 20)
	parent.add_child(sep)