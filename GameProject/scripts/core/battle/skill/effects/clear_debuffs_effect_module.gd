extends "res://scripts/core/battle/skill/effect_executor.gd"
class_name ClearDebuffsEffectModule

func execute(_action: Dictionary, context: RefCounted) -> RefCounted:
	var runtime: RefCounted = context.get("runtime")
	runtime.call("clear_debuffs", context.get("actor"))
	return BattleStepResult.new(BattleStepResult.CONTINUE)
