extends "res://scripts/core/battle/skill/effect_executor.gd"
class_name HealEffectModule

const StatusService = preload("res://scripts/core/status_service.gd")


func execute(action: Dictionary, context: RefCounted) -> RefCounted:
	var runtime: RefCounted = context.get("runtime")
	var actor: Dictionary = context.get("actor")
	var skill_id: String = String(context.get("skill_id"))
	var skill: Dictionary = context.get("skill")
	var is_player_actor: bool = bool(context.get("is_player_actor"))
	if is_player_actor:
		return _execute_player(action, context, runtime, actor, skill_id)
	return _execute_enemy(action, context, runtime, actor, skill_id, skill)


func _execute_player(action: Dictionary, context: RefCounted, runtime: RefCounted, actor: Dictionary, skill_id: String) -> RefCounted:
	var heal_target: Dictionary = runtime.call("resolve_player_heal_target", action, int(context.get("target_index")))
	if heal_target.is_empty():
		return BattleStepResult.new(BattleStepResult.CONTINUE)
	var amount: int = int(action.get("amount", 0))
	if amount <= 0:
		var stat: String = String(action.get("stat", "attack"))
		var multiplier: float = float(action.get("multiplier", 1.0))
		var bonus_stat: String = String(action.get("skill_bonus_stat", stat))
		if bonus_stat != "":
			multiplier += float(runtime.call("skill_multiplier_bonus", skill_id, bonus_stat))
		amount = maxi(1, int(round(float(heal_target.get(stat, 0)) * multiplier)))
	if bool(action.get("resolve_heal", true)):
		amount = maxi(1, int(ceil(float(runtime.call("resolve_stat", heal_target, float(amount), StatusService.STAT_HEAL)))) )
	heal_target["hp"] = mini(int(heal_target.get("max_hp", heal_target.get("hp", 1))), int(heal_target.get("hp", 0)) + amount)
	if String(heal_target.get("side", "")) == "player":
		runtime.call("sync_player", heal_target)
	runtime.call("event", {"kind": "heal", "target": "player", "amount": amount})
	return BattleStepResult.new(BattleStepResult.CONTINUE)


func _execute_enemy(action: Dictionary, context: RefCounted, runtime: RefCounted, actor: Dictionary, skill_id: String, skill: Dictionary) -> RefCounted:
	var heal_target: Dictionary = actor
	if String(action.get("target", "self")) != "self":
		var targets: Array[Dictionary] = context.call("targets")
		if not targets.is_empty():
			heal_target = targets[0].get("unit", {})
	if heal_target.is_empty():
		return BattleStepResult.new(BattleStepResult.CONTINUE)
	var amount: int = int(action.get("amount", 0))
	if amount <= 0:
		amount = maxi(1, int(ceil(float(heal_target.get("max_hp", 1)) * float(action.get("multiplier", 0.25)))))
	heal_target["hp"] = mini(int(heal_target.get("max_hp", heal_target.get("hp", 1))), int(heal_target.get("hp", 0)) + amount)
	if String(heal_target.get("side", "")) == "player":
		runtime.call("sync_player", heal_target)
	runtime.call("event", {"kind": "heal", "target": "enemy", "source": actor.get("name", skill.get("name", skill_id)), "amount": amount})
	return BattleStepResult.new(BattleStepResult.CONTINUE)
