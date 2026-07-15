extends RefCounted
class_name SetEffectService


func opening_state() -> Dictionary:
	return {
		"enemy_attack_multiplier": 1.0,
		"player_block": 0,
		"dodge_layers": 0
	}


func apply_battle_start(player: Dictionary, state: Dictionary, battle_log: Array[String], status_service) -> Dictionary:
	var result := opening_state()
	for key in state.keys():
		result[key] = state[key]
	var set_effects: Dictionary = player.get("active_set_effects", {})
	for action in set_effects.get("on_battle_start", []):
		var action_type := String(action.get("action", ""))
		match action_type:
			"weaken_enemies":
				var weaken_value := float(action.get("value", 0.0))
				if weaken_value > 0.0:
					result["enemy_attack_multiplier"] = 1.0 - weaken_value
					battle_log.append("套装效果：所有敌人伤害降低 %.0f%%。" % (weaken_value * 100.0))
			"gain_block":
				var block_value := int(action.get("value", 0))
				if block_value > 0:
					result["player_block"] = int(result.get("player_block", 0)) + block_value
					battle_log.append("套装效果：首回合获得 %d 点格挡。" % block_value)
			"gain_dodge":
				var dodge_value := int(action.get("value", 0))
				if dodge_value > 0:
					result["dodge_layers"] = int(result.get("dodge_layers", 0)) + dodge_value
					battle_log.append("套装效果：首回合获得 %d 层躲避。" % dodge_value)
			"apply_status":
				var status_to_apply: Dictionary = action.get("status", {})
				if not status_to_apply.is_empty():
					status_service.add_status(player, status_to_apply)
					battle_log.append("套装效果：获得 %s。" % String(status_to_apply.get("name", "")))
			"set_innate_skill":
				var slot := String(action.get("slot", ""))
				var new_skill_id := String(action.get("skill_id", ""))
				var runtime_slot := "attack_1" if slot == "attack" else slot
				if runtime_slot != "" and new_skill_id != "" and player.get("innate_skills", {}).has(runtime_slot):
					player["innate_skills"][runtime_slot] = new_skill_id
	return result
