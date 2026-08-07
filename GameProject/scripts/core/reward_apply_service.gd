extends RefCounted
class_name RewardApplyService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const RewardService = preload("res://scripts/core/reward_service.gd")


func choose_reward(session: Variant, index: int) -> void:
	session.last_events.clear()
	if session.phase != "reward":
		return
	if index < 0 or index >= session.reward_options.size():
		return
	var reward: Dictionary = RewardService.normalize_reward(session.reward_options[index])
	session.reward_options[index] = reward
	if RewardService.reward_needs_attachment(reward):
		session.pending_reward = reward.duplicate(true)
		session.reward_targets = build_reward_targets(session)
		if session.reward_targets.is_empty():
			session.message = "没有可附着目标，奖励已跳过。"
			session.run_progress.advance_after_reward(session)
			return
		session.phase = "reward_target"
		session.message = "选择「%s」要附着到的装备或技能。" % RewardService.short_label(session.pending_reward)
		return
	match String(reward["kind"]):
		"tutorial_unlock":
			apply_tutorial_unlock(session)
		"heal":
			session.player["hp"] = mini(int(session.player["max_hp"]), int(session.player["hp"]) + int(reward["value"]))
		"permanent_equipment":
			apply_permanent_equipment(session, reward)
		"tower_equipment":
			apply_tower_equipment(session, reward)
		"tower_consumable":
			apply_tower_consumable(session, reward)
		"tower_skill":
			apply_tower_skill(session, reward)
		"tower_passive_skill":
			apply_tower_passive_skill(session, reward)
	session.character.recalculate_player_stats(session.player, false)
	session.run_progress.advance_after_reward(session)


# 与 PlaySession._target_label 等价：只读 DataCatalog 输出可展示的目标名称，
# 不依赖会话内部状态，供附着选择后的消息回显使用。
func target_label(target: Dictionary) -> String:
	var target_type := String(target.get("type", ""))
	var target_id := String(target.get("id", ""))
	if target_type == "equipment" and DataCatalog.EQUIPMENT.has(target_id):
		var item: Dictionary = DataCatalog.EQUIPMENT[target_id]
		return "装备：%s" % item["name"]
	if target_type == "skill" and DataCatalog.SKILLS.has(target_id):
		var skill: Dictionary = DataCatalog.SKILLS[target_id]
		return "技能：%s" % skill["name"]
	if target_type == "consumable" and DataCatalog.CONSUMABLES.has(target_id):
		var consumable: Dictionary = DataCatalog.CONSUMABLES[target_id]
		return "消耗品：%s" % consumable["name"]
	return target_id


func choose_reward_target(session: Variant, index: int) -> void:
	session.last_events.clear()
	if session.phase != "reward_target":
		return
	if index < 0 or index >= session.reward_targets.size():
		return
	var target: Dictionary = session.reward_targets[index]
	session.character.attach_reward(session.player, target, session.pending_reward)
	session.character.recalculate_player_stats(session.player, false)
	session.message = "%s 已附着到 %s。" % [
		RewardService.short_label(session.pending_reward),
		target_label(target)
	]
	session.pending_reward = {}
	session.reward_targets.clear()
	session.run_progress.advance_after_reward(session)


func build_reward_options(session: Variant) -> void:
	session.reward_options.clear()
	if session.is_tutorial():
		session.reward_options.append(session.rewards.tutorial_reward(session.class_id, session.battle_index))
		session.message = "获得新手引导固定奖励。"
		return
	var encounter_type := String(session.current_encounter["type"])
	if encounter_type == "normal":
		session.reward_options = session.rewards.random_options("normal", 3, session.floor_index)
		session.player["normal_rewards"] += 1
	elif encounter_type == "elite":
		session.reward_options = session.rewards.random_options("elite", 4, session.floor_index)
		session.player["elite_rewards"] += 1
	else:
		session.reward_options = session.rewards.random_options("boss", 3, session.floor_index)
		var boss_skill: Dictionary = session.rewards.tower_skill_reward(session.class_id)
		if not boss_skill.is_empty():
			session.reward_options.append(boss_skill)
		if int(session.player.get("passive_skill_slots", 0)) > 0 and session.rewards.should_drop(0.50):
			var passive_skill: Dictionary = session.rewards.tower_passive_skill_reward()
			if not passive_skill.is_empty():
				session.reward_options.append(passive_skill)
		session.player["boss_rewards"] += 1
	var equipment_chance := float(DataCatalog.TOWER_EQUIPMENT_DROP_CHANCES.get(encounter_type, 0.0))
	if session.rewards.should_drop(equipment_chance):
		var equipment_reward: Dictionary = session.rewards.tower_equipment_reward(session.player, session.class_id)
		if not equipment_reward.is_empty():
			session.reward_options.append(equipment_reward)
	if session.rewards.should_drop(DataCatalog.TOWER_CONSUMABLE_DROP_CHANCE):
		var consumable_reward: Dictionary = session.rewards.tower_consumable_reward()
		if not consumable_reward.is_empty():
				session.reward_options.append(consumable_reward)
	session.message = "选择一个奖励。"


func apply_tutorial_unlock(session: Variant) -> void:
	var unlock_id: String = DataCatalog.TUTORIAL_UNLOCKS[session.class_id][session.battle_index - 1]
	if DataCatalog.EQUIPMENT.has(unlock_id):
		session.character.equip_tower_item(session.player, unlock_id)
	else:
		# 教学只训练技能使用，不把破军或其他武器技能写入永久解锁。
		session.character.add_tower_skill(session.player, unlock_id)


func unlock_next_skill(session: Variant) -> void:
	session.character.unlock_next_skill(session.player)


func apply_permanent_equipment(session: Variant, reward: Dictionary) -> void:
	var item_id := String(reward.get("item_id", ""))
	if item_id == "" or not DataCatalog.EQUIPMENT.has(item_id):
		return
	session.character.equip_item(session.player, item_id)
	session.message = "获得永久装备：%s。" % DataCatalog.EQUIPMENT[item_id]["name"]


func apply_tower_equipment(session: Variant, reward: Dictionary) -> void:
	var item_id := String(reward.get("item_id", ""))
	if item_id == "" or not DataCatalog.EQUIPMENT.has(item_id):
		return
	if not session.character.equip_tower_item(session.player, item_id):
		session.message = "本局装备背包已满，无法获得：%s。" % DataCatalog.EQUIPMENT[item_id]["name"]
		return
	session.message = "获得塔内装备：%s。" % DataCatalog.EQUIPMENT[item_id]["name"]


func apply_tower_consumable(session: Variant, reward: Dictionary) -> void:
	var item_id := String(reward.get("item_id", ""))
	if item_id == "" or not DataCatalog.CONSUMABLES.has(item_id):
		return
	session.character.add_tower_consumable(session.player, item_id)
	session.message = "获得塔内物品：%s。" % DataCatalog.CONSUMABLES[item_id]["name"]


func apply_tower_skill(session: Variant, reward: Dictionary) -> void:
	var skill_id := String(reward.get("skill_id", ""))
	if skill_id == "" or not DataCatalog.SKILLS.has(skill_id):
		return
	session.character.add_tower_skill(session.player, skill_id)
	session.message = "获得塔内技能：%s。" % DataCatalog.SKILLS[skill_id]["name"]


func apply_tower_passive_skill(session: Variant, reward: Dictionary) -> void:
	var skill_id := String(reward.get("skill_id", ""))
	if skill_id == "" or not DataCatalog.PASSIVE_SKILLS.has(skill_id):
		return
	session.character.add_tower_passive_skill(session.player, skill_id)
	session.message = "获得塔内被动：%s。" % DataCatalog.PASSIVE_SKILLS[skill_id]["name"]


func build_reward_targets(session: Variant) -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	var equipment_ids: Array[String] = []
	for item_id in session.player.get("equipment_ids", []):
		var permanent_item_id := String(item_id)
		if permanent_item_id != "" and not equipment_ids.has(permanent_item_id):
			equipment_ids.append(permanent_item_id)
	for item_id in session.player.get("tower_equipment", {}).values():
		var tower_item_id := String(item_id)
		if tower_item_id != "" and not equipment_ids.has(tower_item_id):
			equipment_ids.append(tower_item_id)
	for item_id in equipment_ids:
		targets.append({"type": "equipment", "id": item_id})
	var skill_ids: Array[String] = []
	for skill_id in [session.player.get("weapon_skill_1", ""), session.player.get("weapon_skill_2", "")]:
		var weapon_skill_id := String(skill_id)
		if weapon_skill_id != "" and not skill_ids.has(weapon_skill_id):
			skill_ids.append(weapon_skill_id)
	for skill_id in session.player.get("equipped_skills", []):
		var permanent_skill_id := String(skill_id)
		if permanent_skill_id != "" and not skill_ids.has(permanent_skill_id):
			skill_ids.append(permanent_skill_id)
	for skill_id in session.player.get("tower_equipped_skills", []):
		var tower_skill_id := String(skill_id)
		if tower_skill_id != "" and not skill_ids.has(tower_skill_id):
			skill_ids.append(tower_skill_id)
	for skill_id in skill_ids:
		targets.append({"type": "skill", "id": skill_id})
	return targets
