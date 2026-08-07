extends RefCounted
class_name RewardService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const RuntimeCatalog = preload("res://scripts/core/runtime_catalog.gd")

const REWARD_SCHEMA_VERSION := 1

var rng := RandomNumberGenerator.new()
var catalog: RuntimeCatalog = RuntimeCatalog.new()


func _init(catalog_instance: RuntimeCatalog = null) -> void:
	if catalog_instance != null:
		catalog = catalog_instance


static func make_reward(kind: String, label: String, source: String, target_type: String, effect: Dictionary = {}, legacy_fields: Dictionary = {}) -> Dictionary:
	var reward := {
		"schema_version": REWARD_SCHEMA_VERSION,
		"kind": kind,
		"label": label,
		"source": source,
		"target_type": target_type,
		"effect": effect.duplicate(true),
		"value": effect.get("value", 0)
	}
	for field in legacy_fields.keys():
		reward[String(field)] = legacy_fields[field]
	return reward


static func normalize_reward(reward: Dictionary, default_source: String = "legacy") -> Dictionary:
	var normalized := reward.duplicate(true)
	var kind := String(normalized.get("kind", ""))
	normalized["schema_version"] = maxi(1, int(normalized.get("schema_version", REWARD_SCHEMA_VERSION)))
	if String(normalized.get("source", "")) == "":
		normalized["source"] = _legacy_source(kind, default_source)
	if String(normalized.get("target_type", "")) == "":
		normalized["target_type"] = _legacy_target_type(kind)
	if typeof(normalized.get("effect", null)) != TYPE_DICTIONARY:
		normalized["effect"] = _legacy_effect(normalized)
	return normalized


static func normalize_rewards(rewards: Array[Dictionary], default_source: String = "legacy") -> Array[Dictionary]:
	var normalized: Array[Dictionary] = []
	for reward in rewards:
		normalized.append(normalize_reward(reward, default_source))
	return normalized


static func _legacy_source(kind: String, default_source: String) -> String:
	if kind == "tutorial_unlock":
		return "tutorial"
	if kind.begins_with("tower_"):
		return "tower_reward"
	if ["attack", "defense", "hp", "skill_power"].has(kind):
		return "floor_reward"
	if kind == "permanent_equipment":
		return "npc_blacksmith"
	return default_source


static func _legacy_target_type(kind: String) -> String:
	match kind:
		"tutorial_unlock":
			return "player_unlock"
		"attack", "defense", "hp", "skill_power":
			return "attachment"
		"tower_equipment":
			return "tower_equipment"
		"tower_consumable":
			return "tower_consumable"
		"tower_skill":
			return "tower_skill"
		"tower_passive_skill":
			return "tower_passive_skill"
		"permanent_equipment":
			return "permanent_equipment"
		"heal":
			return "player"
	return "player"


static func _legacy_effect(reward: Dictionary) -> Dictionary:
	var kind := String(reward.get("kind", ""))
	if kind == "tutorial_unlock":
		return {"unlock_id": String(reward.get("item_id", ""))}
	if reward.has("item_id"):
		return {"item_id": String(reward.get("item_id", ""))}
	if reward.has("skill_id"):
		return {"skill_id": String(reward.get("skill_id", ""))}
	if ["attack", "defense", "hp", "skill_power"].has(kind):
		return {"stat": kind, "value": reward.get("value", 0)}
	return {"value": reward.get("value", 0)}


func tutorial_reward(class_id: String, battle_index: int) -> Dictionary:
	var unlock_ids := catalog.tutorial_unlock_ids(class_id)
	if battle_index - 1 >= unlock_ids.size():
		return {}
	var unlock_id: String = unlock_ids[battle_index - 1]
	var label := ""
	if catalog.has("equipment", unlock_id):
		label = "获得装备：%s" % catalog.entry("equipment", unlock_id)["name"]
	else:
		label = "获得技能：%s" % catalog.entry("skills", unlock_id)["name"]
	return make_reward("tutorial_unlock", label, "tutorial", "player_unlock", {"unlock_id": unlock_id}, {"item_id": unlock_id})


func tower_equipment_reward(player: Dictionary, class_id: String) -> Dictionary:
	var candidates: Array[String] = []
	var tower_equipment: Dictionary = player.get("tower_equipment", {})
	var tower_equipment_ids: Array = player.get("tower_equipment_ids", [])
	if tower_equipment_ids.size() >= DataCatalog.TOWER_EQUIPMENT_SLOTS:
		return {}
	var equipment := catalog.runtime_table("equipment")
	for item_id in equipment.keys():
		var item: Dictionary = equipment[item_id]
		if not catalog.equipment_class_compatible(item, class_id):
			continue
		if player.get("equipment_ids", []).has(item_id) or tower_equipment_ids.has(item_id) or tower_equipment.values().has(item_id):
			continue
		candidates.append(String(item_id))
	if candidates.is_empty():
		return {}
	var selected_id := String(candidates[rng.randi_range(0, candidates.size() - 1)])
	return make_reward("tower_equipment", "塔内装备：%s" % equipment[selected_id]["name"], "tower_reward", "tower_equipment", {"item_id": selected_id}, {"item_id": selected_id})


func tower_consumable_reward() -> Dictionary:
	var item_ids: Array[String] = []
	var consumables := catalog.runtime_table("consumables")
	for item_id in consumables.keys():
		item_ids.append(String(item_id))
	if item_ids.is_empty():
		return {}
	var selected_id := String(item_ids[rng.randi_range(0, item_ids.size() - 1)])
	return make_reward("tower_consumable", "塔内物品：%s" % consumables[selected_id]["name"], "tower_reward", "tower_consumable", {"item_id": selected_id}, {"item_id": selected_id})


func tower_skill_reward(class_id: String) -> Dictionary:
	var candidates: Array[String] = []
	var skills := catalog.runtime_table("skills")
	for skill_id in skills.keys():
		var skill: Dictionary = skills[skill_id]
		var slot := int(skill.get("slot", 0))
		if slot < 3 or slot > 4 or not catalog.skill_class_compatible(skill, class_id):
			continue
		candidates.append(String(skill_id))
	if candidates.is_empty():
		return {}
	var selected_id := String(candidates[rng.randi_range(0, candidates.size() - 1)])
	return make_reward("tower_skill", "塔内技能：%s" % skills[selected_id]["name"], "tower_reward", "tower_skill", {"skill_id": selected_id}, {"skill_id": selected_id})


func tower_passive_skill_reward() -> Dictionary:
	var skill_ids: Array[String] = []
	var passive_skills := catalog.runtime_table("passive_skills")
	for skill_id in passive_skills.keys():
		skill_ids.append(String(skill_id))
	if skill_ids.is_empty():
		return {}
	var selected_id := String(skill_ids[rng.randi_range(0, skill_ids.size() - 1)])
	return make_reward("tower_passive_skill", "塔内被动：%s" % passive_skills[selected_id]["name"], "tower_reward", "tower_passive_skill", {"skill_id": selected_id}, {"skill_id": selected_id})


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
	var source := "floor_reward:%s" % reward_rank
	return [
		make_reward("attack", "%s攻击 +%d" % [prefix, attack_value], source, "attachment", {"stat": "attack", "value": attack_value}),
		make_reward("defense", "%s护甲 +%d" % [prefix, defense_value], source, "attachment", {"stat": "defense", "value": defense_value}),
		make_reward("hp", "%s生命上限 +%d" % [prefix, hp_value], source, "attachment", {"stat": "hp", "value": hp_value}),
		make_reward("skill_power", "%s技能倍率 +%.2f" % [prefix, skill_power_value], source, "attachment", {"stat": "skill_power", "value": skill_power_value})
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
	var equipment := catalog.runtime_table("equipment")
	for item_id in equipment.keys():
		var item: Dictionary = equipment[item_id]
		if not catalog.equipment_class_compatible(item, class_id):
			continue
		if player.get("equipment_ids", []).has(item_id):
			continue
		candidates.append(String(item_id))
	if candidates.is_empty():
		var heal_value := floor_value(12, floor_index)
		return make_reward("heal", "永久装备分支：装备已收集完，恢复生命", "npc_blacksmith", "player", {"stat": "hp", "value": heal_value})
	rng.randomize()
	var selected_id := candidates[rng.randi_range(0, candidates.size() - 1)]
	var item: Dictionary = equipment[selected_id]
	return make_reward("permanent_equipment", "永久装备：%s" % item["name"], "npc_blacksmith", "permanent_equipment", {"item_id": selected_id}, {"item_id": selected_id})




func _has_unlocked_all_class_skills(player: Dictionary, class_id: String) -> bool:
	var skills := catalog.runtime_table("skills")
	for skill_id in skills.keys():
		var skill: Dictionary = skills[skill_id]
		if catalog.skill_class_compatible(skill, class_id):
			if not player.get("unlocked_skills", []).has(skill_id):
				return false
	return true
