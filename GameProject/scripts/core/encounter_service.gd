extends RefCounted
class_name EncounterService

const RuntimeCatalog = preload("res://scripts/core/runtime_catalog.gd")

var catalog: RuntimeCatalog = RuntimeCatalog.new()


func _init(catalog_instance: RuntimeCatalog = null) -> void:
	if catalog_instance != null:
		catalog = catalog_instance


func select_floor_group_id(rng: Variant = null) -> String:
	var group_ids := catalog.monster_group_ids()
	if group_ids.is_empty():
		return ""
	if rng != null and rng is RandomNumberGenerator:
		var generator: RandomNumberGenerator = rng
		return String(group_ids[generator.randi_range(0, group_ids.size() - 1)])
	return String(group_ids[0])


func generate_encounter(tower_floor: int, battle_index: int, floor_group_id: String = "") -> Dictionary:
	var group_id := floor_group_id if floor_group_id != "" else select_floor_group_id()
	var battle_type := catalog.get_floor_battle_type(battle_index)
	var encounter: Dictionary
	if battle_type == "normal":
		encounter = normal_encounter(tower_floor, battle_index, group_id)
	elif battle_type == "elite":
		encounter = elite_encounter(tower_floor, battle_index, group_id)
	else:
		encounter = boss_encounter(tower_floor, group_id)
	encounter["group_id"] = group_id
	encounter["group_name"] = catalog.monster_group_name(group_id)
	return apply_battle_pressure(encounter, battle_index)


func normal_encounter(tower_floor: int, battle_index: int, group_id: String) -> Dictionary:
	if battle_index >= 7 and tower_floor >= 3:
		return formation("enc_%s_group_%d_%d" % [group_id, tower_floor, battle_index], "normal", _group_squad(group_id, 3, [0.52, 0.50, 0.46]))
	if battle_index >= 4 and tower_floor >= 5:
		return formation("enc_%s_pair_%d_%d" % [group_id, tower_floor, battle_index], "normal", _group_squad(group_id, 2, [0.62, 0.62]))
	if battle_index >= 4 and tower_floor >= 4:
		return formation("enc_%s_pair_%d_%d" % [group_id, tower_floor, battle_index], "normal", _group_squad(group_id, 2, [0.62, 0.62]))
	var unit := _group_unit(group_id, "normal", tower_floor + battle_index)
	if unit.is_empty():
		return formation("enc_%s_standard_%d_%d" % [group_id, tower_floor, battle_index], "normal", [_group_low_unit(group_id, 1.0)])
	return formation_from_unit("enc_%s_standard_%d_%d" % [group_id, tower_floor, battle_index], "normal", unit, 1.0)


func elite_encounter(tower_floor: int, battle_index: int, group_id: String) -> Dictionary:
	if tower_floor >= 6 and battle_index == 8:
		var elite_unit := _group_unit(group_id, "elite", tower_floor + battle_index)
		var normal_unit := _group_unit(group_id, "normal", tower_floor + battle_index + 2)
		var units: Array[Dictionary] = []
		if not elite_unit.is_empty():
			units.append(prepare_unit(elite_unit, "elite", 0.72))
		else:
			units.append(_group_low_unit(group_id, 0.72))
		if not normal_unit.is_empty():
			units.append(prepare_unit(normal_unit, "normal", 0.62))
		else:
			units.append(_group_low_unit(group_id, 0.62))
		return formation("enc_%s_elite_pair_%d_%d" % [group_id, tower_floor, battle_index], "elite", units)
	var unit := _group_unit(group_id, "elite", tower_floor + battle_index)
	if unit.is_empty():
		return formation("enc_%s_elite_solo_%d_%d" % [group_id, tower_floor, battle_index], "elite", [_group_low_unit(group_id, 1.0)])
	return formation_from_unit("enc_%s_elite_solo_%d_%d" % [group_id, tower_floor, battle_index], "elite", unit, 1.0)


func boss_encounter(tower_floor: int, group_id: String) -> Dictionary:
	var boss_unit := _group_unit(group_id, "boss", tower_floor)
	if boss_unit.is_empty():
		var boss_units := catalog.monster_units("boss")
		if not boss_units.is_empty():
			boss_unit = boss_units[tower_floor % boss_units.size()]
	if tower_floor >= 7 and tower_floor % 2 == 1:
		var units: Array[Dictionary] = [
			prepare_unit(boss_unit, "boss", 0.82)
		]
		units.append_array(_group_squad(group_id, 2, [0.48, 0.48]))
		return formation("enc_%s_boss_group_%d" % [group_id, tower_floor], "boss", units)
	return formation_from_unit("enc_%s_boss_solo_%d" % [group_id, tower_floor], "boss", boss_unit, 1.0)


func formation_from_units(id: String, battle_type: String, indexes: Array[int], scales: Array[float]) -> Dictionary:
	var units: Array[Dictionary] = []
	var normal_units := catalog.monster_units("normal")
	for i in indexes.size():
		units.append(prepare_unit(normal_units[indexes[i] % normal_units.size()], "normal", scales[i]))
	return formation(id, battle_type, units)


func formation_from_unit(id: String, battle_type: String, unit: Dictionary, scale: float) -> Dictionary:
	return formation(id, battle_type, [prepare_unit(unit, battle_type, scale)])


func formation(id: String, battle_type: String, units: Array[Dictionary]) -> Dictionary:
	return {
		"id": id,
		"type": battle_type,
		"units": units
	}


func prepare_unit(source: Dictionary, rank: String, scale: float) -> Dictionary:
	return {
		"id": source.get("id", source.get("name", "unit")),
		"name": source.get("name", "unit"),
		"rank": rank,
		"hp": source.get("hp", 1.0),
		"attack": source.get("attack", 1.0),
		"defense": source.get("defense", 1.0),
		"block_power": source.get("block_power", 0),
		"fixed_stats": source.get("fixed_stats", false),
		"formation_scale": scale,
		"passive_skills": source.get("passive_skills", source.get("traits", [])),
		"skills": source.get("skills", []),
		"behavior_weights": source.get("behavior_weights", {})
	}


func low_unit(unit_name: String, scale: float, passive_skills: Array) -> Dictionary:
	return {
		"name": unit_name,
		"rank": "normal",
		"hp": 0.60,
		"attack": 0.75,
		"defense": 0.35,
		"formation_scale": scale,
		"passive_skills": passive_skills.filter(func(value): return value != ""),
		"skills": []
	}


func _group_unit(group_id: String, rank: String, index: int) -> Dictionary:
	var units := catalog.monster_group_units(group_id, rank)
	if units.is_empty():
		return {}
	return units[index % units.size()]


func _group_squad(group_id: String, count: int, scales: Array[float]) -> Array[Dictionary]:
	var units: Array[Dictionary] = catalog.monster_group_units(group_id, "normal")
	var result: Array[Dictionary] = []
	for i in range(count):
		var scale := scales[i]
		if not units.is_empty() and i < units.size():
			result.append(prepare_unit(units[i], "normal", scale))
		else:
			result.append(_group_low_unit(group_id, scale))
	return result


func _group_low_unit(group_id: String, scale: float) -> Dictionary:
	var group_name := catalog.monster_group_name(group_id)
	var passive_skills := catalog.monster_group_minion_passive_skills(group_id)
	return low_unit("%s杂兵" % group_name, scale, passive_skills)


func apply_battle_pressure(encounter: Dictionary, battle_index: int) -> Dictionary:
	var pressure := battle_pressure_scale(battle_index)
	if pressure <= 1.0:
		return encounter
	for unit in encounter["units"]:
		unit["formation_scale"] = float(unit.get("formation_scale", 1.0)) * pressure
	encounter["pressure"] = pressure
	return encounter


func battle_pressure_scale(battle_index: int) -> float:
	if battle_index <= 3:
		return 1.0
	# 后半段战斗必须克服同一群落单位轮换带来的基础属性波动，
	# 因此从第 4 场开始使用独立的递增压力曲线，确保后半段平均威胁高于开场。
	return 1.40 + 0.10 * float(battle_index - 4)
