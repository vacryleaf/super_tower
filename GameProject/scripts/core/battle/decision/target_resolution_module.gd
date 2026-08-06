extends RefCounted
class_name TargetResolutionModule

const CombatRules = preload("res://scripts/core/combat_rules.gd")
const SkillActionService = preload("res://scripts/core/skill_action_service.gd")


func resolve_player_target(enemies: Array[Dictionary], requested_index: int) -> Dictionary:
	var resolved_index: int = CombatRules.valid_target(enemies, requested_index)
	if resolved_index < 0:
		return _invalid_target("no_valid_enemy_target")
	return _target("enemy", resolved_index, enemies[resolved_index])


func resolve_player_action_targets(
	player: Dictionary,
	enemies: Array[Dictionary],
	allies: Array[Dictionary],
	target_mode: String,
	requested_index: int
) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match target_mode:
		SkillActionService.TARGET_SELF:
			result.append(_target("player", 0, player))
		SkillActionService.TARGET_ALL_ENEMIES:
			for index in range(enemies.size()):
				if _is_alive(enemies[index]):
					result.append(_target("enemy", index, enemies[index]))
		SkillActionService.TARGET_ADJACENT:
			var center: Dictionary = resolve_player_target(enemies, requested_index)
			if not bool(center.get("valid", false)):
				return result
			var center_index: int = int(center["index"])
			for offset in [-1, 1]:
				var adjacent_index: int = center_index + offset
				if adjacent_index >= 0 and adjacent_index < enemies.size() and _is_alive(enemies[adjacent_index]):
					result.append(_target("enemy", adjacent_index, enemies[adjacent_index]))
		SkillActionService.TARGET_ALLY_SELECTED:
				result.append_array(_resolve_allied_target(allies, requested_index))
		_:
			var selected: Dictionary = resolve_player_target(enemies, requested_index)
			if bool(selected.get("valid", false)):
				result.append(selected)
	return result


func resolve_enemy_action_targets(
	player: Dictionary,
	allies: Array[Dictionary],
	target_mode: String,
	requested_index: int
) -> Array[Dictionary]:
	if target_mode == SkillActionService.TARGET_SELF:
		return []
	var player_side: Array[Dictionary] = [player]
	player_side.append_array(allies)
	var result: Array[Dictionary] = []
	if target_mode == SkillActionService.TARGET_ALL_ENEMIES or target_mode == SkillActionService.TARGET_ADJACENT:
		for index in range(player_side.size()):
			if _is_alive(player_side[index]):
				result.append(_target("player", index, player_side[index]))
		return result
	var selected_index: int = requested_index
	if selected_index < 0 or selected_index >= player_side.size() or not _is_alive(player_side[selected_index]):
		selected_index = _first_alive_index(player_side)
	if selected_index >= 0:
		result.append(_target("player", selected_index, player_side[selected_index]))
	return result


func _resolve_allied_target(allies: Array[Dictionary], requested_index: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if requested_index >= 0 and requested_index < allies.size() and _is_alive(allies[requested_index]):
		result.append(_target("ally", requested_index, allies[requested_index]))
		return result
	for index in range(allies.size()):
		if _is_alive(allies[index]):
			result.append(_target("ally", index, allies[index]))
			break
	return result


func _target(side: String, index: int, unit: Dictionary) -> Dictionary:
	return {"valid": true, "side": side, "index": index, "unit": unit}


func _invalid_target(reason: String) -> Dictionary:
	return {"valid": false, "side": "", "index": -1, "unit": {}, "reason": reason}


func _is_alive(unit: Dictionary) -> bool:
	return int(unit.get("hp", 0)) > 0


func _first_alive_index(units: Array[Dictionary]) -> int:
	for index in range(units.size()):
		if _is_alive(units[index]):
			return index
	return -1
