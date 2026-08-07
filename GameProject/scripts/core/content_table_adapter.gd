extends RefCounted
class_name ContentTableAdapter

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

const TABLE_STATE_CARDS := "state_cards"
const TABLE_CLASSES := "classes"
const TABLE_SKILLS := "skills"
const TABLE_WEAPONS := "weapons"
const TABLE_MONSTERS := "monsters"
const TABLE_ITEMS := "items"
const TABLE_EQUIPMENT := "equipment"
const TABLE_CONSUMABLES := "consumables"
const TABLE_PASSIVE_SKILLS := "passive_skills"
const TABLE_INNATE_SKILLS := "innate_skills"


# 将表名适配为运行时权威表（键为稳定 ID，值为规范化条目）。
# 仅负责 DataCatalog 静态数据的字典化，不参与外部表或 Mod 解析。
func table(table_name: String) -> Dictionary:
	match table_name:
		TABLE_STATE_CARDS:
			return DataCatalog.STATE_CARDS.duplicate(true)
		TABLE_CLASSES:
			return DataCatalog.CLASSES.duplicate(true)
		TABLE_SKILLS:
			return DataCatalog.SKILLS.duplicate(true)
		TABLE_WEAPONS:
			return _weapons_table()
		TABLE_MONSTERS:
			return _monsters_table()
		TABLE_ITEMS:
			return _items_table()
		TABLE_EQUIPMENT:
			return DataCatalog.EQUIPMENT.duplicate(true)
		TABLE_CONSUMABLES:
			return DataCatalog.CONSUMABLES.duplicate(true)
		TABLE_PASSIVE_SKILLS:
			return DataCatalog.PASSIVE_SKILLS.duplicate(true)
		TABLE_INNATE_SKILLS:
			return DataCatalog.INNATE_SKILLS.duplicate(true)
	return {}


# 当前适配器是否支持该表名。
func supports(table_name: String) -> bool:
	match table_name:
		TABLE_STATE_CARDS, TABLE_CLASSES, TABLE_SKILLS, TABLE_WEAPONS, TABLE_MONSTERS, TABLE_ITEMS, TABLE_EQUIPMENT, TABLE_CONSUMABLES, TABLE_PASSIVE_SKILLS, TABLE_INNATE_SKILLS:
			return true
	return false


func _weapons_table() -> Dictionary:
	return DataCatalog.WEAPON_PROFILES.duplicate(true)


func _monsters_table() -> Dictionary:
	var result: Dictionary = {}
	_add_units(result, DataCatalog.NORMAL_UNITS)
	_add_units(result, DataCatalog.ELITE_UNITS)
	_add_units(result, DataCatalog.BOSS_UNITS)
	return result


func _items_table() -> Dictionary:
	var result: Dictionary = DataCatalog.EQUIPMENT.duplicate(true)
	for item_id in DataCatalog.CONSUMABLES.keys():
		result[String(item_id)] = (DataCatalog.CONSUMABLES[item_id] as Dictionary).duplicate(true)
	return result


func _add_units(target: Dictionary, units: Array) -> void:
	for unit in units:
		if typeof(unit) == TYPE_DICTIONARY:
			target[String((unit as Dictionary).get("id", ""))] = (unit as Dictionary).duplicate(true)
