extends RefCounted
class_name EquipmentManageView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

const SLOTS := ["head", "body", "waist", "legs", "hands", "leggings", "feet", "weapon", "offhand", "shoulders", "cloak", "necklace", "ring", "ring2"]
const SLOT_LABELS := {
	"head": "头部", "body": "上身", "waist": "腰部", "legs": "腿部",
	"hands": "手套", "leggings": "护腿", "feet": "鞋子", "weapon": "武器",
	"offhand": "副手", "shoulders": "肩部", "cloak": "披风", "necklace": "项链",
	"ring": "戒指1", "ring2": "戒指2"
}

var selected_slot := ""


func render(root: Control, class_key: String, roster_player: Dictionary, label_factory: Callable, action_callback: Callable, close_callback: Callable) -> void:
	var cls_name := String(DataCatalog.CLASSES[class_key]["name"])
	root.add_child(label_factory.call("%s - 装备管理" % cls_name, 28))

	if selected_slot != "":
		root.add_child(label_factory.call("已选中槽位：%s，点击右侧背包物品装备" % SLOT_LABELS.get(selected_slot, selected_slot), 14))

	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)

	_render_slots(body, roster_player, label_factory, close_callback)
	_render_bag(body, roster_player, class_key, label_factory, action_callback)

	var close_button := Button.new()
	close_button.text = "返回营地"
	close_button.custom_minimum_size = Vector2(160, 44)
	close_button.pressed.connect(close_callback)
	root.add_child(close_button)


func _render_slots(parent: Control, roster_player: Dictionary, label_factory: Callable, close_callback: Callable) -> void:
	var slot_panel := VBoxContainer.new()
	slot_panel.custom_minimum_size = Vector2(220, 0)
	slot_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(slot_panel)

	slot_panel.add_child(label_factory.call("装备槽位", 18))

	var equipment: Dictionary = roster_player.get("equipment", {})
	for slot in SLOTS:
		var item_id := String(equipment.get(slot, ""))
		var item_name := "空"
		if item_id != "" and DataCatalog.EQUIPMENT.has(item_id):
			item_name = DataCatalog.EQUIPMENT[item_id]["name"]

		var button := Button.new()
		var text := "%s：%s" % [SLOT_LABELS.get(slot, slot), item_name]
		if slot == selected_slot:
			text = "> " + text
		button.text = text
		button.custom_minimum_size = Vector2(200, 32)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if item_id == "":
			button.modulate = Color(0.5, 0.5, 0.5)
		button.pressed.connect(func(): _select_slot(slot, close_callback))
		slot_panel.add_child(button)


func _render_bag(parent: Control, roster_player: Dictionary, class_key: String, label_factory: Callable, action_callback: Callable) -> void:
	var bag_panel := VBoxContainer.new()
	bag_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(bag_panel)

	bag_panel.add_child(label_factory.call("背包", 18))

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bag_panel.add_child(scroll)

	var bag_content := VBoxContainer.new()
	bag_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(bag_content)

	var equipment_ids: Array = roster_player.get("equipment_ids", [])
	if equipment_ids.is_empty():
		bag_content.add_child(label_factory.call("暂无装备。", 16))
		return

	var equipment: Dictionary = roster_player.get("equipment", {})
	for item_id in equipment_ids:
		if not DataCatalog.EQUIPMENT.has(item_id):
			continue
		var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
		var current_slot := ""
		for slot in equipment.keys():
			if String(equipment[slot]) == String(item_id):
				current_slot = slot
				break

		var button := Button.new()
		var text: String = item["name"]
		if current_slot != "":
			text += "（已装备：%s）" % SLOT_LABELS.get(current_slot, current_slot)
		text += "  HP %d  攻击 %d  护甲 %d  格挡 %d" % [int(item["hp"]), int(item["attack"]), int(item["armor"]), int(item.get("block", 0))]
		var set_id := String(item.get("set_id", ""))
		if set_id != "" and DataCatalog.EQUIPMENT_SETS.has(set_id):
			text += "  [%s]" % DataCatalog.EQUIPMENT_SETS[set_id]["name"]
		button.text = text
		button.custom_minimum_size = Vector2(300, 34)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if selected_slot == "":
			button.disabled = true
		button.pressed.connect(func(): _equip_to_slot(selected_slot, String(item_id), class_key, action_callback))
		bag_content.add_child(button)


func _select_slot(slot: String, close_callback: Callable) -> void:
	selected_slot = slot
	close_callback.call()


func _equip_to_slot(slot: String, item_id: String, class_key: String, action_callback: Callable) -> void:
	selected_slot = ""
	action_callback.call(class_key, slot, item_id)