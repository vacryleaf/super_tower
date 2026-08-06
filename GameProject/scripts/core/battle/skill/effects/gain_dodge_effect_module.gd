extends "res://scripts/core/battle/skill/effect_executor.gd"
class_name GainDodgeEffectModule

const Combatant = preload("res://scripts/core/combatant.gd")


func execute(action: Dictionary, context: RefCounted) -> RefCounted:
	var runtime: RefCounted = context.get("runtime")
	var actor: Dictionary = context.get("actor")
	var is_player_actor: bool = bool(context.get("is_player_actor"))
	var gained: int = maxi(1, int(action.get("layers", 1)))
	if is_player_actor:
		if String(runtime.call("pending_state_card")) == String(action.get("double_with_state", "")):
			gained *= 2
		runtime.call("add_player_dodge", gained)
		runtime.call("event", {"kind": "dodge", "target": "player", "amount": gained})
	else:
		Combatant.add_dodge(actor, gained)
		runtime.call("event", {"kind": "dodge", "target": "enemy", "source": actor.get("name", "敌人"), "amount": gained})
	return BattleStepResult.new(BattleStepResult.CONTINUE)
