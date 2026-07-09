extends RefCounted
class_name ItemCollectionView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const UIHelpers = preload("res://scripts/ui/ui_helpers.gd")


func render(root: Control, class_key: String, roster_player: Dictionary, label_factory: Callable, close_callback: Callable) -> void:
	var cls_name := String(DataCatalog.CLASSES[class_key]["name"])
	root.add_child(label_factory.call("%s - 物品收藏" % cls_name, 28))

	var equipment_ids: Array = roster_player.get("equipment_ids", [])
	if equipment_ids.is_empty():
		root.add_child(label_factory.call("暂无收集的装备。", 16))
	else:
		var scroll := ScrollContainer.new()
		scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		root.add_child(scroll)
		var content := VBoxContainer.new()
		content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scroll.add_child(content)
		var by_slot := _group_by_slot(equipment_ids)
		for slot in UIHelpers.SLOTS:
			if not by_slot.has(slot):
				continue
			content.add_child(label_factory.call(UIHelpers.slot_label(slot), 18))
			for item_id in by_slot[slot]:
				var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
				var el: Label = label_factory.call(_item_summary(item), 14)
				el.modulate = Color(0.8, 0.8, 0.8)
				content.add_child(el)

	var close_button := Button.new()
	close_button.text = "返回营地"
	close_button.custom_minimum_size = Vector2(160, 44)
	close_button.pressed.connect(close_callback)
	root.add_child(close_button)


func _group_by_slot(equipment_ids: Array) -> Dictionary:
	var result := {}
	for item_id in equipment_ids:
		if not DataCatalog.EQUIPMENT.has(item_id):
			continue
		var slot := String(DataCatalog.EQUIPMENT[item_id].get("slot", ""))
		if not result.has(slot):
			result[slot] = []
		result[slot].append(item_id)
	return result


func _item_summary(item: Dictionary) -> String:
	var parts: Array[String] = [String(item.get("name", ""))]
	var stats: Array[String] = []
	if int(item.get("hp", 0)) != 0:
		stats.append("HP %+d" % int(item["hp"]))
	if int(item.get("attack", 0)) != 0:
		stats.append("攻击 %+d" % int(item["attack"]))
	if int(item.get("armor", 0)) != 0:
		stats.append("护甲 %+d" % int(item["armor"]))
	if int(item.get("block", 0)) != 0:
		stats.append("格挡 %+d" % int(item["block"]))
	if not stats.is_empty():
		parts.append("（%s）" % "，".join(stats))
	var set_id := String(item.get("set_id", ""))
	if set_id != "" and DataCatalog.EQUIPMENT_SETS.has(set_id):
		parts.append(" 套装：%s" % DataCatalog.EQUIPMENT_SETS[set_id]["name"])
	return "  ".join(parts)