extends "res://scripts/core/battle/skill/effect_executor.gd"
class_name InterruptEffectModule

func execute(_action: Dictionary, context: RefCounted) -> RefCounted:
	var runtime: RefCounted = context.get("runtime")
	var skill: Dictionary = context.get("skill")
	var is_player_actor: bool = bool(context.get("is_player_actor"))
	for entry in context.call("targets"):
		var target: Dictionary = entry.get("unit", {})
		if target.is_empty() or int(target.get("hp", 0)) <= 0:
			continue
		target["interrupted"] = true
		if is_player_actor:
			runtime.call("append_battle_log", "%s：打断 %s 的本回合行动。" % [skill.get("name", context.get("skill_id")), target.get("name", "敌人")])
	return BattleStepResult.new(BattleStepResult.CONTINUE)
