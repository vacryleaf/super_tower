extends "res://scripts/core/battle/skill/effect_executor.gd"
class_name ApplyStatusEffectModule

func execute(action: Dictionary, context: RefCounted) -> RefCounted:
	var runtime: RefCounted = context.get("runtime")
	var actor: Dictionary = context.get("actor")
	var skill_id: String = String(context.get("skill_id"))
	var is_player_actor: bool = bool(context.get("is_player_actor"))
	var status: Dictionary = _resolved_status(action, context, runtime, skill_id, is_player_actor)
	if status.is_empty():
		return BattleStepResult.new(BattleStepResult.CONTINUE)
	var targets: Array[Dictionary] = []
	if String(action.get("target", "selected")) == "self":
		targets.append({"unit": actor})
	else:
		targets = context.call("targets")
	for entry in targets:
		var target: Dictionary = entry.get("unit", {})
		if not target.is_empty() and int(target.get("hp", 0)) > 0:
			runtime.call("add_status", target, status)
	return BattleStepResult.new(BattleStepResult.CONTINUE)


func _resolved_status(action: Dictionary, context: RefCounted, runtime: RefCounted, skill_id: String, is_player_actor: bool) -> Dictionary:
	var raw_status: Variant = action.get("status", {})
	if typeof(raw_status) != TYPE_DICTIONARY or (raw_status as Dictionary).is_empty():
		return {}
	var status: Dictionary = (raw_status as Dictionary).duplicate(true)
	if not is_player_actor:
		for effect in status.get("effects", []):
			effect.erase("skill_bonus_stat")
		return status
	var actor: Dictionary = context.get("actor")
	for effect in status.get("effects", []):
		var bonus_stat: String = String(effect.get("skill_bonus_stat", ""))
		if bonus_stat == "":
			continue
		effect["value"] = float(effect.get("value", 0.0)) + float(runtime.call("skill_multiplier_bonus", skill_id, bonus_stat))
		effect.erase("skill_bonus_stat")
	for tick in status.get("tick_effects", []):
		if not tick.has("source_stat"):
			continue
		var stat: String = String(tick.get("source_stat", ""))
		var multiplier: float = float(tick.get("source_multiplier", 1.0))
		var amount: int = maxi(1, int(round(float(actor.get(stat, 0)) * multiplier)))
		tick.erase("source_stat")
		tick.erase("source_multiplier")
		tick["value"] = -amount if bool(tick.get("negative", false)) else amount
		tick.erase("negative")
	return status
