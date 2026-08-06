extends RefCounted
class_name BattleModule

const BattleStepResult = preload("res://scripts/core/battle/battle_step_result.gd")


func supports(_timing: String) -> bool:
	return false


func priority(_timing: String) -> int:
	return 0


func execute(_timing: String, _context: RefCounted) -> RefCounted:
	return BattleStepResult.new(BattleStepResult.CONTINUE)
