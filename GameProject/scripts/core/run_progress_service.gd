extends RefCounted
class_name RunProgressService


func on_victory(session: Variant) -> void:
	session.player["battles_completed"] += 1
	session._unlock_enemies_in_bestiary()
	var encounter_type := String(session.current_encounter.get("type", ""))
	if encounter_type == "boss" and not session.is_tutorial():
		session.tower_coins += session.floor_index
		session._unlock_next_class_skill()
	session.phase = "reward"
	session._build_reward_options()


func on_defeat(session: Variant) -> void:
	if session.is_tutorial():
		session.player["tutorial_restarts"] += 1
		session.player["hp"] = int(session.player.get("max_hp", session.player.get("base_max_hp", 1)))
		session.message = "新手引导失败保护：当前战斗已重开。"
		session._start_current_battle()
	else:
		session.phase = "game_over"
		session.message = "你在第 %d 层第 %d 场战斗中失败。" % [session.floor_index, session.battle_index]


func advance_after_reward(session: Variant) -> void:
	if session.is_tutorial() and session.battle_index == 3:
		session.player["tutorial_completed"] = true
		session.pending_tutorial_epilogue = true
		session.phase = "tutorial_epilogue"
		session.message = "城外有座塔拔地而起，众多冒险家纷纷前往，但绝大部分都无法通过第十层，更别提看起来有数百层。"
		return
	if session.battle_index >= 10:
		if session.floor_index >= 10:
			session.phase = "victory"
			session.message = "你已通关第 10 层，当前版本目标完成。"
			return
		session.floor_index += 1
		session.battle_index = 1
		session.floor_group_id = ""
	else:
		session.battle_index += 1
	apply_limited_post_battle_recovery(session)
	session._start_current_battle()


func apply_limited_post_battle_recovery(session: Variant) -> void:
	var max_hp := int(session.player.get("max_hp", session.player.get("base_max_hp", 1)))
	var hp := int(session.player.get("hp", max_hp))
	var cap := int(floor(float(max_hp) * 0.80))
	if hp >= cap:
		return
	session.player["hp"] = mini(cap, hp + post_reward_heal_amount(session))


func post_reward_heal_amount(session: Variant) -> int:
	var ratio := 0.08
	var encounter_type := String(session.current_encounter.get("type", "normal"))
	if encounter_type == "boss":
		ratio = 0.35
	elif encounter_type == "elite":
		ratio = 0.18
	var max_hp := int(session.player.get("max_hp", session.player.get("base_max_hp", 1)))
	return maxi(4, int(round(float(max_hp) * ratio)))
