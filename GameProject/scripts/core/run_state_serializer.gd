extends RefCounted
class_name RunStateSerializer

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const Combatant = preload("res://scripts/core/combatant.gd")


func save_data(session: RefCounted) -> Dictionary:
	return {
		"version": 2,
		"class_id": session.class_id,
		"floor_index": session.floor_index,
		"battle_index": session.battle_index,
		"phase": session.phase,
		"message": session.message,
		"player": session.player,
		"current_encounter": session.current_encounter,
		"enemies": session.enemies,
		"allies": session.allies,
		"energy": session.energy,
		"has_acted": session.has_acted,
		"skill_cooldowns": session.skill_cooldowns,
		"player_block": session.player_block,
		"dodge_layers": session.dodge_layers,
		"round_index": session.round_index,
		"pending_state_card": session.pending_state_card,
		"state_draw_cursor": session.state_draw_cursor,
		"battle_attack_multiplier": session.battle_attack_multiplier,
		"enemy_attack_multiplier": session.enemy_attack_multiplier,
		"focus_target_index": session.focus_target_index,
		"focus_combo_multiplier": session.focus_combo_multiplier,
		"counter_stance_charges": session.counter_stance_charges,
		"counter_attack_multiplier": session.counter_attack_multiplier,
		"dodge_streak": session.dodge_streak,
		"meticulous_stacks": session.meticulous_stacks,
		"seek_bloom_stacks": session.seek_bloom_stacks,
		"charge_used": session.charge_used,
		"charge_ready": session.charge_ready,
		"charge_uses_left": session.charge_uses_left,
		"pending_charge_effects": session.pending_charge_effects,
		"reward_options": session.reward_options,
		"pending_reward": session.pending_reward,
		"reward_targets": session.reward_targets
	}


func load_save_data(session: RefCounted, data: Dictionary) -> bool:
	if int(data.get("version", 0)) < 1:
		return false
	var saved_player: Dictionary = _dictionary(data.get("player", {}))
	var saved_class := String(data.get("class_id", saved_player.get("class_id", "")))
	if saved_class == "" or not DataCatalog.CLASSES.has(saved_class):
		return false
	session.class_id = saved_class
	session.player = saved_player
	if not session.player.has("class_id"):
		session.player["class_id"] = session.class_id
	session.floor_index = int(data.get("floor_index", 1))
	session.battle_index = int(data.get("battle_index", 1))
	session.phase = String(data.get("phase", "battle"))
	session.message = String(data.get("message", "继续游戏。"))
	session.current_encounter = _dictionary(data.get("current_encounter", {}))
	session.enemies = _dictionary_array(data.get("enemies", []))
	_normalize_loaded_enemies(session.enemies)
	session.allies = _dictionary_array(data.get("allies", []))
	_normalize_loaded_allies(session.allies)
	session.energy = int(data.get("energy", 0))
	session.has_acted = bool(data.get("has_acted", false))
	session.skill_cooldowns = _dictionary(data.get("skill_cooldowns", {}))
	session.player_block = int(data.get("player_block", 0))
	session.dodge_layers = int(data.get("dodge_layers", 0))
	session.round_index = int(data.get("round_index", 0))
	session.pending_state_card = String(data.get("pending_state_card", ""))
	session.state_draw_cursor = int(data.get("state_draw_cursor", 0))
	session.battle_attack_multiplier = float(data.get("battle_attack_multiplier", 1.0))
	session.enemy_attack_multiplier = float(data.get("enemy_attack_multiplier", 1.0))
	session.focus_target_index = int(data.get("focus_target_index", -1))
	session.focus_combo_multiplier = float(data.get("focus_combo_multiplier", 1.0))
	session.counter_stance_charges = int(data.get("counter_stance_charges", 0))
	session.counter_attack_multiplier = float(data.get("counter_attack_multiplier", 1.0))
	session.dodge_streak = int(data.get("dodge_streak", 0))
	session.meticulous_stacks = int(data.get("meticulous_stacks", 0))
	session.seek_bloom_stacks = int(data.get("seek_bloom_stacks", 0))
	session.charge_used = _dictionary(data.get("charge_used", {}))
	session.charge_ready = _dictionary(data.get("charge_ready", {}))
	session.charge_uses_left = _dictionary(data.get("charge_uses_left", {}))
	session.pending_charge_effects = _dictionary(data.get("pending_charge_effects", {}))
	session._ensure_charge_effects()
	session.reward_options = _dictionary_array(data.get("reward_options", []))
	session.pending_reward = _dictionary(data.get("pending_reward", {}))
	session.reward_targets = _dictionary_array(data.get("reward_targets", []))
	session.battle_log.clear()
	session.last_events.clear()
	if session.phase == "battle" and (session.current_encounter.is_empty() or session.enemies.is_empty()):
		session._start_current_battle()
	else:
		session.simulator._recalculate_player_stats(session.player, false)
	return true


func _normalize_loaded_enemies(enemies: Array[Dictionary]) -> void:
	for enemy in enemies:
		Combatant.normalize_enemy(enemy)
		if not enemy.has("statuses"):
			enemy["statuses"] = []


func _normalize_loaded_allies(allies: Array[Dictionary]) -> void:
	for ally in allies:
		Combatant.normalize_enemy(ally)
		if not ally.has("statuses"):
			ally["statuses"] = []


func _dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	return {}


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		if typeof(item) == TYPE_DICTIONARY:
			result.append((item as Dictionary).duplicate(true))
	return result
