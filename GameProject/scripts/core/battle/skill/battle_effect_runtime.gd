extends RefCounted
class_name BattleEffectRuntime

const Combatant = preload("res://scripts/core/combatant.gd")
const ModifierPipeline = preload("res://scripts/core/modifier_pipeline.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const TargetResolutionModule = preload("res://scripts/core/battle/decision/target_resolution_module.gd")

var session: RefCounted
var target_resolver: RefCounted


func _init(initial_session: RefCounted) -> void:
	session = initial_session
	target_resolver = TargetResolutionModule.new()


func resolve_targets(action: Dictionary, target_index: int, actor: Dictionary, is_player_actor: bool) -> Array[Dictionary]:
	var target_mode := String(action.get("target", "selected"))
	if is_player_actor:
		return target_resolver.call("resolve_player_action_targets", session.player, session.enemies, session.allies, target_mode, target_index)
	return target_resolver.call("resolve_enemy_action_targets", session.player, session.allies, target_mode, target_index)


func resolve_player_heal_target(action: Dictionary, target_index: int) -> Dictionary:
	if String(action.get("target", "self")) != "ally_selected":
		return session.player
	if target_index == 0:
		return session.player
	var ally_index: int = target_index - 1
	if ally_index < 0 or ally_index >= session.allies.size():
		return {}
	return session.allies[ally_index]


func status_service() -> RefCounted:
	return session.status_service


func add_status(target: Dictionary, status: Dictionary) -> void:
	session.status_service.add_status(target, status)


func clear_debuffs(target: Dictionary) -> void:
	session.status_service.clear_debuffs(target)


func resolve_stat(target: Dictionary, base_value: float, stat_key: String) -> float:
	return session.status_service.resolve_stat(target, base_value, stat_key)


func collect_modifiers(stat_key: String, context: Dictionary, action_source: String = "") -> Array[Dictionary]:
	return ModifierPipeline.collect_from_session(session, stat_key, context, action_source)


func skill_multiplier_bonus(skill_id: String, stat_key: String) -> float:
	if session.has_method("_skill_multiplier_bonus"):
		return float(session.call("_skill_multiplier_bonus", skill_id, stat_key))
	return 0.0


func apply_charge_defense_modifiers(amount: int, skill_id: String) -> int:
	if session.has_method("_apply_charge_defense_modifiers"):
		return int(session.call("_apply_charge_defense_modifiers", amount, skill_id))
	return amount


func add_player_block(amount: int) -> void:
	if session.has_method("_add_player_block"):
		session.call("_add_player_block", amount)
		return
	var player: Dictionary = session.player
	player["block"] = int(player.get("block", 0)) + maxi(0, amount)


func add_player_dodge(layers: int) -> void:
	if session.has_method("_add_player_dodge"):
		session.call("_add_player_dodge", layers)
		return
	var player: Dictionary = session.player
	Combatant.add_dodge(player, layers)


func sync_player(combatant_unit: Dictionary) -> void:
	if session.has_method("_sync_player_combatant"):
		session.call("_sync_player_combatant", combatant_unit)


func pending_state_card() -> String:
	return String(session.get("pending_state_card"))


func log(message: String) -> void:
	session.battle_log.append(message)


func event(value: Dictionary) -> void:
	session.last_events.append(value.duplicate(true))
