extends RefCounted
class_name RuntimeCatalog

const CatalogMigrationService = preload("res://scripts/core/catalog_migration_service.gd")
const ContentTableAdapter = preload("res://scripts/core/content_table_adapter.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const ModLoader = preload("res://scripts/core/mod_loader.gd")

# 表名 → Mod 内容领域；只有这些表支持 Mod 扩展内容。
const MOD_DOMAIN_BY_TABLE := {
	"skills": "skills",
	"weapons": "weapons",
	"monsters": "monsters",
	"items": "items"
}

var migration := CatalogMigrationService.new()
var adapter := ContentTableAdapter.new()
var loader: ModLoader


func _init(mods_root: String = "user://mods") -> void:
	loader = ModLoader.new(mods_root)


# 发现并注册 mods_root 下所有合法 Mod，返回成功注册的 Mod ID。
func load_mods() -> Array[String]:
	var registered: Array[String] = []
	for record in loader.discover_mods():
		var mod_id := String(record.get("id", ""))
		if loader.register_content(mod_id):
			registered.append(mod_id)
	return registered


# 按稳定 ID 查询规范化条目；Mod 内容优先，其次已迁移的完整外部表，最后运行时表。
# 找不到时返回空字典，避免调用方直接读取原始来源。
func entry(table_name: String, entry_id: String) -> Dictionary:
	var mod_entry := _mod_entry(table_name, entry_id)
	if not mod_entry.is_empty():
		return mod_entry
	var resolved := resolved_table(table_name)
	if resolved.has(entry_id):
		return (resolved[entry_id] as Dictionary).duplicate(true)
	return {}


func has(table_name: String, entry_id: String) -> bool:
	return not entry(table_name, entry_id).is_empty()


# 整表：解析后的权威表加上 Mod 扩展条目。
func table(table_name: String) -> Dictionary:
	var result: Dictionary = resolved_table(table_name)
	var mod_table := mod_content_table(table_name)
	for content_id in mod_table.keys():
		result[String(content_id)] = (mod_table[content_id] as Dictionary).duplicate(true)
	return result


# 解析后的权威表：外部表仅在 parity 完整时替换运行时表，否则回退运行时表。
func resolved_table(table_name: String) -> Dictionary:
	return migration.resolve_table(table_name, adapter.table(table_name), true)


# 纯运行时表（DataCatalog 权威），不经过外部表解析。
func runtime_table(table_name: String) -> Dictionary:
	return adapter.table(table_name)


func external_table(table_name: String) -> Dictionary:
	return migration.repository.table(table_name)


func table_status(table_name: String) -> String:
	return migration.table_status(table_name)


func can_use_external(table_name: String) -> bool:
	return migration.can_use_external(table_name)


func parity_report() -> Dictionary:
	return migration.parity_report()


# 表名对应的 Mod 内容表（已注册内容，按稳定 ID 索引）。
func mod_content_table(table_name: String) -> Dictionary:
	var domain := String(MOD_DOMAIN_BY_TABLE.get(table_name, ""))
	if domain == "":
		return {}
	return loader.content_table(domain)


func register_mod(mod_id: String) -> bool:
	return loader.register_content(mod_id)


func active_mod_ids() -> Array[String]:
	return loader.active_mod_ids()


func _mod_entry(table_name: String, entry_id: String) -> Dictionary:
	var mod_table := mod_content_table(table_name)
	if not mod_table.has(entry_id):
		return {}
	return (mod_table[entry_id] as Dictionary).duplicate(true)


# 按 rank 返回有序怪物单位数组（normal/elite/boss），条目与 monsters 表同源。
func monster_units(rank: String) -> Array[Dictionary]:
	var units: Array
	match rank:
		"normal":
			units = DataCatalog.NORMAL_UNITS
		"elite":
			units = DataCatalog.ELITE_UNITS
		"boss":
			units = DataCatalog.BOSS_UNITS
	var result: Array[Dictionary] = []
	for unit in units:
		if typeof(unit) == TYPE_DICTIONARY:
			result.append((unit as Dictionary).duplicate(true))
	return result


func monster_group_ids() -> Array[String]:
	return DataCatalog.monster_group_ids()


func monster_group(group_id: String) -> Dictionary:
	return DataCatalog.monster_group(group_id)


func monster_group_name(group_id: String) -> String:
	return DataCatalog.monster_group_name(group_id)


func monster_group_minion_passive_skills(group_id: String) -> Array:
	return DataCatalog.monster_group_minion_passive_skills(group_id)


# 群组单位经 monsters 表查询，保证运行时与图鉴同源。
func monster_group_units(group_id: String, rank: String) -> Array[Dictionary]:
	var group := monster_group(group_id)
	var ids: Array = group.get("%s_units" % rank, [])
	var units: Array[Dictionary] = []
	for unit_id in ids:
		var unit := entry("monsters", String(unit_id))
		if not unit.is_empty():
			units.append(unit)
	return units


func get_floor_battle_type(index: int) -> String:
	return DataCatalog.get_floor_battle_type(index)


func tutorial_unlock_ids(class_id: String) -> Array:
	return DataCatalog.TUTORIAL_UNLOCKS.get(class_id, [])


func skill_class_compatible(skill: Dictionary, class_id: String) -> bool:
	return DataCatalog.skill_class_compatible(skill, class_id)


func equipment_class_compatible(item: Dictionary, class_id: String) -> bool:
	return DataCatalog.equipment_class_compatible(item, class_id)


func innate_skills_table() -> Dictionary:
	return DataCatalog.INNATE_SKILLS.duplicate(true)
