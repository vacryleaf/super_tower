extends RefCounted
class_name HitResolutionModule

const BattleHitContext = preload("res://scripts/core/battle/battle_hit_context.gd")
const TargetResolutionModule = preload("res://scripts/core/battle/decision/target_resolution_module.gd")

var target_resolver: RefCounted


func _init(initial_target_resolver: RefCounted = null) -> void:
	target_resolver = initial_target_resolver if initial_target_resolver != null else TargetResolutionModule.new()


func create_hit_context(
	action_context: Dictionary,
	source_actor: Dictionary,
	target_actor: Dictionary,
	parent_action_id: String = "",
	chain_id: String = ""
) -> RefCounted:
	var hit_context := BattleHitContext.new(
		source_actor,
		target_actor,
		String(action_context.get("source", "")),
		parent_action_id,
		chain_id
	)
	hit_context.skill_id = String(action_context.get("skill_id", ""))
	hit_context.damage_type = String(action_context.get("damage_type", "physical"))
	hit_context.base_damage = int(action_context.get("base_damage", 0))
	hit_context.modified_damage = int(action_context.get("final_damage", hit_context.base_damage))
	hit_context.final_damage = hit_context.modified_damage
	hit_context.is_critical = bool(action_context.get("is_critical", false))
	hit_context.armor_multiplier = float(action_context.get("armor_multiplier", 1.0))
	return hit_context


func resolve_player_hit(
	enemies: Array[Dictionary],
	action_context: Dictionary,
	source_actor: Dictionary,
	parent_action_id: String = "",
	chain_id: String = ""
) -> Dictionary:
	var target: Dictionary = target_resolver.call("resolve_player_target", enemies, int(action_context.get("target_index", -1)))
	if not bool(target.get("valid", false)):
		return _invalid_result(String(target.get("reason", "no_valid_target")))
	var hit_context: RefCounted = create_hit_context(action_context, source_actor, target["unit"], parent_action_id, chain_id)
	return {"valid": true, "target": target, "context": hit_context}


func resolve_enemy_hit(
	player: Dictionary,
	allies: Array[Dictionary],
	action_context: Dictionary,
	source_actor: Dictionary,
	parent_action_id: String = "",
	chain_id: String = ""
) -> Dictionary:
	var targets: Array[Dictionary] = target_resolver.call(
		"resolve_enemy_action_targets",
		player,
		allies,
		"selected",
		int(action_context.get("target_index", 0))
	)
	if targets.is_empty():
		return _invalid_result("no_valid_player_target")
	var target: Dictionary = targets[0]
	var hit_context: RefCounted = create_hit_context(action_context, source_actor, target["unit"], parent_action_id, chain_id)
	return {"valid": true, "target": target, "context": hit_context}


func _invalid_result(reason: String) -> Dictionary:
	return {"valid": false, "target": {}, "context": null, "reason": reason}
