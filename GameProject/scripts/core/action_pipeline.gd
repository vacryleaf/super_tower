extends RefCounted
class_name ActionPipeline

const ModifierPipeline = preload("res://scripts/core/modifier_pipeline.gd")
const ActionSource = preload("res://scripts/core/action_source.gd")


static func compute(ctx: Dictionary, session) -> int:
	var base := int(ctx.get("base_damage", 0))
	var source := String(ctx.get("source", ActionSource.ACTIVE_ATTACK))
	var skill_id := String(ctx.get("skill_id", ""))

	var after_charge: int = base
	if session.has_method("_apply_charge_attack_modifiers"):
		after_charge = session._apply_charge_attack_modifiers(base, skill_id)

	ctx["final_damage"] = after_charge
	return after_charge
