extends RefCounted
class_name EncounterService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func generate_encounter(tower_floor: int, battle_index: int) -> Dictionary:
	var battle_type := DataCatalog.get_floor_battle_type(battle_index)
	var encounter: Dictionary
	if battle_type == "normal":
		encounter = normal_encounter(tower_floor, battle_index)
	elif battle_type == "elite":
		encounter = elite_encounter(tower_floor, battle_index)
	else:
		encounter = boss_encounter(tower_floor)
	return apply_battle_pressure(encounter, battle_index)


func normal_encounter(tower_floor: int, battle_index: int) -> Dictionary:
	var selector := (tower_floor + battle_index) % 5
	if selector == 0 and tower_floor >= 3:
		return formation("enc_normal_goblin_team", "normal", [
			low_unit("哥布林盾矛手", 0.52, ["tank", "taunt"]),
			low_unit("哥布林投石手", 0.50, ["backline"]),
			low_unit("哥布林斥候", 0.46, ["first_strike", "evade"])
		])
	if selector == 1 and tower_floor >= 4:
		return formation_from_units("enc_normal_guard_pair", "normal", [2, 3], [0.62, 0.62])
	if selector == 2 and tower_floor >= 5:
		return formation_from_units("enc_normal_shadow_pair", "normal", [4, 5], [0.62, 0.62])
	var unit: Dictionary = DataCatalog.NORMAL_UNITS[(tower_floor + battle_index) % DataCatalog.NORMAL_UNITS.size()]
	return formation_from_unit("enc_normal_standard_%d_%d" % [tower_floor, battle_index], "normal", unit, 1.0)


func elite_encounter(tower_floor: int, battle_index: int) -> Dictionary:
	if tower_floor >= 6 and battle_index == 8:
		var elite_unit: Dictionary = DataCatalog.ELITE_UNITS[(tower_floor + battle_index) % DataCatalog.ELITE_UNITS.size()]
		var normal_unit: Dictionary = DataCatalog.NORMAL_UNITS[(tower_floor + battle_index + 2) % DataCatalog.NORMAL_UNITS.size()]
		return formation("enc_elite_pair_%d_%d" % [tower_floor, battle_index], "elite", [
			prepare_unit(elite_unit, "elite", 0.72),
			prepare_unit(normal_unit, "normal", 0.62)
		])
	var unit: Dictionary = DataCatalog.ELITE_UNITS[(tower_floor + battle_index) % DataCatalog.ELITE_UNITS.size()]
	return formation_from_unit("enc_elite_solo_%d_%d" % [tower_floor, battle_index], "elite", unit, 1.0)


func boss_encounter(tower_floor: int) -> Dictionary:
	var boss_unit: Dictionary = DataCatalog.BOSS_UNITS[tower_floor % DataCatalog.BOSS_UNITS.size()]
	if tower_floor >= 7 and tower_floor % 2 == 1:
		var add_1: Dictionary = DataCatalog.NORMAL_UNITS[tower_floor % DataCatalog.NORMAL_UNITS.size()]
		var add_2: Dictionary = DataCatalog.NORMAL_UNITS[(tower_floor + 1) % DataCatalog.NORMAL_UNITS.size()]
		return formation("enc_boss_group_%d" % tower_floor, "boss", [
			prepare_unit(boss_unit, "boss", 0.82),
			prepare_unit(add_1, "normal", 0.48),
			prepare_unit(add_2, "normal", 0.48)
		])
	return formation_from_unit("enc_boss_solo_%d" % tower_floor, "boss", boss_unit, 1.0)


func formation_from_units(id: String, battle_type: String, indexes: Array[int], scales: Array[float]) -> Dictionary:
	var units: Array[Dictionary] = []
	for i in indexes.size():
		units.append(prepare_unit(DataCatalog.NORMAL_UNITS[indexes[i] % DataCatalog.NORMAL_UNITS.size()], "normal", scales[i]))
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
		"formation_scale": scale,
		"traits": source.get("traits", []),
		"skills": source.get("skills", [])
	}


func low_unit(unit_name: String, scale: float, traits: Array) -> Dictionary:
	return {
		"name": unit_name,
		"rank": "normal",
		"hp": 0.60,
		"attack": 0.75,
		"defense": 0.35,
		"formation_scale": scale,
		"traits": traits.filter(func(value): return value != ""),
		"skills": []
	}


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
	return 1.0 + 0.08 * float(battle_index - 3)
