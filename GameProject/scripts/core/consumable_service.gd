extends RefCounted
class_name ConsumableService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const StatusService = preload("res://scripts/core/status_service.gd")

const SOURCE_CONSUMABLE := "consumable"
const SOURCE_TOWER_CONSUMABLE := "tower_consumable"


func available_consumables(session: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	_collect_consumables(session, result, session.player.get("consumables", []), SOURCE_CONSUMABLE)
	_collect_consumables(session, result, session.player.get("tower_consumables", []), SOURCE_TOWER_CONSUMABLE)
	return result


func use_consumable(session: Variant, reference: Variant) -> bool:
	session.last_events.clear()
	if session.phase != "battle":
		return false
	if not session._can_act():
		return false
	var item := _find_consumable(session, reference)
	if item.is_empty():
		session.message = "没有找到可用消耗品。"
		return false
	var result := _apply_effect(session, item)
	if not bool(result.get("used", false)):
		session.message = String(result.get("message", "该消耗品当前无法使用。"))
		return false
	_remove_consumable(session, item)
	session.has_acted = true
	session._consume_state_after_action("item")
	var item_name := String(item.get("name", item.get("item_id", "消耗品")))
	var effect_message := String(result.get("message", "已使用。"))
	session.battle_log.append("使用%s：%s" % [item_name, effect_message])
	session.message = "%s：%s" % [item_name, effect_message]
	var event_kind := String(result.get("event_kind", "buff"))
	session.last_events.append({
		"kind": event_kind,
		"target": "player",
		"amount": int(result.get("amount", 0))
	})
	session._after_player_action()
	return true


func _collect_consumables(session: Variant, result: Array[Dictionary], raw_items: Array, source_type: String) -> void:
	for index in range(raw_items.size()):
		var raw_item: Variant = raw_items[index]
		var item_id := String(raw_item.get("id", "")) if typeof(raw_item) == TYPE_DICTIONARY else String(raw_item)
		if item_id == "" or not DataCatalog.CONSUMABLES.has(item_id):
			continue
		var item: Dictionary = DataCatalog.CONSUMABLES[item_id].duplicate(true)
		var upgraded := typeof(raw_item) == TYPE_DICTIONARY and bool(raw_item.get("upgraded", false))
		if upgraded:
			item["value"] = _upgraded_value(item.get("value", 0))
			item["name"] = "强化" + String(item.get("name", "物品"))
		if String(item.get("kind", "")).begins_with("charge_"):
			continue
		item["consumable_id"] = "%s:%d" % [source_type, index]
		item["source_type"] = source_type
		item["source_index"] = index
		item["item_id"] = item_id
		item["upgraded"] = upgraded
		item["source_label"] = "消耗栏 %d" % (index + 1) if source_type == SOURCE_CONSUMABLE else "塔内物品"
		result.append(item)


func _find_consumable(session: Variant, reference: Variant) -> Dictionary:
	var requested_id := ""
	if typeof(reference) == TYPE_INT:
		requested_id = "%s:%d" % [SOURCE_CONSUMABLE, int(reference)]
	else:
		requested_id = String(reference)
	for item in available_consumables(session):
		if String(item.get("consumable_id", "")) == requested_id:
			return item
	for item in available_consumables(session):
		if String(item.get("item_id", "")) == requested_id:
			return item
	return {}


func _apply_effect(session: Variant, item: Dictionary) -> Dictionary:
	var kind := String(item.get("kind", ""))
	var value := maxi(0, int(item.get("value", 0)))
	var player: Dictionary = session.player
	match kind:
		"heal":
			var current_hp := int(player.get("hp", 0))
			var max_hp := int(player.get("max_hp", current_hp))
			var resolved_heal: float = session.status_service.resolve_stat(player, float(value), StatusService.STAT_HEAL)
			var amount := mini(int(ceil(resolved_heal)), maxi(0, max_hp - current_hp))
			if amount <= 0:
				return {"used": false, "message": "生命值已满。"}
			player["hp"] = current_hp + amount
			return {"used": true, "event_kind": "heal", "amount": amount, "message": "恢复 %d 点生命" % amount}
		"armor":
			_add_stat_status(session, item, StatusService.STAT_ARMOR, value)
			return {"used": true, "event_kind": "buff", "amount": value, "message": "护甲提升 %d" % value}
		"dodge":
			session._add_player_dodge(value)
			return {"used": true, "event_kind": "dodge", "amount": value, "message": "获得 %d 层闪避" % value}
		"attack":
			_add_stat_status(session, item, StatusService.STAT_ATTACK, value)
			return {"used": true, "event_kind": "buff", "amount": value, "message": "攻击提升 %d" % value}
		"skill":
			var current_energy := int(session.energy)
			var energy_amount := mini(value, maxi(0, DataCatalog.ENERGY_MAX - current_energy))
			if energy_amount <= 0:
				return {"used": false, "message": "能量已满。"}
			session.energy = current_energy + energy_amount
			return {"used": true, "event_kind": "energy", "amount": energy_amount, "message": "恢复 %d 点能量" % energy_amount}
		"block":
			session._add_player_block(value)
			return {"used": true, "event_kind": "defense", "amount": value, "message": "获得 %d 点格挡" % value}
	return {"used": false, "message": "该消耗品效果尚未定义。"}


func _add_stat_status(session: Variant, item: Dictionary, stat: String, value: int) -> void:
	var item_ref := String(item.get("consumable_id", item.get("item_id", "consumable")))
	session.status_service.add_status(session.player, {
		"id": "consumable:%s" % item_ref,
		"name": String(item.get("name", "消耗品")),
		"kind": "buff",
		"stack": "replace",
		"effects": [{"stat": stat, "type": StatusService.EFFECT_FLAT, "value": value}],
		"duration": -1
	})


func _remove_consumable(session: Variant, item: Dictionary) -> void:
	var source_type := String(item.get("source_type", ""))
	var source_index := int(item.get("source_index", -1))
	var field := "consumables" if source_type == SOURCE_CONSUMABLE else "tower_consumables"
	var items: Array = session.player.get(field, [])
	if source_index < 0 or source_index >= items.size():
		return
	if source_type == SOURCE_CONSUMABLE:
		items[source_index] = ""
	else:
		items[source_index] = ""
	session.player[field] = items


func _upgraded_value(raw_value: Variant) -> int:
	return int(round(float(raw_value) * 1.5))
