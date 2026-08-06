extends RefCounted
class_name EffectExecutor

const BattleStepResult = preload("res://scripts/core/battle/battle_step_result.gd")


func execute(_action: Dictionary, _context: RefCounted) -> RefCounted:
	return BattleStepResult.new(BattleStepResult.ERROR, "effect executor is not implemented", "unimplemented_effect_executor")
