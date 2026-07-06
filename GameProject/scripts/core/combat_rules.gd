extends RefCounted
class_name CombatRules

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const ModifierPipeline = preload("res://scripts/core/modifier_pipeline.gd")


static func build_enemies(encounter: Dictionary, tower_floor: int, include_statuses: bool = true) -> Array[Dictionary]:
	var enemies: Array[Dictionary] = []
	for unit in encounter.get("units", []):
		var enemy := Combatant.from_enemy_unit(unit, String(encounter.get("type", "normal")), tower_floor)
		if include_statuses and not enemy.has("statuses"):
			enemy["statuses"] = []
		enemies.append(enemy)
	return enemies


static func alive_count(enemies: Array[Dictionary]) -> int:
	var count := 0
	for enemy in enemies:
		if int(enemy.get("hp", 0)) > 0:
			count += 1
	return count


static func active_taunt_target(enemies: Array[Dictionary]) -> int:
	for i in range(enemies.size()):
		if int(enemies[i].get("hp", 0)) > 0 and int(enemies[i].get("taunt", 0)) > 0:
			return i
	return -1


static func valid_target(enemies: Array[Dictionary], target_index: int) -> int:
	var taunt_target := active_taunt_target(enemies)
	if taunt_target >= 0:
		return taunt_target
	if enemies.is_empty():
		return -1
	if target_index >= 0 and target_index < enemies.size() and int(enemies[target_index].get("hp", 0)) > 0:
		return target_index
	for i in range(enemies.size()):
		if int(enemies[i].get("hp", 0)) > 0:
			return i
	return -1


static func clear_enemy_taunts(enemies: Array[Dictionary]) -> void:
	for enemy in enemies:
		Combatant.clear_taunt(enemy)


static func clear_enemy_blocks(enemies: Array[Dictionary]) -> void:
	for enemy in enemies:
		Combatant.clear_block(enemy)


static func current_attack_value(session: RefCounted) -> int:
	var resolved_attack: float = session.status_service.resolve_stat(session.player, float(session.player["attack"]), StatusService.STAT_ATTACK)
	var modifiers: Array = ModifierPipeline.collect_from_session(session, "attack", {
		"state_card": session.pending_state_card,
		"focus_combo_multiplier": session.focus_combo_multiplier
	})
	return maxi(1, int(round(ModifierPipeline.resolve(resolved_attack, modifiers))))


static func defense_value(session: RefCounted) -> int:
	var resolved_defense: float = session.status_service.resolve_stat(session.player, float(session.player["block_power"]), StatusService.STAT_DEFENSE)
	var modifiers: Array = ModifierPipeline.collect_from_session(session, "defense", {})
	return maxi(1, int(round(ModifierPipeline.resolve(resolved_defense, modifiers))))


static func skill_attack_value(session: RefCounted, skill_id: String) -> int:
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var multiplier: float = float(skill.get("multiplier", 1.0)) + session._skill_multiplier_bonus(skill_id, "attack")
	var resolved_attack: float = session.status_service.resolve_stat(session.player, float(session.player["attack"]), StatusService.STAT_ATTACK)
	var modifiers: Array = ModifierPipeline.collect_from_session(session, "attack", {"skill_id": skill_id, "skill_multiplier": multiplier})
	return maxi(1, int(round(ModifierPipeline.resolve(resolved_attack, modifiers))))


static func skill_defense_value(session: RefCounted, skill_id: String) -> int:
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var multiplier: float = float(skill.get("multiplier", skill.get("block_multiplier", 1.0))) + session._skill_multiplier_bonus(skill_id, "defense")
	var resolved_defense: float = session.status_service.resolve_stat(session.player, float(session.player["block_power"]), StatusService.STAT_DEFENSE)
	var modifiers: Array = ModifierPipeline.collect_from_session(session, "defense", {"skill_id": skill_id, "skill_multiplier": multiplier})
	return maxi(1, int(round(ModifierPipeline.resolve(resolved_defense, modifiers))))


static func skill_dodge_block_value(session: RefCounted, skill_id: String) -> int:
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var multiplier: float = float(skill.get("block_multiplier", 0.0)) + session._skill_multiplier_bonus(skill_id, "defense")
	if multiplier <= 0.0:
		return 0
	return maxi(1, int(round(float(session.player["block_power"]) * multiplier)))


static func skill_heal_value(session: RefCounted, skill_id: String) -> int:
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var multiplier: float = float(skill.get("heal_multiplier", 0.0)) + session._skill_multiplier_bonus(skill_id, "hp")
	return maxi(1, int(round(float(session.player["max_hp"]) * multiplier)))


static func enemy_attack_segments(session: RefCounted, enemy: Dictionary, first_strike: bool) -> Array[int]:
	var segments: Array[int] = session.enemy_rules.attack_segments(enemy, session.round_index, first_strike)
	var base_attack := float(enemy["attack"])
	var resolved_attack: float = session.status_service.resolve_stat(enemy, base_attack, StatusService.STAT_ATTACK)
	var status_ratio := resolved_attack / maxf(1.0, base_attack)
	var total_multiplier: float = session.enemy_attack_multiplier * status_ratio
	if abs(total_multiplier - 1.0) < 0.001:
		return segments
	var result: Array[int] = []
	for damage in segments:
		result.append(maxi(1, int(round(float(damage) * total_multiplier))))
	return result
