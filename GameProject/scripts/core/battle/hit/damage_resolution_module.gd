extends RefCounted
class_name DamageResolutionModule

const BattleHitContext = preload("res://scripts/core/battle/battle_hit_context.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const DamageType = preload("res://scripts/core/damage_type.gd")
const DodgeResolutionModule = preload("res://scripts/core/battle/hit/dodge_resolution_module.gd")

var dodge_resolution_module: RefCounted


func _init(initial_dodge_resolution_module: RefCounted = null) -> void:
	dodge_resolution_module = initial_dodge_resolution_module if initial_dodge_resolution_module != null else DodgeResolutionModule.new()


func resolve(
	target: Dictionary,
	raw_damage: int,
	damage_type: String,
	runtime: RefCounted,
	attacker: Dictionary = {},
	action_armor_multiplier: float = -1.0
) -> Dictionary:
	var damage_taken_mult: float = float(runtime.call("resolve_stat", target, 1.0, "damage_taken"))
	var marked_damage: int = maxi(0, int(ceil(float(raw_damage) * damage_taken_mult)))
	if damage_type != DamageType.TRUE:
		var resist_key: String = DamageType.resist_key(damage_type)
		var base_resist: float = float(target.get("resistances", {}).get(damage_type, 1.0))
		var resist_mult: float = float(runtime.call("resolve_stat", target, base_resist, resist_key))
		marked_damage = maxi(0, int(ceil(float(marked_damage) * resist_mult)))
	if damage_type == DamageType.SHADOW:
		var shadow_multiplier: float = float(runtime.call("resolve_stat", attacker, 1.0, "shadow_damage"))
		marked_damage = maxi(0, int(ceil(float(marked_damage) * shadow_multiplier)))
	if String(target.get("side", "")) == "enemy":
		marked_damage = maxi(0, int(ceil(float(marked_damage) * float(runtime.call("ally_guard_damage_multiplier", target)))) )
	var armor_multiplier: float = float(runtime.call("armor_multiplier_against", attacker))
	if action_armor_multiplier >= 0.0:
		armor_multiplier *= clampf(action_armor_multiplier, 0.0, 1.0)
	var hit_context := BattleHitContext.new(attacker, target, "damage")
	hit_context.base_damage = marked_damage
	hit_context.modified_damage = marked_damage
	hit_context.damage_type = damage_type
	hit_context.armor_multiplier = armor_multiplier
	dodge_resolution_module.call("resolve", hit_context)
	if bool(hit_context.get("is_dodged")):
		return _dodged_damage_result(target, marked_damage)
	var result: Dictionary = Combatant.apply_damage(target, marked_damage, damage_type, armor_multiplier, false)
	runtime.call("apply_shadow_armor_reflect", target, attacker, result)
	if String(target.get("side", "")) == "enemy" and int(result.get("damage", 0)) > 0:
		runtime.call("check_split_after_damage", target)
	return result


func _dodged_damage_result(target: Dictionary, raw_damage: int) -> Dictionary:
	var block_value: int = int(target.get("block", 0))
	return {
		"dodged": true,
		"raw_damage": maxi(0, raw_damage),
		"damage_before_block": 0,
		"armor_reduced": 0,
		"block_before": block_value,
		"block_absorbed": 0,
		"block_after": block_value,
		"block_broken": false,
		"damage": 0
	}
