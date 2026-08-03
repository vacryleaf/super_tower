extends RefCounted
class_name NpcShopView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func render(root: Control, session: Variant, mode: String, label_factory: Callable, buy_callback: Callable, back_callback: Callable) -> void:
	var title := "商人" if mode == "merchant" else ("铁匠" if mode == "blacksmith" else "法师")
	root.add_child(label_factory.call(title, 30))
	root.add_child(label_factory.call("塔币：%d" % session.tower_coins, 18))
	if mode == "merchant":
		_render_consumables(root, session, label_factory, buy_callback)
	elif mode == "blacksmith":
		_render_equipment(root, session, label_factory, buy_callback)
	else:
		_render_skills(root, session, label_factory, buy_callback)
	var back_button := Button.new()
	back_button.text = "返回营地"
	back_button.custom_minimum_size = Vector2(160, 44)
	back_button.pressed.connect(back_callback)
	root.add_child(back_button)


func _render_consumables(root: Control, session: Variant, label_factory: Callable, buy_callback: Callable) -> void:
	for item_id in DataCatalog.CONSUMABLES.keys():
		var item: Dictionary = DataCatalog.CONSUMABLES[item_id]
		_add_consumable_row(root, session, label_factory, buy_callback, String(item_id), String(item["name"]), 5, false)
		if session.is_npc_feature_unlocked("merchant_upgraded"):
			_add_consumable_row(root, session, label_factory, buy_callback, String(item_id) + "|upgraded", "强化" + String(item["name"]), 8, true)


func _add_consumable_row(root: Control, session: Variant, label_factory: Callable, buy_callback: Callable, purchase_id: String, label: String, price: int, upgraded: bool) -> void:
	var row := HBoxContainer.new()
	row.add_child(label_factory.call("%s - %d 塔币" % [label, price], 16))
	var button := Button.new()
	button.text = "购买"
	button.disabled = session.tower_coins < price
	button.pressed.connect(func(): buy_callback.call(purchase_id))
	row.add_child(button)
	root.add_child(row)


func _render_equipment(root: Control, session: Variant, label_factory: Callable, buy_callback: Callable) -> void:
	var player: Dictionary = session.player
	for item_id in DataCatalog.EQUIPMENT.keys():
		if player.get("equipment_ids", []).has(item_id):
			continue
		var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
		var row := HBoxContainer.new()
		row.add_child(label_factory.call("%s - %d 塔币" % [item["name"], DataCatalog.PERMANENT_EQUIPMENT_PRICE], 16))
		var button := Button.new()
		button.text = "解锁"
		button.disabled = session.tower_coins < DataCatalog.PERMANENT_EQUIPMENT_PRICE
		button.pressed.connect(func(): buy_callback.call(String(item_id)))
		row.add_child(button)
		root.add_child(row)


func _render_skills(root: Control, session: Variant, label_factory: Callable, buy_callback: Callable) -> void:
	for skill_id in DataCatalog.SKILLS.keys():
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		var slot := int(skill.get("slot", 0))
		if slot < 3 or slot > 4 or session.is_skill_owned(String(skill_id)):
			continue
		var row := HBoxContainer.new()
		row.add_child(label_factory.call("%s - %d 塔币" % [skill["name"], DataCatalog.PERMANENT_SKILL_PRICE], 16))
		var button := Button.new()
		button.text = "解锁"
		button.disabled = session.tower_coins < DataCatalog.PERMANENT_SKILL_PRICE
		button.pressed.connect(func(): buy_callback.call(String(skill_id)))
		row.add_child(button)
		root.add_child(row)
