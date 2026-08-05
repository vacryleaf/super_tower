extends RefCounted
class_name RewardService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

var rng := RandomNumberGenerator.new()


func tutorial_reward(class_id: String, battle_index: int) -> Dictionary:
	var unlock_id: String = DataCatalog.TUTORIAL_UNLOCKS[class_id][battle_index - 1]
	var label := ""
	if DataCatalog.EQUIPMENT.has(unlock_id):
		label = "获得装备：%s" % DataCatalog.EQUIPMENT[unlock_id]["name"]
	else:
		label = "获得技能：%s" % DataCatalog.SKILLS[unlock_id]["name"]
	return {"kind": "tutorial_unlock", "label": label, "value": 0, "item_id": unlock_id}


func tower_equipment_reward(player: Dictionary, class_id: String) -> Dictionary:
	var candidates: Array[String] = []
	var tower_equipment: Dictionary = player.get("tower_equipment", {})
	var tower_equipment_ids: Array = player.get("tower_equipment_ids", [])
	if tower_equipment_ids.size() >= DataCatalog.TOWER_EQUIPMENT_SLOTS:
		return {}
	for item_id in DataCatalog.EQUIPMENT.keys():
		var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
		if not DataCatalog.equipment_class_compatible(item, class_id):
			continue
		if player.get("equipment_ids", []).has(item_id) or tower_equipment_ids.has(item_id) or tower_equipment.values().has(item_id):
			continue
		candidates.append(String(item_id))
	if candidates.is_empty():
		return {}
	var selected_id := String(candidates[rng.randi_range(0, candidates.size() - 1)])
	return {"kind": "tower_equipment", "label": "塔内装备：%s" % DataCatalog.EQUIPMENT[selected_id]["name"], "item_id": selected_id, "value": 0}


func tower_consumable_reward() -> Dictionary:
	var item_ids: Array[String] = []
	for item_id in DataCatalog.CONSUMABLES.keys():
		item_ids.append(String(item_id))
	if item_ids.is_empty():
		return {}
	var selected_id := String(item_ids[rng.randi_range(0, item_ids.size() - 1)])
	return {"kind": "tower_consumable", "label": "塔内物品：%s" % DataCatalog.CONSUMABLES[selected_id]["name"], "item_id": selected_id, "value": 0}


func tower_skill_reward(class_id: String) -> Dictionary:
	var candidates: Array[String] = []
	for skill_id in DataCatalog.SKILLS.keys():
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		var slot := int(skill.get("slot", 0))
		if slot < 3 or slot > 4 or not DataCatalog.skill_class_compatible(skill, class_id):
			continue
		candidates.append(String(skill_id))
	if candidates.is_empty():
		return {}
	var selected_id := String(candidates[rng.randi_range(0, candidates.size() - 1)])
	return {"kind": "tower_skill", "label": "塔内技能：%s" % DataCatalog.SKILLS[selected_id]["name"], "skill_id": selected_id, "value": 0}


func tower_passive_skill_reward() -> Dictionary:
	var skill_ids: Array[String] = []
	for skill_id in DataCatalog.PASSIVE_SKILLS.keys():
		skill_ids.append(String(skill_id))
	if skill_ids.is_empty():
		return {}
	var selected_id := String(skill_ids[rng.randi_range(0, skill_ids.size() - 1)])
	return {"kind": "tower_passive_skill", "label": "塔内被动：%s" % DataCatalog.PASSIVE_SKILLS[selected_id]["name"], "skill_id": selected_id, "value": 0}


func should_drop(chance: float) -> bool:
	rng.randomize()
	return chance >= 1.0 or rng.randf() < chance


func random_options(reward_rank: String, count: int, floor_index: int) -> Array[Dictionary]:
	var pool := reward_pool(reward_rank, floor_index)
	return sample_rewards_with_core(pool, count)


func reward_pool(reward_rank: String, floor_index: int) -> Array[Dictionary]:
	var prefix := ""
	if reward_rank == "elite":
		prefix = "精英奖励："
	elif reward_rank == "boss":
		prefix = "Boss 五选一卡牌："
	var attack_value := floor_value(3, floor_index)
	var defense_value := floor_value(1, floor_index)
	var hp_value := floor_value(6, floor_index)
	var skill_power_value := 0.08
	if reward_rank == "elite":
		attack_value = floor_value(5, floor_index)
		defense_value = floor_value(2, floor_index)
		hp_value = floor_value(10, floor_index)
		skill_power_value = 0.10
	elif reward_rank == "boss":
		attack_value = floor_value(8, floor_index)
		defense_value = floor_value(3, floor_index)
		hp_value = floor_value(18, floor_index)
		skill_power_value = 0.12
	return [
		{"kind": "attack", "label": "%s攻击 +%d" % [prefix, attack_value], "value": attack_value},
		{"kind": "defense", "label": "%s护甲 +%d" % [prefix, defense_value], "value": defense_value},
		{"kind": "hp", "label": "%s生命上限 +%d" % [prefix, hp_value], "value": hp_value},
		{"kind": "skill_power", "label": "%s技能倍率 +%.2f" % [prefix, skill_power_value], "value": skill_power_value}
	]


func sample_rewards(pool: Array[Dictionary], count: int) -> Array[Dictionary]:
	var available := pool.duplicate(true)
	var result: Array[Dictionary] = []
	if available.is_empty():
		return result
	rng.randomize()
	while result.size() < count and not available.is_empty():
		var index := rng.randi_range(0, available.size() - 1)
		result.append(available[index])
		available.remove_at(index)
	return result


func sample_rewards_with_core(pool: Array[Dictionary], count: int) -> Array[Dictionary]:
	var available := pool.duplicate(true)
	var result: Array[Dictionary] = []
	var core: Array[Dictionary] = []
	for reward in available:
		if is_core_growth_reward(reward):
			core.append(reward)
	rng.randomize()
	if count > 0 and not core.is_empty():
		var core_reward: Dictionary = core[rng.randi_range(0, core.size() - 1)]
		result.append(core_reward)
		remove_matching_reward(available, core_reward)
	while result.size() < count and not available.is_empty():
		var index := rng.randi_range(0, available.size() - 1)
		result.append(available[index])
		available.remove_at(index)
	return sample_rewards(result, result.size())


static func reward_needs_attachment(reward: Dictionary) -> bool:
	var kind := String(reward.get("kind", ""))
	return ["attack", "defense", "hp", "state", "skill_power"].has(kind)


static func is_charge_reward(reward: Dictionary) -> bool:
	return String(reward.get("kind", "")).begins_with("charge_")


static func short_label(reward: Dictionary) -> String:
	var label := String(reward.get("label", "奖励"))
	label = label.replace("精英奖励：", "")
	label = label.replace("Boss 五选一卡牌：", "")
	label = label.replace("永久装备分支：", "")
	label = label.replace("状态卡强化：", "状态 Buff强化：")
	return label


static func floor_value(base: int, floor_index: int) -> int:
	return base + maxi(0, int(floor(float(floor_index - 1) / 10.0)))


static func is_core_growth_reward(reward: Dictionary) -> bool:
	return ["attack", "defense", "hp"].has(String(reward.get("kind", "")))


static func remove_matching_reward(rewards: Array[Dictionary], target: Dictionary) -> void:
	var target_kind := String(target.get("kind", ""))
	var target_label := String(target.get("label", ""))
	for i in range(rewards.size()):
		var reward: Dictionary = rewards[i]
		if String(reward.get("kind", "")) == target_kind and String(reward.get("label", "")) == target_label:
			rewards.remove_at(i)
			return


func permanent_equipment_reward(player: Dictionary, class_id: String, floor_index: int) -> Dictionary:
	var candidates: Array[String] = []
	for item_id in DataCatalog.EQUIPMENT.keys():
		var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
		if not DataCatalog.equipment_class_compatible(item, class_id):
			continue
		if player.get("equipment_ids", []).has(item_id):
			continue
		candidates.append(String(item_id))
	if candidates.is_empty():
		return {"kind": "heal", "label": "永久装备分支：装备已收集完，恢复生命", "value": floor_value(12, floor_index)}
	rng.randomize()
	var selected_id := candidates[rng.randi_range(0, candidates.size() - 1)]
	var item: Dictionary = DataCatalog.EQUIPMENT[selected_id]
	return {
		"kind": "permanent_equipment",
		"label": "永久装备：%s" % item["name"],
		"item_id": selected_id,
		"value": 0
	}




func _has_unlocked_all_class_skills(player: Dictionary, class_id: String) -> bool:
	for skill_id in DataCatalog.SKILLS.keys():
		var skill: Dictionary = DataCatalog.SKILLS[skill_id]
		if DataCatalog.skill_class_compatible(skill, class_id):
			if not player.get("unlocked_skills", []).has(skill_id):
				return false
	return true
