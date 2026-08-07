extends RefCounted
class_name RunStateSerializer

const Combatant = preload("res://scripts/core/combatant.gd")
const RunContext = preload("res://scripts/core/run_context.gd")
const RunStateSnapshot = preload("res://scripts/core/run_state_snapshot.gd")


func save_data(session: RefCounted) -> Dictionary:
	var context := RunContext.new()
	context.capture_from_session(session)
	var snapshot := RunStateSnapshot.new()
	snapshot.run_data = context.capture()
	snapshot.battle_data = _capture_battle_data(session)
	return snapshot.to_dict()


func load_save_data(session: RefCounted, data: Dictionary) -> bool:
	if int(data.get("version", 0)) < 1:
		return false
	var snapshot := RunStateSnapshot.from_dict(data)
	var context := RunContext.new()
	context.apply_data(snapshot.run_data)
	_apply_run_context(session, context)
	# 旧存档迁移时会填充楼层组历史，NPC 解锁副作用与旧实现保持一致。
	if context.legacy_restored_count > 0:
		session._unlock_npc_upgrades_for_current_floor(context.legacy_restored_count)
	_apply_battle_data(session, snapshot.battle_data)
	return true


func _capture_battle_data(session: RefCounted) -> Dictionary:
	return {
		"current_encounter": (session.current_encounter as Dictionary).duplicate(true),
		"enemies": _duplicate_dict_array(session.enemies),
		"allies": _duplicate_dict_array(session.allies),
		"energy": int(session.energy),
		"has_acted": bool(session.has_acted),
		"skill_cooldowns": (session.skill_cooldowns as Dictionary).duplicate(true),
		"player_block": int(session.player_block),
		"dodge_layers": int(session.dodge_layers),
		"round_index": int(session.round_index),
		"ai_turn_stage": String(session.ai_turn_stage),
		"pending_state_card": String(session.pending_state_card),
		"state_draw_cursor": int(session.state_draw_cursor),
		"battle_attack_multiplier": float(session.battle_attack_multiplier),
		"enemy_attack_multiplier": float(session.enemy_attack_multiplier),
		"counter_stance_charges": int(session.counter_stance_charges),
		"counter_attack_multiplier": float(session.counter_attack_multiplier),
		"dodge_streak": int(session.dodge_streak),
		"counters": (session.counters as Dictionary).duplicate(true),
		"charge_used": (session.charge_used as Dictionary).duplicate(true),
		"charge_ready": (session.charge_ready as Dictionary).duplicate(true),
		"charge_uses_left": (session.charge_uses_left as Dictionary).duplicate(true),
		"pending_charge_effects": (session.pending_charge_effects as Dictionary).duplicate(true),
		"deferred_damage": float(session.deferred_damage),
		"duel_target_index": int(session.duel_target_index),
		"perfect_deflect": bool(session.perfect_deflect)
	}


func _apply_run_context(session: RefCounted, context: RunContext) -> void:
	session.class_id = context.class_id
	session.player = context.player
	session.floor_index = context.floor_index
	session.battle_index = context.battle_index
	session.tower_bonus = context.tower_bonus
	session.floor_encounter_count = context.floor_encounter_count
	session.floor_group_id = context.floor_group_id
	session.encountered_groups_by_floor = context.encountered_groups_by_floor.duplicate(true)
	session.tutorial_active = context.tutorial_active
	session.phase = context.phase
	session.message = context.message
	session.reward_options = context.reward_options
	session.pending_reward = context.pending_reward
	session.reward_targets = context.reward_targets


func _apply_battle_data(session: RefCounted, battle_data: Dictionary) -> void:
	session.current_encounter = _dictionary(battle_data.get("current_encounter", {}))
	session.enemies = _dictionary_array(battle_data.get("enemies", []))
	_normalize_loaded_enemies(session.enemies)
	session.allies = _dictionary_array(battle_data.get("allies", []))
	_normalize_loaded_allies(session.allies)
	session.energy = int(battle_data.get("energy", 0))
	session.has_acted = bool(battle_data.get("has_acted", false))
	session.skill_cooldowns = _dictionary(battle_data.get("skill_cooldowns", {}))
	session.player_block = int(battle_data.get("player_block", 0))
	session.dodge_layers = int(battle_data.get("dodge_layers", 0))
	session.round_index = int(battle_data.get("round_index", 0))
	session.ai_turn_stage = String(battle_data.get("ai_turn_stage", "after_player_pending"))
	session.pending_state_card = String(battle_data.get("pending_state_card", ""))
	session.state_draw_cursor = int(battle_data.get("state_draw_cursor", 0))
	session.battle_attack_multiplier = float(battle_data.get("battle_attack_multiplier", 1.0))
	session.enemy_attack_multiplier = float(battle_data.get("enemy_attack_multiplier", 1.0))
	session.counter_stance_charges = int(battle_data.get("counter_stance_charges", 0))
	session.counter_attack_multiplier = float(battle_data.get("counter_attack_multiplier", 1.0))
	session.dodge_streak = int(battle_data.get("dodge_streak", 0))
	session.counters = _dictionary(battle_data.get("counters", {}))
	session.charge_used = _dictionary(battle_data.get("charge_used", {}))
	session.charge_ready = _dictionary(battle_data.get("charge_ready", {}))
	session.charge_uses_left = _dictionary(battle_data.get("charge_uses_left", {}))
	session.pending_charge_effects = _dictionary(battle_data.get("pending_charge_effects", {}))
	session._ensure_charge_effects()
	session.deferred_damage = float(battle_data.get("deferred_damage", 0.0))
	session.duel_target_index = int(battle_data.get("duel_target_index", -1))
	session.perfect_deflect = bool(battle_data.get("perfect_deflect", false))
	session.battle_log.clear()
	session.last_events.clear()
	if session.phase == "battle" and (session.current_encounter.is_empty() or session.enemies.is_empty()):
		session._start_current_battle()
	else:
		session.character.recalculate_player_stats(session.player, false)


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


func _duplicate_dict_array(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(source) != TYPE_ARRAY:
		return result
	for item in source:
		if typeof(item) == TYPE_DICTIONARY:
			result.append((item as Dictionary).duplicate(true))
	return result


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
