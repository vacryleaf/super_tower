extends RefCounted
class_name EncyclopediaView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const TraitCatalog = preload("res://scripts/core/trait_catalog.gd")
const UIHelpers = preload("res://scripts/ui/ui_helpers.gd")

var _label_factory: Callable
var _bestiary_callback: Callable
var _detail_container: Control
var _category_buttons: Array[Button] = []


func render(root: Control, label_factory: Callable, close_callback: Callable, bestiary_callback: Callable = Callable()) -> void:
	_label_factory = label_factory
	_bestiary_callback = bestiary_callback
	_category_buttons.clear()

	root.add_child(label_factory.call("百科", 30))

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	_build_left_panel(body)
	_build_right_panel(body)

	var close_button := Button.new()
	close_button.text = "返回营地"
	close_button.custom_minimum_size = Vector2(160, 44)
	close_button.pressed.connect(close_callback)
	root.add_child(close_button)

	_select_category(0)


func _build_left_panel(parent: Control) -> void:
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(180, 0)
	left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(left)

	for i in range(UIHelpers.CATEGORIES.size()):
		var cat: Array = UIHelpers.CATEGORIES[i]
		var btn := Button.new()
		btn.text = cat[0]
		btn.custom_minimum_size = Vector2(160, 40)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_category_pressed.bind(i))
		_category_buttons.append(btn)
		left.add_child(btn)


func _build_right_panel(parent: Control) -> void:
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


func _on_category_pressed(index: int) -> void:
	_select_category(index)


func _select_category(index: int) -> void:
	for i in range(_category_buttons.size()):
		_category_buttons[i].flat = (i != index)

	for child in _detail_container.get_children():
		child.queue_free()

	var cat_id: String = UIHelpers.CATEGORIES[index][1]
	if cat_id == "bestiary":
		_detail_container.add_child(_label_factory.call("点击下方按钮查看怪物图鉴", 16))
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
			_render_classes()
		"traits":
			_render_traits()


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


func _render_classes() -> void:
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
