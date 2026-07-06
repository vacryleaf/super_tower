extends RefCounted
class_name EquipmentView

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

const SLOTS := ["head", "body", "waist", "legs", "hands", "leggings", "feet", "weapon", "offhand", "shoulders", "cloak", "necklace", "ring", "ring2"]


func panel(session: Variant, label_factory: Callable, close_callback: Callable) -> Control:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(820, 440)
	var outer := VBoxContainer.new()
	panel.add_child(outer)
	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer.add_child(header)
	header.add_child(label_factory.call("装备", 22))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(84, 38)
	close_button.pressed.connect(close_callback)
	header.add_child(close_button)

	var columns := HBoxContainer.new()
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	outer.add_child(columns)
	_render_body_slots(columns, session, label_factory)
	_render_bag(columns, session, label_factory)
	_render_set_summary(columns, session, label_factory)
	return panel


func target_label(target: Dictionary) -> String:
	var target_type := String(target.get("type", ""))
	var target_id := String(target.get("id", ""))
	if target_type == "equipment" and DataCatalog.EQUIPMENT.has(target_id):
		var item: Dictionary = DataCatalog.EQUIPMENT[target_id]
		return "装备：%s（%s）" % [item["name"], slot_label(item["slot"])]
	if target_type == "skill" and DataCatalog.SKILLS.has(target_id):
		var skill: Dictionary = DataCatalog.SKILLS[target_id]
		return "技能：%s" % skill["name"]
	return target_id


func attachment_summary(session: Variant, target_type: String, target_id: String) -> String:
	var key := "equipment_attachments" if target_type == "equipment" else "skill_attachments"
	var groups: Dictionary = session.player.get(key, {})
	var attachments: Array = groups.get(target_id, [])
	if attachments.is_empty():
		return "附着：无"
	var labels: Array[String] = []
	for attachment in attachments:
		labels.append(String(attachment.get("label", attachment.get("kind", ""))).replace("状态卡", "状态 Buff"))
	return "附着：" + "、".join(labels)


func slot_label(slot: String) -> String:
	var labels := {
		"head": "头部",
		"body": "上身",
		"waist": "腰部",
		"legs": "下身",
		"hands": "手部",
		"leggings": "护腿",
		"feet": "脚部",
		"weapon": "武器",
		"offhand": "副手",
		"shoulders": "肩部",
		"cloak": "披风",
		"necklace": "项链",
		"ring": "戒指1",
		"ring2": "戒指2"
	}
	return labels.get(slot, slot)


func _render_body_slots(parent: Control, session: Variant, label_factory: Callable) -> void:
	var body_slots := VBoxContainer.new()
	body_slots.custom_minimum_size = Vector2(230, 0)
	parent.add_child(body_slots)
	body_slots.add_child(label_factory.call("人体装备栏", 16))
	for slot in SLOTS:
		body_slots.add_child(label_factory.call("%s：%s" % [slot_label(slot), _equipped_name(session, slot)], 13))


func _render_bag(parent: Control, session: Variant, label_factory: Callable) -> void:
	var bag_scroll := ScrollContainer.new()
	bag_scroll.custom_minimum_size = Vector2(300, 0)
	bag_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	parent.add_child(bag_scroll)
	var bag := VBoxContainer.new()
	bag.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bag_scroll.add_child(bag)
	bag.add_child(label_factory.call("本局背包", 16))
	if session.player["equipment_ids"].is_empty():
		bag.add_child(label_factory.call("暂无本局装备。", 13))
	else:
		for item_id in session.player["equipment_ids"]:
			var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
			bag.add_child(label_factory.call("%s%s\n%s  生命+%d 攻击+%d 护甲+%d 格挡+%d\n%s" % [
				item["name"],
				_set_suffix(item),
				slot_label(item["slot"]),
				int(item["hp"]),
				int(item["attack"]),
				int(item["armor"]),
				int(item.get("block", 0)),
				attachment_summary(session, "equipment", item_id)
			], 12))
	bag.add_child(label_factory.call("技能附着", 16))
	for skill_id in session.player["equipped_skills"]:
		bag.add_child(label_factory.call("%s\n%s" % [
			DataCatalog.SKILLS[skill_id]["name"],
			attachment_summary(session, "skill", skill_id)
		], 12))


func _render_set_summary(parent: Control, session: Variant, label_factory: Callable) -> void:
	var set_box := VBoxContainer.new()
	set_box.custom_minimum_size = Vector2(220, 0)
	parent.add_child(set_box)
	set_box.add_child(label_factory.call("套装", 16))
	var set_counts: Dictionary = session.player.get("set_counts", {})
	if set_counts.is_empty():
		set_box.add_child(label_factory.call("暂无套装。", 13))
		return
	for set_id in set_counts.keys():
		if not DataCatalog.EQUIPMENT_SETS.has(set_id):
			continue
		var set_data: Dictionary = DataCatalog.EQUIPMENT_SETS[set_id]
		set_box.add_child(label_factory.call("%s（%d件）" % [set_data["name"], int(set_counts[set_id])], 13))
		var bonuses: Dictionary = set_data.get("bonuses", {})
		for threshold in bonuses.keys():
			var bonus: Dictionary = bonuses[threshold]
			var active := int(set_counts[set_id]) >= int(threshold)
			set_box.add_child(label_factory.call("%s%d件：%s" % ["已激活 " if active else "", int(threshold), bonus.get("label", "")], 12))


func _set_suffix(item: Dictionary) -> String:
	var set_id := String(item.get("set_id", ""))
	if set_id == "" or not DataCatalog.EQUIPMENT_SETS.has(set_id):
		return ""
	return "（%s）" % DataCatalog.EQUIPMENT_SETS[set_id]["name"]


func _equipped_name(session: Variant, slot: String) -> String:
	var equipment: Dictionary = session.player.get("equipment", {})
	if equipment.has(slot):
		var item_id: String = equipment[slot]
		return DataCatalog.EQUIPMENT[item_id]["name"]
	return "空"
