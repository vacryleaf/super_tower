extends RefCounted
class_name RewardService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const MAX_CHARGES := 5

var rng := RandomNumberGenerator.new()


func tutorial_reward(class_id: String, battle_index: int) -> Dictionary:
	var unlock_id: String = DataCatalog.TUTORIAL_UNLOCKS[class_id][battle_index - 1]
	var label := ""
	if DataCatalog.EQUIPMENT.has(unlock_id):
		label = "解锁装备：%s" % DataCatalog.EQUIPMENT[unlock_id]["name"]
	else:
		label = "解锁第一个技能：%s" % DataCatalog.SKILLS[unlock_id]["name"]
	return {"kind": "tutorial_unlock", "label": label, "value": 0}


func random_options(reward_rank: String, count: int, floor_index: int, available_charge_count: int) -> Array[Dictionary]:
	var pool := reward_pool(reward_rank, floor_index)
	if available_charge_count >= MAX_CHARGES:
		var filtered: Array[Dictionary] = []
		for reward in pool:
			if not is_charge_reward(reward):
				filtered.append(reward)
		pool = filtered
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
	var charge_damage := floor_value(8, floor_index)
	var attack_multiplier := 1.15
	var defense_multiplier := 1.15
	if reward_rank == "elite":
		attack_value = floor_value(5, floor_index)
		defense_value = floor_value(2, floor_index)
		hp_value = floor_value(10, floor_index)
		charge_damage = floor_value(12, floor_index)
		attack_multiplier = 1.2
		defense_multiplier = 1.25
	elif reward_rank == "boss":
		attack_value = floor_value(8, floor_index)
		defense_value = floor_value(3, floor_index)
		hp_value = floor_value(18, floor_index)
		charge_damage = floor_value(18, floor_index)
		attack_multiplier = 1.3
		defense_multiplier = 1.35
	return [
		{"kind": "attack", "label": "%s攻击 +%d" % [prefix, attack_value], "value": attack_value},
		{"kind": "defense", "label": "%s护甲 +%d" % [prefix, defense_value], "value": defense_value},
		{"kind": "hp", "label": "%s生命上限 +%d" % [prefix, hp_value], "value": hp_value},
		{"kind": "charge_bonus_damage", "label": "%s充能：下一次攻击附加 %d 点伤害" % [prefix, charge_damage], "value": charge_damage},
		{"kind": "charge_attack_multiplier", "label": "%s充能：下一次攻击效果 x%.2f" % [prefix, attack_multiplier], "value": attack_multiplier},
		{"kind": "charge_defense_multiplier", "label": "%s充能：下一次防御效果 x%.2f" % [prefix, defense_multiplier], "value": defense_multiplier},
		{"kind": "charge_repeat_attack", "label": "%s充能：下一次攻击追加一次结算" % prefix, "value": 1},
		{"kind": "charge_repeat_defense", "label": "%s充能：下一次防御追加一次结算" % prefix, "value": 1}
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
	return ["attack", "defense", "hp", "state"].has(kind) or is_charge_reward(reward)


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
