extends RefCounted
class_name SimulationRewardPolicy

const DataCatalog = preload("res://scripts/core/data_catalog.gd")


func apply_tutorial_unlock(player: Dictionary, battle_zero_index: int, character: Variant) -> void:
	var class_id: String = player["class_id"]
	var unlocks: Array = DataCatalog.TUTORIAL_UNLOCKS[class_id]
	var unlock_id: String = unlocks[battle_zero_index]
	if DataCatalog.EQUIPMENT.has(unlock_id):
		character.equip_item(player, unlock_id)
	elif DataCatalog.SKILLS.has(unlock_id):
		character.unlock_skill(player, unlock_id, true)
	character.recalculate_player_stats(player, false)


func apply_formal_reward(player: Dictionary, battle_type: String, tower_floor: int, character: Variant) -> void:
	var fixed_scale := maxi(0, int(floor(float(tower_floor - 1) / 10.0)))
	if battle_type == "normal":
		_apply_normal_reward(player, fixed_scale, character)
	elif battle_type == "elite":
		_apply_elite_reward(player, fixed_scale, character)
	else:
		_apply_boss_reward(player, fixed_scale, character)
	character.recalculate_player_stats(player, false)
	apply_limited_post_battle_recovery(player, battle_type)


func apply_limited_post_battle_recovery(player: Dictionary, battle_type: String) -> void:
	var cap := int(floor(float(player["max_hp"]) * 0.80))
	if int(player["hp"]) >= cap:
		return
	player["hp"] = mini(cap, int(player["hp"]) + reward_heal_amount(battle_type, player))


func reward_heal_amount(battle_type: String, player: Dictionary) -> int:
	if battle_type == "boss":
		return int(round(float(player["max_hp"]) * 0.35))
	if battle_type == "elite":
		return int(round(float(player["max_hp"]) * 0.18))
	return int(round(float(player["max_hp"]) * 0.08))


func _apply_normal_reward(player: Dictionary, fixed_scale: int, character: Variant) -> void:
	var reward_cycle := int(player["normal_rewards"]) % 4
	if reward_cycle == 0:
		character.attach_reward(player, character.preferred_attachment_target(player, "attack"), {"kind": "attack", "value": 2 + fixed_scale, "label": "攻击 +%d" % (2 + fixed_scale)})
	elif reward_cycle == 1:
		character.attach_reward(player, character.preferred_attachment_target(player, "defense"), {"kind": "defense", "value": 1 + fixed_scale, "label": "护甲 +%d" % (1 + fixed_scale)})
	elif reward_cycle == 2:
		character.attach_reward(player, character.preferred_attachment_target(player, "hp"), {"kind": "hp", "value": 6 + fixed_scale, "label": "生命上限 +%d" % (6 + fixed_scale)})
	else:
		character.attach_reward(player, character.preferred_attachment_target(player, "charge"), {"kind": "charge_bonus_damage", "value": 7 + fixed_scale, "label": "充能：下一次攻击附加 %d 点伤害" % (7 + fixed_scale)})
	player["normal_rewards"] += 1


func _apply_elite_reward(player: Dictionary, fixed_scale: int, character: Variant) -> void:
	var elite_cycle := int(player["elite_rewards"]) % 3
	if elite_cycle == 0:
		character.attach_reward(player, character.preferred_attachment_target(player, "attack"), {"kind": "attack", "value": 4 + fixed_scale, "label": "攻击 +%d" % (4 + fixed_scale)})
	elif elite_cycle == 1:
		character.attach_reward(player, character.preferred_attachment_target(player, "hp"), {"kind": "hp", "value": 18 + fixed_scale, "label": "生命上限 +%d" % (18 + fixed_scale)})
	else:
		character.attach_reward(player, character.preferred_attachment_target(player, "charge"), {"kind": "charge_attack_multiplier", "value": 1.2, "label": "充能：下一次攻击效果 x1.2"})
	player["elite_rewards"] += 1


func _apply_boss_reward(player: Dictionary, fixed_scale: int, character: Variant) -> void:
	var boss_cycle := int(player["boss_rewards"]) % 3
	if boss_cycle == 0:
		character.attach_reward(player, character.preferred_attachment_target(player, "attack"), {"kind": "attack", "value": 8 + fixed_scale, "label": "攻击 +%d" % (8 + fixed_scale)})
	elif boss_cycle == 1:
		character.attach_reward(player, character.preferred_attachment_target(player, "charge"), {"kind": "charge_repeat_defense", "value": 1, "label": "充能：下一次防御追加一次结算"})
	else:
		character.attach_reward(player, character.preferred_attachment_target(player, "skill"), {"kind": "skill_power", "value": 0.10, "label": "技能倍率 +0.10"})
	character.unlock_next_skill(player)
	player["boss_rewards"] += 1
