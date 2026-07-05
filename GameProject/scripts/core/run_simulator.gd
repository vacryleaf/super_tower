extends RefCounted
class_name RunSimulator

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const CombatEngine = preload("res://scripts/core/combat_engine.gd")

var combat := CombatEngine.new()


func create_character(class_id: String) -> Dictionary:
	var class_data: Dictionary = DataCatalog.CLASSES[class_id]
	var player := {
		"class_id": class_id,
		"base_max_hp": int(class_data["max_hp"]),
		"base_attack": int(class_data["base_attack"]),
		"base_defense": int(class_data["base_defense"]),
		"max_hp_bonus": 0,
		"attack_bonus": 0,
		"defense_bonus": 0,
		"skill_bonus": 0,
		"state_attack_bonus": 0,
		"state_defense_bonus": 0,
		"equipment": {},
		"equipment_ids": [],
		"unlocked_skills": [],
		"equipped_skills": [],
		"tutorial_completed": false,
		"battles_completed": 0,
		"boss_rewards": 0,
		"normal_rewards": 0,
		"elite_rewards": 0,
		"tutorial_restarts": 0
	}
	_recalculate_player_stats(player, true)
	return player


func run_tutorial(class_id: String) -> Dictionary:
	var player := create_character(class_id)
	var battle_results: Array[Dictionary] = []
	for i in DataCatalog.TUTORIAL_ENCOUNTERS.size():
		var encounter: Dictionary = DataCatalog.TUTORIAL_ENCOUNTERS[i]
		var result := combat.run_battle(player, encounter, 1, i + 1)
		if not result["victory"]:
			player["tutorial_restarts"] += 1
			player["hp"] = player["max_hp"]
			result = combat.run_battle(player, encounter, 1, i + 1)
		if not result["victory"]:
			return _failure(player, "tutorial battle %d failed" % (i + 1), battle_results)
		battle_results.append(result)
		_apply_tutorial_unlock(player, i)
		player["battles_completed"] += 1
	player["tutorial_completed"] = true
	player["hp"] = player["max_hp"]
	return {
		"success": true,
		"player": player,
		"battle_results": battle_results,
		"tutorial_restarts": int(player["tutorial_restarts"])
	}


func run_campaign(class_id: String, target_floor: int = 10) -> Dictionary:
	var tutorial := run_tutorial(class_id)
	if not tutorial["success"]:
		return tutorial

	var player: Dictionary = tutorial["player"]
	var floor_summaries: Array[Dictionary] = [{
		"floor": 1,
		"tutorial": true,
		"battles": 10,
		"victory": true
	}]

	for floor in range(2, target_floor + 1):
		var floor_result := run_formal_floor(player, floor)
		floor_summaries.append(floor_result)
		if not floor_result["victory"]:
			return {
				"success": false,
				"failed_floor": floor,
				"player": player,
				"floor_summaries": floor_summaries,
				"hp": int(player["hp"]),
				"max_hp": int(player["max_hp"])
			}

	return {
		"success": true,
		"player": player,
		"floor_summaries": floor_summaries,
		"floors_completed": target_floor,
		"battles_completed": int(player["battles_completed"]),
		"hp": int(player["hp"]),
		"max_hp": int(player["max_hp"]),
		"normal_rewards": int(player["normal_rewards"]),
		"elite_rewards": int(player["elite_rewards"]),
		"boss_rewards": int(player["boss_rewards"])
	}


func run_formal_floor(player: Dictionary, tower_floor: int) -> Dictionary:
	var battle_summaries: Array[Dictionary] = []
	for battle_index in range(1, 11):
		var encounter := generate_encounter(tower_floor, battle_index)
		var result := combat.run_battle(player, encounter, tower_floor, battle_index)
		if not result["victory"]:
			return {
				"floor": tower_floor,
				"battle": battle_index,
				"encounter": encounter["id"],
				"victory": false,
				"battles": battle_summaries.size(),
				"hp": int(player["hp"])
			}
		_apply_formal_reward(player, encounter["type"], tower_floor)
		player["battles_completed"] += 1
		battle_summaries.append({
			"battle": battle_index,
			"type": encounter["type"],
			"id": encounter["id"],
			"enemies": result["enemies_total"],
			"rounds": result["rounds"],
			"hp": int(player["hp"])
		})
	return {
		"floor": tower_floor,
		"tutorial": false,
		"victory": true,
		"battles": battle_summaries.size(),
		"battle_summaries": battle_summaries,
		"hp": int(player["hp"]),
		"max_hp": int(player["max_hp"])
	}


func generate_encounter(tower_floor: int, battle_index: int) -> Dictionary:
	var battle_type := DataCatalog.get_floor_battle_type(battle_index)
	if battle_type == "normal":
		return _normal_encounter(tower_floor, battle_index)
	if battle_type == "elite":
		return _elite_encounter(tower_floor, battle_index)
	return _boss_encounter(tower_floor)


func _normal_encounter(tower_floor: int, battle_index: int) -> Dictionary:
	var selector := (tower_floor + battle_index) % 5
	if selector == 0 and tower_floor >= 3:
		return _formation("enc_normal_goblin_team", "normal", [
			_low_unit("Goblin Spear", 0.48, [""]),
			_low_unit("Goblin Stone", 0.48, []),
			_low_unit("Goblin Scout", 0.48, ["first_strike"])
		])
	if selector == 1 and tower_floor >= 4:
		return _formation_from_units("enc_normal_guard_pair", "normal", [2, 3], [0.62, 0.62])
	if selector == 2 and tower_floor >= 5:
		return _formation_from_units("enc_normal_shadow_pair", "normal", [4, 5], [0.62, 0.62])
	var unit: Dictionary = DataCatalog.NORMAL_UNITS[(tower_floor + battle_index) % DataCatalog.NORMAL_UNITS.size()]
	return _formation_from_unit("enc_normal_standard_%d_%d" % [tower_floor, battle_index], "normal", unit, 1.0)


func _elite_encounter(tower_floor: int, battle_index: int) -> Dictionary:
	if tower_floor >= 6 and battle_index == 8:
		var elite_unit: Dictionary = DataCatalog.ELITE_UNITS[(tower_floor + battle_index) % DataCatalog.ELITE_UNITS.size()]
		var normal_unit: Dictionary = DataCatalog.NORMAL_UNITS[(tower_floor + battle_index + 2) % DataCatalog.NORMAL_UNITS.size()]
		return _formation("enc_elite_pair_%d_%d" % [tower_floor, battle_index], "elite", [
			_prepare_unit(elite_unit, "elite", 0.72),
			_prepare_unit(normal_unit, "normal", 0.62)
		])
	var unit: Dictionary = DataCatalog.ELITE_UNITS[(tower_floor + battle_index) % DataCatalog.ELITE_UNITS.size()]
	return _formation_from_unit("enc_elite_solo_%d_%d" % [tower_floor, battle_index], "elite", unit, 1.0)


func _boss_encounter(tower_floor: int) -> Dictionary:
	var boss_unit: Dictionary = DataCatalog.BOSS_UNITS[tower_floor % DataCatalog.BOSS_UNITS.size()]
	if tower_floor >= 7 and tower_floor % 2 == 1:
		var add_1: Dictionary = DataCatalog.NORMAL_UNITS[tower_floor % DataCatalog.NORMAL_UNITS.size()]
		var add_2: Dictionary = DataCatalog.NORMAL_UNITS[(tower_floor + 1) % DataCatalog.NORMAL_UNITS.size()]
		return _formation("enc_boss_group_%d" % tower_floor, "boss", [
			_prepare_unit(boss_unit, "boss", 0.82),
			_prepare_unit(add_1, "normal", 0.48),
			_prepare_unit(add_2, "normal", 0.48)
		])
	return _formation_from_unit("enc_boss_solo_%d" % tower_floor, "boss", boss_unit, 1.0)


func _formation_from_units(id: String, battle_type: String, indexes: Array[int], scales: Array[float]) -> Dictionary:
	var units: Array[Dictionary] = []
	for i in indexes.size():
		units.append(_prepare_unit(DataCatalog.NORMAL_UNITS[indexes[i] % DataCatalog.NORMAL_UNITS.size()], "normal", scales[i]))
	return _formation(id, battle_type, units)


func _formation_from_unit(id: String, battle_type: String, unit: Dictionary, scale: float) -> Dictionary:
	return _formation(id, battle_type, [_prepare_unit(unit, battle_type, scale)])


func _formation(id: String, battle_type: String, units: Array[Dictionary]) -> Dictionary:
	return {
		"id": id,
		"type": battle_type,
		"units": units
	}


func _prepare_unit(source: Dictionary, rank: String, scale: float) -> Dictionary:
	return {
		"id": source.get("id", source.get("name", "unit")),
		"name": source.get("name", "unit"),
		"rank": rank,
		"hp": source.get("hp", 1.0),
		"attack": source.get("attack", 1.0),
		"defense": source.get("defense", 1.0),
		"formation_scale": scale,
		"traits": source.get("traits", [])
	}


func _low_unit(unit_name: String, scale: float, traits: Array) -> Dictionary:
	return {
		"name": unit_name,
		"rank": "normal",
		"hp": 0.60,
		"attack": 0.75,
		"defense": 0.35,
		"formation_scale": scale,
		"traits": traits.filter(func(value): return value != "")
	}


func _apply_tutorial_unlock(player: Dictionary, battle_zero_index: int) -> void:
	var class_id: String = player["class_id"]
	var unlocks: Array = DataCatalog.TUTORIAL_UNLOCKS[class_id]
	var unlock_id: String = unlocks[battle_zero_index]
	if DataCatalog.EQUIPMENT.has(unlock_id):
		equip_item(player, unlock_id)
	elif DataCatalog.SKILLS.has(unlock_id):
		unlock_skill(player, unlock_id, true)
	_recalculate_player_stats(player, false)


func _apply_formal_reward(player: Dictionary, battle_type: String, tower_floor: int) -> void:
	var fixed_scale := maxi(0, int(floor(float(tower_floor - 1) / 10.0)))
	if battle_type == "normal":
		player["attack_bonus"] += 2 + fixed_scale
		player["defense_bonus"] += 1 + fixed_scale
		player["max_hp_bonus"] += 5 + fixed_scale
		player["normal_rewards"] += 1
	elif battle_type == "elite":
		player["attack_bonus"] += 4 + fixed_scale
		player["defense_bonus"] += 3 + fixed_scale
		player["max_hp_bonus"] += 8 + fixed_scale
		player["state_attack_bonus"] += 1
		player["elite_rewards"] += 1
	else:
		player["attack_bonus"] += 8 + fixed_scale
		player["defense_bonus"] += 6 + fixed_scale
		player["max_hp_bonus"] += 20 + fixed_scale
		player["skill_bonus"] += 2
		_unlock_next_skill(player)
		player["boss_rewards"] += 1
	_recalculate_player_stats(player, false)
	player["hp"] = mini(int(player["max_hp"]), int(player["hp"]) + _reward_heal_amount(battle_type, player))


func _reward_heal_amount(battle_type: String, player: Dictionary) -> int:
	if battle_type == "boss":
		return int(round(float(player["max_hp"]) * 0.35))
	if battle_type == "elite":
		return int(round(float(player["max_hp"]) * 0.18))
	return int(round(float(player["max_hp"]) * 0.08))


func equip_item(player: Dictionary, item_id: String) -> void:
	var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
	player["equipment"][item["slot"]] = item_id
	if not player["equipment_ids"].has(item_id):
		player["equipment_ids"].append(item_id)


func unlock_skill(player: Dictionary, skill_id: String, equip_now: bool) -> void:
	if not player["unlocked_skills"].has(skill_id):
		player["unlocked_skills"].append(skill_id)
	if equip_now and not player["equipped_skills"].has(skill_id) and player["equipped_skills"].size() < 4:
		player["equipped_skills"].append(skill_id)


func _unlock_next_skill(player: Dictionary) -> void:
	var class_id: String = player["class_id"]
	for skill_id in DataCatalog.SKILLS.keys():
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		if skill.get("class", "") == class_id and not player["unlocked_skills"].has(skill_id):
			unlock_skill(player, skill_id, player["equipped_skills"].size() < 4)
			return
	for skill_id in DataCatalog.SKILLS.keys():
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		if skill.get("class", "") == "common" and not player["unlocked_skills"].has(skill_id):
			unlock_skill(player, skill_id, player["equipped_skills"].size() < 4)
			return


func _recalculate_player_stats(player: Dictionary, reset_hp: bool) -> void:
	var hp := int(player["base_max_hp"]) + int(player["max_hp_bonus"])
	var attack := int(player["base_attack"]) + int(player["attack_bonus"])
	var defense := int(player["base_defense"]) + int(player["defense_bonus"])
	for item_id in player["equipment_ids"]:
		var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
		hp += int(item["hp"])
		attack += int(item["attack"])
		defense += int(item["armor"])
	var old_max := int(player.get("max_hp", hp))
	player["max_hp"] = hp
	player["attack"] = attack
	player["defense"] = defense
	if reset_hp or not player.has("hp"):
		player["hp"] = hp
	else:
		player["hp"] = mini(hp, int(player["hp"]) + maxi(0, hp - old_max))


func _failure(player: Dictionary, reason: String, battle_results: Array[Dictionary]) -> Dictionary:
	return {
		"success": false,
		"reason": reason,
		"player": player,
		"battle_results": battle_results,
		"hp": int(player["hp"]),
		"max_hp": int(player["max_hp"])
	}
