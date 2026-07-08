extends RefCounted
class_name CampView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func render(
	root: Control,
	session: Variant,
	label_factory: Callable,
	continue_callback: Callable,
	shop_callback: Callable,
	encyclopedia_callback: Callable,
	class_detail_callback: Callable,
	pre_run_callback: Callable
) -> void:
	root.add_child(label_factory.call("塔下营地", 30))
	root.add_child(label_factory.call("可玩版本：新手引导、手动战斗、奖励选择、装备、技能和 1-10 层流程。", 16))

	if session.has_active_run():
		var continue_button := Button.new()
		continue_button.text = "继续当前派遣"
		continue_button.custom_minimum_size = Vector2(190, 46)
		continue_button.pressed.connect(continue_callback)
		root.add_child(continue_button)

	root.add_child(label_factory.call("塔币：%d" % session.tower_coins, 18))

	root.add_child(label_factory.call("职业", 22))
	var class_row := HBoxContainer.new()
	class_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	root.add_child(class_row)
	for class_key in DataCatalog.CLASSES.keys():
		class_row.add_child(_class_card(session, class_key, label_factory, class_detail_callback))

	var util_row := HBoxContainer.new()
	util_row.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	root.add_child(util_row)
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
	var bestiary_button := Button.new()
	bestiary_button.text = "敌人图鉴"
	bestiary_button.custom_minimum_size = Vector2(160, 44)
	bestiary_button.pressed.connect(bestiary_callback)
	util_row.add_child(bestiary_button)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	var bottom_row := HBoxContainer.new()
	bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_row.alignment = BoxContainer.ALIGNMENT_END
	root.add_child(bottom_row)
	var pre_run_button := Button.new()
	pre_run_button.text = "爬塔"
	pre_run_button.custom_minimum_size = Vector2(180, 54)
	pre_run_button.pressed.connect(pre_run_callback)
	bottom_row.add_child(pre_run_button)


func _class_card(session: Variant, class_key: String, label_factory: Callable, detail_callback: Callable) -> Control:
	var data: Dictionary = DataCatalog.CLASSES[class_key]
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(280, 130)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var box := VBoxContainer.new()
	box.add_child(label_factory.call(String(data["name"]), 24))
	box.add_child(label_factory.call("生命%d  攻击%d  护甲%d  格挡%d" % [
		int(data["max_hp"]), int(data["base_attack"]), int(data["base_defense"]), int(data.get("base_block", 1))
	], 16))

	var roster_player: Dictionary = session.get_roster_player(class_key)
	if roster_player.is_empty():
		box.add_child(label_factory.call("未招募", 14))
	else:
		box.add_child(label_factory.call("装备 %d 件  技能 %d 个" % [
			roster_player.get("equipment_ids", []).size(),
			roster_player.get("unlocked_skills", []).size()
		], 14))
		var highest := int(roster_player.get("highest_floor", 0))
		if highest > 0:
			box.add_child(label_factory.call("最高记录：第 %d 层" % highest, 14))

	var detail_button := Button.new()
	detail_button.text = "查看详情"
	detail_button.custom_minimum_size = Vector2(140, 36)
	detail_button.pressed.connect(func(): detail_callback.call(class_key))
	box.add_child(detail_button)

	panel.add_child(box)
	return panel


func _is_shop_unlocked(session: Variant) -> bool:
	var profile = session.save_profile.read_profile(Callable(session, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	for class_key in roster.keys():
		if int(roster[class_key].get("highest_floor", 0)) >= 10:
			return true
	return false