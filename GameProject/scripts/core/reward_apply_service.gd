extends RefCounted
class_name RewardApplyService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const RewardService = preload("res://scripts/core/reward_service.gd")
const MAX_CHARGES := 5


func choose_reward(session: Variant, index: int) -> void:
	session.last_events.clear()
	if session.phase != "reward":
		return
	if index < 0 or index >= session.reward_options.size():
		return
	var reward: Dictionary = session.reward_options[index]
	if RewardService.reward_needs_attachment(reward):
		session.pending_reward = reward.duplicate(true)
		session.reward_targets = build_reward_targets(session)
		if session.reward_targets.is_empty():
			session.message = "没有可附着目标，奖励已跳过。"
			session._advance_after_reward()
			return
		session.phase = "reward_target"
		session.message = "选择「%s」要附着到的装备或技能。" % RewardService.short_label(session.pending_reward)
		return
	match String(reward["kind"]):
		"tutorial_unlock":
			apply_tutorial_unlock(session)
		"heal":
			session.player["hp"] = mini(int(session.player["max_hp"]), int(session.player["hp"]) + int(reward["value"]))
		"skill":
			unlock_next_skill(session)
		"permanent_equipment":
			apply_permanent_equipment(session, reward)
	session.simulator._recalculate_player_stats(session.player, false)
	session._advance_after_reward()


func choose_reward_target(session: Variant, index: int) -> void:
	session.last_events.clear()
	if session.phase != "reward_target":
		return
	if index < 0 or index >= session.reward_targets.size():
		return
	var target: Dictionary = session.reward_targets[index]
	if RewardService.is_charge_reward(session.pending_reward) and session.available_charges().size() >= MAX_CHARGES:
		session.message = "最多只能持有 %d 个充能，本次充能奖励已跳过。" % MAX_CHARGES
		session.pending_reward = {}
		session.reward_targets.clear()
		session._advance_after_reward()
		return
	session.simulator.attach_reward(session.player, target, session.pending_reward)
	session.simulator._recalculate_player_stats(session.player, false)
	session.message = "%s 已附着到 %s。" % [
		RewardService.short_label(session.pending_reward),
		session._target_label(target)
	]
	session.pending_reward = {}
	session.reward_targets.clear()
	session._advance_after_reward()


func build_reward_options(session: Variant) -> void:
	session.reward_options.clear()
	if session.is_tutorial():
		session.reward_options.append(session.rewards.tutorial_reward(session.class_id, session.battle_index))
		session.message = "获得新手引导固定奖励。"
		return
	var encounter_type := String(session.current_encounter["type"])
	if encounter_type == "normal":
		session.reward_options = session.rewards.random_options("normal", 3, session.floor_index, session.available_charges().size())
		session.player["normal_rewards"] += 1
	elif encounter_type == "elite":
		session.reward_options = session.rewards.random_options("elite", 4, session.floor_index, session.available_charges().size())
		session.player["elite_rewards"] += 1
	else:
		session.reward_options = session.rewards.random_options("boss", 3, session.floor_index, session.available_charges().size())
		session.reward_options.append(session.rewards.permanent_equipment_reward(session.player, session.class_id, session.floor_index))
		session.reward_options.append(session.rewards.skill_branch_reward(session.player, session.class_id))
		session.reward_options = session.rewards.sample_rewards(session.reward_options, session.reward_options.size())
		session.player["boss_rewards"] += 1
	session.message = "选择一个奖励。"


func apply_tutorial_unlock(session: Variant) -> void:
	var unlock_id: String = DataCatalog.TUTORIAL_UNLOCKS[session.class_id][session.battle_index - 1]
	if DataCatalog.EQUIPMENT.has(unlock_id):
		session.simulator.equip_item(session.player, unlock_id)
	else:
		session.simulator.unlock_skill(session.player, unlock_id, true)


func unlock_next_skill(session: Variant) -> void:
	session.simulator._unlock_next_skill(session.player)


func apply_permanent_equipment(session: Variant, reward: Dictionary) -> void:
	var item_id := String(reward.get("item_id", ""))
	if item_id == "" or not DataCatalog.EQUIPMENT.has(item_id):
		return
	session.simulator.equip_item(session.player, item_id)
	session.message = "获得永久装备：%s。" % DataCatalog.EQUIPMENT[item_id]["name"]


func build_reward_targets(session: Variant) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for item_id in session.player.get("equipment_ids", []):
		targets.append({"type": "equipment", "id": String(item_id)})
	for skill_id in session.player.get("equipped_skills", []):
		targets.append({"type": "skill", "id": String(skill_id)})
	return targets
