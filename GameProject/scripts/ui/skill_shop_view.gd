extends RefCounted
class_name SkillShopView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const SKILL_PRICE := 15


func render(
	root: Control,
	session: Variant,
	label_factory: Callable,
	buy_callback: Callable,
	back_callback: Callable
) -> void:
	root.add_child(label_factory.call("技能商人", 30))
	root.add_child(label_factory.call("塔币：%d" % session.tower_coins, 18))

	var common_skills := _common_skills()
	var any_owned := false
	for skill_id in common_skills:
		any_owned = any_owned or session.is_skill_owned(skill_id)

	for skill_id in common_skills:
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		var owned := session.is_skill_owned(skill_id)
		var row := HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var label_text := "%s - %d 塔币" % [skill["name"], SKILL_PRICE]
		if owned:
			label_text += "（已拥有）"
		var label: Label = label_factory.call(label_text, 16)
		if owned:
			label.modulate = Color(0.5, 0.5, 0.5)
		row.add_child(label)
		if not owned:
			var button := Button.new()
			button.text = "购买"
			button.custom_minimum_size = Vector2(80, 34)
			if session.tower_coins < SKILL_PRICE:
				button.disabled = true
				button.text = "塔币不足"
			else:
				button.pressed.connect(func(): buy_callback.call(skill_id))
			row.add_child(button)
		root.add_child(row)

	var back_button := Button.new()
	back_button.text = "返回营地"
	back_button.custom_minimum_size = Vector2(160, 44)
	back_button.pressed.connect(back_callback)
	root.add_child(back_button)


func _common_skills() -> Array[String]:
	var result: Array[String] = []
	for skill_id in DataCatalog.SKILLS.keys():
		if String(DataCatalog.SKILLS[skill_id].get("class", "")) == "common":
			result.append(String(skill_id))
	return result

