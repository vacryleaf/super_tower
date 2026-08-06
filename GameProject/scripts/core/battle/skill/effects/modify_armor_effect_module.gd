extends "res://scripts/core/battle/skill/effect_executor.gd"
class_name ModifyArmorEffectModule

const StatusService = preload("res://scripts/core/status_service.gd")


func execute(action: Dictionary, context: RefCounted) -> RefCounted:
	var runtime: RefCounted = context.get("runtime")
	var skill: Dictionary = context.get("skill")
	var skill_id: String = String(context.get("skill_id"))
	var is_player_actor: bool = bool(context.get("is_player_actor"))
	var targets: Array[Dictionary] = context.call("targets")
	if not is_player_actor:
		var multiplier: float = float(action.get("multiplier", 1.0))
		for entry in targets:
			var target: Dictionary = entry.get("unit", {})
			if target.is_empty() or int(target.get("hp", 0)) <= 0:
				continue
			runtime.call("add_status", target, {
				"id": "%s:armor" % skill_id,
				"name": String(action.get("name", skill_id)),
				"kind": "debuff",
				"stack": "replace",
				"effects": [{"stat": StatusService.STAT_ARMOR, "type": StatusService.EFFECT_MULTIPLY, "value": multiplier}],
				"duration": int(action.get("duration", -1))
			})
		return BattleStepResult.new(BattleStepResult.CONTINUE)

	var multiplier: float = float(action.get("multiplier", 1.0))
	for entry in targets:
		var target: Dictionary = entry.get("unit", {})
		if String(entry.get("side", "")) != "enemy" or int(target.get("hp", 0)) <= 0:
			continue
		var old_armor: int = int(target.get("armor", 0))
		target["armor"] = maxi(0, int(round(float(old_armor) * multiplier)))
		if old_armor != int(target["armor"]):
			runtime.call("append_battle_log", "%s：%s 护甲 %d → %d。" % [skill.get("name", skill_id), target.get("name", "敌人"), old_armor, int(target["armor"])])
	return BattleStepResult.new(BattleStepResult.CONTINUE)
