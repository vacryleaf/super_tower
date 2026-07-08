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
		session.player["hp"] = session.player["max_hp"]
		session.message = "新手引导失败保护：当前战斗已重开。"
		session._start_current_battle()
	else:
		session.phase = "game_over"
		session.message = "你在第 %d 层第 %d 场战斗中失败。" % [session.floor_index, session.battle_index]


func advance_after_reward(session: Variant) -> void:
	if session.is_tutorial() and session.battle_index == 10:
		session.player["tutorial_completed"] = true
		session.floor_index = 2
		session.battle_index = 1
		session.message = "新手引导完成，正式高塔开始。"
		apply_limited_post_battle_recovery(session)
		session._start_current_battle()
		return
	if session.battle_index >= 10:
		if session.floor_index >= 10:
			session.phase = "victory"
			session.message = "你已通关第 10 层，当前版本目标完成。"
			return
		session.floor_index += 1
		session.battle_index = 1
	else:
		session.battle_index += 1
	apply_limited_post_battle_recovery(session)
	session._start_current_battle()


func apply_limited_post_battle_recovery(session: Variant) -> void:
	var cap := int(floor(float(session.player["max_hp"]) * 0.80))
	if int(session.player["hp"]) >= cap:
		return
	session.player["hp"] = mini(cap, int(session.player["hp"]) + post_reward_heal_amount(session))


func post_reward_heal_amount(session: Variant) -> int:
	var ratio := 0.08
	var encounter_type := String(session.current_encounter.get("type", "normal"))
	if encounter_type == "boss":
		ratio = 0.35
	elif encounter_type == "elite":
		ratio = 0.18
	return maxi(4, int(round(float(session.player["max_hp"]) * ratio)))
