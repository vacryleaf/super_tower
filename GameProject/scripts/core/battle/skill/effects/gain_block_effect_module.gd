extends "res://scripts/core/battle/skill/effect_executor.gd"
class_name GainBlockEffectModule

const Combatant = preload("res://scripts/core/combatant.gd")
const ModifierPipeline = preload("res://scripts/core/modifier_pipeline.gd")
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
	var amount: int = int(action.get("amount", 0))
	if amount <= 0:
		var stat: String = String(action.get("stat", "block_power"))
		var multiplier: float = float(action.get("multiplier", 1.0))
		var bonus_stat: String = String(action.get("skill_bonus_stat", ""))
		if bonus_stat != "":
			multiplier += float(runtime.call("skill_multiplier_bonus", skill_id, bonus_stat))
		var base_value: float = float(actor.get(stat, actor.get("block_power", 1)))
		var resolved_value: float = float(runtime.call("resolve_stat", actor, base_value, StatusService.STAT_DEFENSE))
		var modifiers: Array[Dictionary] = runtime.call("collect_modifiers", "defense", {"skill_id": skill_id, "skill_multiplier": multiplier})
		amount = maxi(1, int(round(ModifierPipeline.resolve(resolved_value, modifiers))))
	if bool(action.get("apply_defense_charge", false)):
		amount = int(runtime.call("apply_charge_defense_modifiers", amount, skill_id))
	var total_amount: int = amount * (1 + int(context.get("repeat_bonus")))
	runtime.call("add_player_block", total_amount)
	runtime.call("event", {"kind": "defense", "target": "player", "amount": total_amount})
	return BattleStepResult.new(BattleStepResult.CONTINUE)


func _execute_enemy(action: Dictionary, context: RefCounted, runtime: RefCounted, actor: Dictionary, skill_id: String, skill: Dictionary) -> RefCounted:
	var amount: int = int(action.get("amount", 0))
	if amount <= 0:
		amount = maxi(1, int(round(float(actor.get("block_power", actor.get("defense", 1))) * float(action.get("multiplier", 1.0)))))
	Combatant.add_block_amount(actor, amount)
	runtime.call("append_battle_log", "%s 使用 %s：获得 %d 点格挡。" % [actor.get("name", "敌人"), skill.get("name", skill_id), amount])
	runtime.call("event", {"kind": "defense", "target": "enemy", "source": actor.get("name", "敌人"), "amount": amount})
	return BattleStepResult.new(BattleStepResult.CONTINUE)
