extends RefCounted
class_name EncyclopediaIndexService

const RuntimeCatalog = preload("res://scripts/core/runtime_catalog.gd")
const TraitCatalog = preload("res://scripts/core/trait_catalog.gd")

const INDEX_SCHEMA_VERSION := 1
const DOMAINS := ["skills", "weapons", "items", "monsters", "traits"]

var catalog: RuntimeCatalog = RuntimeCatalog.new()


func _init(catalog_instance: RuntimeCatalog = null) -> void:
	if catalog_instance != null:
		catalog = catalog_instance


func build_index(extra_content: Dictionary = {}) -> Dictionary:
	var index := {
		"skills": {},
		"weapons": {},
		"items": {},
		"monsters": {},
		"traits": {}
	}
	var skills := catalog.runtime_table("skills")
	for skill_id in skills.keys():
		index["skills"][String(skill_id)] = _entry("skill", String(skill_id), skills[skill_id], "DataCatalog.SKILLS")
	var innate_skills := catalog.innate_skills_table()
	for skill_id in innate_skills.keys():
		var normalized_id := String(skill_id)
		if not index["skills"].has(normalized_id):
			index["skills"][normalized_id] = _entry("skill", normalized_id, innate_skills[skill_id], "DataCatalog.INNATE_SKILLS")
	var weapons := catalog.runtime_table("weapons")
	for weapon_id in weapons.keys():
		index["weapons"][String(weapon_id)] = _entry("weapon", String(weapon_id), weapons[weapon_id], "DataCatalog.WEAPON_PROFILES")
	var consumables := catalog.runtime_table("consumables")
	for item_id in consumables.keys():
		index["items"][String(item_id)] = _entry("item", String(item_id), consumables[item_id], "DataCatalog.CONSUMABLES")
	var equipment := catalog.runtime_table("equipment")
	for item_id in equipment.keys():
		var normalized_item_id := String(item_id)
		if not index["items"].has(normalized_item_id):
			index["items"][normalized_item_id] = _entry("item", normalized_item_id, equipment[item_id], "DataCatalog.EQUIPMENT")
	var all_units: Array[Dictionary] = catalog.monster_units("normal")
	all_units.append_array(catalog.monster_units("elite"))
	all_units.append_array(catalog.monster_units("boss"))
	for unit in all_units:
		var monster_id := String(unit.get("id", ""))
		if monster_id != "":
			index["monsters"][monster_id] = _entry("monster", monster_id, unit, "DataCatalog.MONSTERS")
	for trait_id in TraitCatalog.LABELS.keys():
		var normalized_trait_id := String(trait_id)
		index["traits"][normalized_trait_id] = _entry("trait", normalized_trait_id, {
			"name": TraitCatalog.LABELS[trait_id],
			"description": TraitCatalog.DESCRIPTIONS.get(trait_id, "")
		}, "TraitCatalog")
	_merge_extra_content(index, extra_content)
	return index


func validate_index(index: Dictionary) -> Array[Dictionary]:
	var errors: Array[Dictionary] = []
	for domain in DOMAINS:
		var table: Dictionary = index.get(domain, {})
		for entry_id in table.keys():
			var entry: Dictionary = table[entry_id]
			for field in ["id", "kind", "name_key", "description_key", "tags", "rarity", "unlock_state", "source", "schema_version"]:
				if not entry.has(field):
					errors.append({"domain": domain, "id": String(entry_id), "field": field, "message": "图鉴索引缺少字段。"})
	return errors


func entries(index: Dictionary, domain: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var table: Dictionary = index.get(domain, {})
	for entry_id in table.keys():
		result.append((table[entry_id] as Dictionary).duplicate(true))
	return result


func _entry(kind: String, entry_id: String, data: Dictionary, source: String) -> Dictionary:
	var tags: Array[String] = [kind]
	var content_class := String(data.get("content_class", data.get("class", "")))
	if content_class != "":
		tags.append(content_class)
	var data_kind := String(data.get("kind", data.get("type", "")))
	if data_kind != "":
		tags.append(data_kind)
	var rarity := "common"
	if kind == "monster":
		rarity = String(data.get("rank", "normal"))
	var name_key := String(data.get("name_key", "%s.%s.name" % [kind, entry_id]))
	var description_key := String(data.get("description_key", "%s.%s.description" % [kind, entry_id]))
	return {
		"id": entry_id,
		"kind": kind,
		"name_key": name_key,
		"description_key": description_key,
		"display_name": String(data.get("name", data.get("label", entry_id))),
		"display_description": String(data.get("description", "暂无说明。")),
		"tags": tags,
		"rarity": rarity,
		"unlock_state": {"type": "bestiary", "id": entry_id} if kind == "monster" else {"type": "always"},
		"source": source,
		"schema_version": INDEX_SCHEMA_VERSION
	}


func _merge_extra_content(index: Dictionary, extra_content: Dictionary) -> void:
	for domain in extra_content.keys():
		if not index.has(domain) or typeof(extra_content[domain]) != TYPE_ARRAY:
			continue
		for raw_entry in extra_content[domain]:
			if typeof(raw_entry) != TYPE_DICTIONARY:
				continue
			var entry: Dictionary = raw_entry
			var entry_id := String(entry.get("id", ""))
			if entry_id == "":
				continue
			index[domain][entry_id] = _entry(String(domain).trim_suffix("s"), entry_id, entry, "Mod")
