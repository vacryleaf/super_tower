extends RefCounted
class_name RunProgressService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

# Run 层协调边界：战斗结束（BattleResult）后，由本服务单向协调永久成长、
# 奖励构建、楼层推进和存档回写。只通过 session 的公开状态与公开服务端口
# （save_profile / character / reward_apply / run_progress）读写，
# 不反向调用 Battle 层的命中/技能私有方法。


func on_victory(session: Variant, result: Variant = null) -> void:
	session.player["battles_completed"] += 1
	_unlock_enemies_in_bestiary(session)
	var encounter_type := String(session.current_encounter.get("type", ""))
	if encounter_type == "boss" and not session.is_tutorial():
		session.tower_coins += _tower_coin_reward(session)
		_unlock_boss_npc(session, session.floor_index)
		if session.floor_index >= DataCatalog.MAX_TOWER_FLOOR:
			_record_tower_completion(session)
	elif not session.is_tutorial() and encounter_type in ["normal", "elite"]:
		session.tower_coins += _tower_coin_reward(session)
	session.phase = "reward"
	session.reward_apply.build_reward_options(session)


func on_defeat(session: Variant, result: Variant = null) -> void:
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
		# The opening prologue is separate from the tower. Leave the player at
		# formal floor 1 battle 1 for the next run instead of consuming floor 1.
		session.player["tutorial_completed"] = true
		session.tutorial_active = false
		session.floor_index = 1
		session.battle_index = 1
		session.floor_encounter_count = 0
		session.floor_group_id = ""
		session.pending_tutorial_epilogue = true
		session.phase = "tutorial_epilogue"
		session.message = "城外有座塔拔地而起，众多冒险家纷纷前往，但绝大部分都无法通过第七层，更别提看起来有数百层。"
		return
	if session.battle_index >= 10:
		if session.floor_index >= DataCatalog.MAX_TOWER_FLOOR:
			session.phase = "victory"
			session.message = "你已通关第 %d 层，当前版本目标完成。" % DataCatalog.MAX_TOWER_FLOOR
			return
		session.floor_index += 1
		session.battle_index = 1
		session.floor_encounter_count = 0
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


# 永久成长副作用：图鉴记录、塔币、Boss NPC 解锁和塔通关记录。
# 以下实现与 PlaySession 的旧私有方法等价，仅作为 Run 层权威路径；
# PlaySession 旧实现保留兼容，由 ARCH-20 统一清理。


func _unlock_enemies_in_bestiary(session: Variant) -> void:
	var profile: Dictionary = session.save_profile.read_profile(_persistent_snapshot(session))
	var bestiary: Dictionary = profile.get("bestiary", {})
	for unit in session.current_encounter.get("units", []):
		var enemy_id := String(unit.get("id", unit.get("name", "")))
		if enemy_id == "":
			continue
		if not bestiary.has(enemy_id):
			bestiary[enemy_id] = {"defeated_count": 0}
		bestiary[enemy_id]["defeated_count"] = int(bestiary[enemy_id]["defeated_count"]) + 1
	profile["bestiary"] = bestiary
	session.save_profile.write_profile(profile)


func _tower_coin_reward(session: Variant) -> int:
	var rank := String(session.current_encounter.get("type", "normal"))
	var multiplier := int(DataCatalog.TOWER_COIN_MULTIPLIERS.get(rank, 0))
	var defeated_units := maxi(1, session.current_encounter.get("units", []).size())
	return multiplier * session.effective_tower_level() * defeated_units


func _unlock_boss_npc(session: Variant, boss_floor: int) -> void:
	for npc_id in DataCatalog.NPCS.keys():
		var npc: Dictionary = DataCatalog.NPCS[npc_id]
		if int(npc.get("unlock_boss_floor", 0)) != boss_floor or session.npc_unlocks.has(String(npc_id)):
			continue
		session.npc_unlocks.append(String(npc_id))
		_sync_profile_now(session)


func _record_tower_completion(session: Variant) -> void:
	if session.cleared_tower_bonuses.has(session.tower_bonus):
		return
	session.cleared_tower_bonuses.append(session.tower_bonus)
	session.tower_seeds += 1
	session.max_tower_bonus = maxi(session.max_tower_bonus, mini(DataCatalog.MAX_TOWER_BONUS, session.tower_bonus + 1))
	session.player["blood_potion_seed"] = int(session.player.get("blood_potion_seed", 0)) + 1
	session.player["blood_potion_uses"] = int(session.player.get("blood_potion_uses", 0)) + 1
	if int(session.player.get("passive_skill_slots", 0)) <= 0:
		session.player["passive_skill_slots"] = 1
		session.character.unlock_passive_skill(session.player, "iron_will", true)
	_sync_profile_now(session)


func _sync_profile_now(session: Variant) -> void:
	var profile: Dictionary = session.save_profile.read_profile(_persistent_snapshot(session))
	_sync_profile_progress(session, profile)
	session.save_profile.write_profile(profile)


func _sync_profile_progress(session: Variant, profile: Dictionary) -> void:
	profile["tower_coins"] = session.tower_coins
	profile["npc_unlocks"] = session.npc_unlocks.duplicate()
	profile["npc_features"] = session.npc_features.duplicate()
	profile["encountered_groups"] = session.encountered_groups.duplicate()
	profile["max_tower_bonus"] = session.max_tower_bonus
	profile["cleared_tower_bonuses"] = session.cleared_tower_bonuses.duplicate()
	profile["tower_seeds"] = session.tower_seeds
	profile["tower_stash"] = session.tower_stash.duplicate(true)
	if String(session.class_id) != "" and not session.player.is_empty():
		var roster: Dictionary = profile.get("roster", {})
		roster[String(session.class_id)] = _persistent_snapshot(session).call(session.player)
		profile["roster"] = roster


func _persistent_snapshot(session: Variant) -> Callable:
	return Callable(session, "_persistent_player_snapshot")
