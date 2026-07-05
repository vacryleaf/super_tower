extends RefCounted
class_name RunSimulator

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const MAX_CHARGES := 5
const CombatEngine = preload("res://scripts/core/combat_engine.gd")
const EncounterService = preload("res://scripts/core/encounter_service.gd")
const CharacterService = preload("res://scripts/core/character_service.gd")
const SimulationRewardPolicy = preload("res://scripts/core/simulation_reward_policy.gd")

var combat := CombatEngine.new()
var encounters := EncounterService.new()
var character := CharacterService.new()
var simulation_rewards := SimulationRewardPolicy.new()


func create_character(class_id: String) -> Dictionary:
	return character.create_character(class_id)


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
	_apply_limited_post_battle_recovery(player, "boss")
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
	return encounters.generate_encounter(tower_floor, battle_index)


func _normal_encounter(tower_floor: int, battle_index: int) -> Dictionary:
	return encounters.normal_encounter(tower_floor, battle_index)


func _elite_encounter(tower_floor: int, battle_index: int) -> Dictionary:
	return encounters.elite_encounter(tower_floor, battle_index)


func _boss_encounter(tower_floor: int) -> Dictionary:
	return encounters.boss_encounter(tower_floor)


func _formation_from_units(id: String, battle_type: String, indexes: Array[int], scales: Array[float]) -> Dictionary:
	return encounters.formation_from_units(id, battle_type, indexes, scales)


func _formation_from_unit(id: String, battle_type: String, unit: Dictionary, scale: float) -> Dictionary:
	return encounters.formation_from_unit(id, battle_type, unit, scale)


func _formation(id: String, battle_type: String, units: Array[Dictionary]) -> Dictionary:
	return encounters.formation(id, battle_type, units)


func _prepare_unit(source: Dictionary, rank: String, scale: float) -> Dictionary:
	return encounters.prepare_unit(source, rank, scale)


func _low_unit(unit_name: String, scale: float, traits: Array) -> Dictionary:
	return encounters.low_unit(unit_name, scale, traits)


func _apply_battle_pressure(encounter: Dictionary, battle_index: int) -> Dictionary:
	return encounters.apply_battle_pressure(encounter, battle_index)


func _battle_pressure_scale(battle_index: int) -> float:
	return encounters.battle_pressure_scale(battle_index)


func _apply_tutorial_unlock(player: Dictionary, battle_zero_index: int) -> void:
	simulation_rewards.apply_tutorial_unlock(player, battle_zero_index, character)


func _apply_formal_reward(player: Dictionary, battle_type: String, tower_floor: int) -> void:
	simulation_rewards.apply_formal_reward(player, battle_type, tower_floor, character)


func _apply_limited_post_battle_recovery(player: Dictionary, battle_type: String) -> void:
	simulation_rewards.apply_limited_post_battle_recovery(player, battle_type)


func _reward_heal_amount(battle_type: String, player: Dictionary) -> int:
	return simulation_rewards.reward_heal_amount(battle_type, player)


func equip_item(player: Dictionary, item_id: String) -> void:
	character.equip_item(player, item_id)


func unlock_skill(player: Dictionary, skill_id: String, equip_now: bool) -> void:
	character.unlock_skill(player, skill_id, equip_now)


func _unlock_next_skill(player: Dictionary) -> void:
	character.unlock_next_skill(player)


func attach_reward(player: Dictionary, target: Dictionary, reward: Dictionary) -> void:
	character.attach_reward(player, target, reward)


func _charge_count(player: Dictionary) -> int:
	return character.charge_count(player)


func _is_charge_kind(kind: String) -> bool:
	return character.is_charge_kind(kind)


func _preferred_attachment_target(player: Dictionary, reward_kind: String) -> Dictionary:
	return character.preferred_attachment_target(player, reward_kind)


func _equipment_target_by_slot(player: Dictionary, slot: String) -> Dictionary:
	return character.equipment_target_by_slot(player, slot)


func skill_attachment_bonus(player: Dictionary, skill_id: String, kind: String) -> int:
	return character.skill_attachment_bonus(player, skill_id, kind)


func skill_multiplier_bonus(player: Dictionary, skill_id: String, kind: String = "") -> float:
	return character.skill_multiplier_bonus(player, skill_id, kind)


func _attachment_multiplier_value(value: float) -> float:
	return character.attachment_multiplier_value(value)


func _recalculate_player_stats(player: Dictionary, reset_hp: bool) -> void:
	character.recalculate_player_stats(player, reset_hp)


func _attachment_stat_kind(kind: String) -> String:
	return character.attachment_stat_kind(kind)


func _failure(player: Dictionary, reason: String, battle_results: Array[Dictionary]) -> Dictionary:
	return {
		"success": false,
		"reason": reason,
		"player": player,
		"battle_results": battle_results,
		"hp": int(player["hp"]),
		"max_hp": int(player["max_hp"])
	}
