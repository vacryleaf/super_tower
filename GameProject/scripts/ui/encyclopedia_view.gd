extends RefCounted
class_name EncyclopediaView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const TraitCatalog = preload("res://scripts/core/trait_catalog.gd")


func render(root: Control, label_factory: Callable, close_callback: Callable) -> void:
	root.add_child(label_factory.call("百科", 30))

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	_render_state_cards(content, label_factory)
	_render_separator(content)
	_render_set_effects(content, label_factory)
	_render_separator(content)
	_render_skills(content, label_factory)
	_render_separator(content)
	_render_classes(content, label_factory)
	_render_separator(content)
	_render_traits(content, label_factory)

	var close_button := Button.new()
	close_button.text = "返回营地"
	close_button.custom_minimum_size = Vector2(160, 44)
	close_button.pressed.connect(close_callback)
	root.add_child(close_button)


func _render_state_cards(parent: Control, label_factory: Callable) -> void:
	parent.add_child(label_factory.call("状态卡 Buff", 22))
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
		parent.add_child(label_factory.call(text, 15))
		parent.add_child(label_factory.call("  %s" % tag_explain.get(tag, ""), 13))


func _render_set_effects(parent: Control, label_factory: Callable) -> void:
	parent.add_child(label_factory.call("套装效果", 22))
	for set_id in DataCatalog.EQUIPMENT_SETS.keys():
		var set_data: Dictionary = DataCatalog.EQUIPMENT_SETS[set_id]
		parent.add_child(label_factory.call(set_data["name"], 18))
		var bonuses: Dictionary = set_data.get("bonuses", {})
		for threshold in bonuses.keys():
			var bonus: Dictionary = bonuses[threshold]
			parent.add_child(label_factory.call("  %d 件套：%s" % [int(threshold), String(bonus.get("label", ""))], 14))


func _render_skills(parent: Control, label_factory: Callable) -> void:
	parent.add_child(label_factory.call("技能", 22))
	parent.add_child(label_factory.call("先天技能（所有职业通用）：", 16))
	for skill_id in DataCatalog.INNATE_SKILLS.keys():
		var skill: Dictionary = DataCatalog.INNATE_SKILLS[skill_id]
		parent.add_child(label_factory.call("  %s - %s，费用 %d" % [skill["name"], _skill_type_name(skill), int(skill["cost"])], 14))
	parent.add_child(label_factory.call("职业技能与通用技能：", 16))
	for skill_id in DataCatalog.SKILLS.keys():
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		var class_name := String(skill.get("class", ""))
		var class_label := ""
		match class_name:
			"warrior":
				class_label = "战士"
			"archer":
				class_label = "弓箭手"
			"common":
				class_label = "通用"
		parent.add_child(label_factory.call("  %s [%s] - %s，费用 %d" % [skill["name"], class_label, _skill_type_name(skill), int(skill["cost"])], 14))


func _render_classes(parent: Control, label_factory: Callable) -> void:
	parent.add_child(label_factory.call("职业", 22))
	for class_id in DataCatalog.CLASSES.keys():
		var data: Dictionary = DataCatalog.CLASSES[class_id]
		var resource_name := "怒气" if data.get("resource", "") == "rage" else "专注"
		var text := "%s：HP %d，攻击 %d，护甲 %d，格挡 %d，资源：%s" % [
			data["name"], int(data["max_hp"]), int(data["base_attack"]), int(data["base_defense"]), int(data.get("base_block", 1)), resource_name
		]
		parent.add_child(label_factory.call(text, 15))


func _render_traits(parent: Control, label_factory: Callable) -> void:
	parent.add_child(label_factory.call("敌人特性", 22))
	var all_traits: Array[String] = []
	for trait_id in TraitCatalog.LABELS.keys():
		all_traits.append(String(trait_id))
	all_traits.sort()
	for trait_id in all_traits:
		var label_text := "%s：%s" % [TraitCatalog.LABELS.get(trait_id, trait_id), TraitCatalog.DESCRIPTIONS.get(trait_id, "暂无说明。")]
		parent.add_child(label_factory.call(label_text, 14))


func _skill_type_name(skill: Dictionary) -> String:
	match String(skill.get("type", "")):
		"attack":
			var hits := int(skill.get("hits", 1))
			var mult := float(skill.get("multiplier", 1.0))
			if hits > 1:
				return "攻击（%d 段，每段 x%.2f）" % [hits, mult]
			return "攻击（x%.2f）" % mult
		"defense":
			return "防御（格挡 x%.2f）" % float(skill.get("multiplier", 1.0))
		"stance":
			return "架式（格挡 x%.2f，反击 x%.2f）" % [float(skill.get("block_multiplier", 1.0)), float(skill.get("counter_multiplier", 1.0))]
		"dodge":
			return "闪避（%d 层）" % int(skill.get("dodge_layers", 1))
		"heal":
			return "治疗（生命上限 x%.2f）" % float(skill.get("heal_multiplier", 0.25))
		"buff":
			return "增益（攻击 x%.2f）" % float(skill.get("attack_multiplier", 1.0))
		"debuff":
			return "减益（增伤 x%.2f，削弱 x%.2f）" % [float(skill.get("mark_multiplier", 1.0)), float(skill.get("weaken_multiplier", 1.0))]
	return "未知"


func _render_separator(parent: Control) -> void:
	var sep := HSeparator.new()
	sep.custom_minimum_size = Vector2(0, 20)
	parent.add_child(sep)