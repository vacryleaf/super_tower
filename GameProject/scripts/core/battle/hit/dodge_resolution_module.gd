extends "res://scripts/core/battle/battle_module.gd"
class_name DodgeResolutionModule

const BattleTiming = preload("res://scripts/core/battle/battle_timing.gd")


func supports(timing: String) -> bool:
	return timing == BattleTiming.DODGE_CHECK


func priority(_timing: String) -> int:
	return 100


func execute(_timing: String, context: RefCounted) -> RefCounted:
	return resolve(context)


func resolve(context: RefCounted) -> RefCounted:
	var target: Dictionary = context.get("target_actor")
	if int(context.get("base_damage")) <= 0 or int(target.get("dodge_layers", 0)) <= 0:
		return BattleStepResult.new(BattleStepResult.CONTINUE)
	target["dodge_layers"] = int(target.get("dodge_layers", 0)) - 1
	context.call("mark_dodged")
	return BattleStepResult.new(BattleStepResult.CONTINUE)
