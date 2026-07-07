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

	var after_focus: int = after_charge
	var target_index := int(ctx.get("target_index", -1))
	if session.has_method("_resolve_focus_combo") and source == ActionSource.ACTIVE_ATTACK:
		after_focus = maxi(1, int(round(float(after_charge) * session._resolve_focus_combo(target_index))))

	ctx["final_damage"] = after_focus
	return after_focus
