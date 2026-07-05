extends RefCounted
class_name PlaySession

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const CombatEngine = preload("res://scripts/core/combat_engine.gd")
const RunSimulator = preload("res://scripts/core/run_simulator.gd")

var simulator := RunSimulator.new()
var combat := CombatEngine.new()

var player: Dictionary = {}
var class_id := ""
var floor_index := 1
var battle_index := 1
var phase := "menu"
var message := ""
var enemies: Array[Dictionary] = []
var current_encounter: Dictionary = {}
var action_points := 1
var player_armor := 0
var dodge_layers := 0
var round_index := 0
var pending_state_card := ""
var state_cards: Array[String] = []
var state_draw_cursor := 0
var used_state_cards_this_turn := 0
var reward_options: Array[Dictionary] = []
var battle_log: Array[String] = []
var last_events: Array[Dictionary] = []
var last_drawn_cards: Array[String] = []


func start_new_game(selected_class: String) -> void:
	class_id = selected_class
	player = simulator.create_character(selected_class)
	floor_index = 1
	battle_index = 1
	phase = "battle"
	message = "新手引导开始。胜利后会逐步解锁基础装备。"
	_start_current_battle()


func is_tutorial() -> bool:
	return floor_index == 1 and not bool(player.get("tutorial_completed", false))


func _start_current_battle() -> void:
	last_events.clear()
	last_drawn_cards.clear()
	current_encounter = _get_current_encounter()
	enemies = _build_enemies(current_encounter)
	action_points = 1
	player_armor = 0
	dodge_layers = 0
	round_index = 0
	pending_state_card = ""
	state_cards.clear()
	used_state_cards_this_turn = 0
	battle_log.clear()
	phase = "battle"
	message = _battle_title()
	if _has_first_strike():
		_enemy_attack(enemies[0], true)
	_begin_player_turn()


func _get_current_encounter() -> Dictionary:
	if is_tutorial():
		return DataCatalog.TUTORIAL_ENCOUNTERS[battle_index - 1]
	return simulator.generate_encounter(floor_index, battle_index)


func _build_enemies(encounter: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for unit in encounter["units"]:
		if unit.has("hp") and typeof(unit["hp"]) == TYPE_INT:
			var traits: Array = unit.get("traits", [])
			result.append({
				"name": unit["name"],
				"rank": unit.get("rank", encounter.get("type", "normal")),
				"max_hp": int(unit["hp"]),
				"hp": int(unit["hp"]),
				"attack": int(unit["attack"]),
				"defense": int(unit["defense"]),
				"armor": int(unit["defense"]) * 2 if traits.has("thick_skin") else 0,
				"traits": traits
			})
		else:
			result.append(combat.scale_enemy(unit, floor_index, unit.get("rank", encounter.get("type", "normal")), float(unit.get("formation_scale", 1.0))))
	return result


func _begin_player_turn() -> void:
	round_index += 1
	action_points = mini(round_index, 3)
	player_armor = 0
	used_state_cards_this_turn = 0
	_draw_state_cards(1)


func _draw_state_cards(count: int) -> void:
	var cycle := ["steady", "good", "steady", "great", "steady", "critical", "steady", "read", "good", "perfect_guard", "steady", "fallback"]
	last_drawn_cards.clear()
	for i in range(count):
		if state_cards.size() >= 5:
			return
		var card_id: String = cycle[state_draw_cursor % cycle.size()]
		state_cards.append(card_id)
		last_drawn_cards.append(card_id)
		state_draw_cursor += 1


func use_state_card(index: int) -> void:
	last_events.clear()
	if phase != "battle":
		return
	if index < 0 or index >= state_cards.size():
		return
	if used_state_cards_this_turn >= 2:
		message = "每回合最多使用 2 张状态卡。"
		return
	pending_state_card = state_cards[index]
	state_cards.remove_at(index)
	used_state_cards_this_turn += 1
	message = "已准备状态卡：%s" % _state_name(pending_state_card)


func player_attack(target_index: int) -> void:
	last_events.clear()
	if not _can_act(1):
		return
	var target := _valid_target(target_index)
	if target < 0:
		return
	var damage := _modified_value(int(player["attack"]), "attack")
	_apply_damage_to_enemy(target, damage)
	if pending_state_card == "fallback":
		player_armor += maxi(1, int(round(float(player["defense"]) * 0.5)))
	action_points -= 1
	_consume_pending_state()
	_after_player_action()


func player_defend() -> void:
	last_events.clear()
	if not _can_act(1):
		return
	var gained := _modified_value(int(player["defense"]), "defense")
	player_armor += gained
	action_points -= 1
	battle_log.append("防御：获得 %d 点护甲。" % gained)
	last_events.append({"kind": "defense", "target": "player", "amount": gained})
	_consume_pending_state()
	_after_player_action()


func player_dodge() -> void:
	last_events.clear()
	if not _can_act(1):
		return
	var gained := 1
	if pending_state_card == "read":
		gained = 2
	dodge_layers += gained
	action_points -= 1
	battle_log.append("躲避：获得 %d 层躲避。" % gained)
	last_events.append({"kind": "dodge", "target": "player", "amount": gained})
	_consume_pending_state()
	_after_player_action()


func use_skill(slot_index: int, target_index: int) -> void:
	last_events.clear()
	if phase != "battle":
		return
	if slot_index < 0 or slot_index >= player["equipped_skills"].size():
		message = "该技能槽还没有技能。"
		return
	var skill_id: String = player["equipped_skills"][slot_index]
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var cost := int(skill.get("cost", 1))
	if not _can_act(cost):
		return
	var skill_type := String(skill.get("type", "attack"))
	if skill_type == "attack":
		var target := _valid_target(target_index)
		if target < 0:
			return
		var damage := _modified_value(int(player["attack"]) + int(skill.get("power", 0)) + int(player.get("skill_bonus", 0)), "attack")
		_apply_damage_to_enemy(target, damage)
	elif skill_type == "defense" or skill_type == "stance":
		var gained := _modified_value(int(skill.get("power", 0)) + int(player["defense"]), "defense")
		player_armor += gained
		battle_log.append("%s：获得 %d 点护甲。" % [skill["name"], gained])
		last_events.append({"kind": "defense", "target": "player", "amount": gained})
	elif skill_type == "dodge":
		dodge_layers += 1
		player_armor += int(skill.get("power", 0))
		battle_log.append("%s：获得躲避。" % skill["name"])
		last_events.append({"kind": "dodge", "target": "player", "amount": 1})
	elif skill_type == "heal":
		var healed := int(skill.get("power", 0))
		player["hp"] = mini(int(player["max_hp"]), int(player["hp"]) + healed)
		battle_log.append("%s：恢复 %d 点生命。" % [skill["name"], healed])
		last_events.append({"kind": "heal", "target": "player", "amount": healed})
	else:
		player["attack_bonus"] += 1
		simulator._recalculate_player_stats(player, false)
		battle_log.append("%s：攻击提高。" % skill["name"])
	action_points -= cost
	_consume_pending_state()
	_after_player_action()


func end_turn() -> void:
	last_events.clear()
	if phase != "battle":
		return
	_enemy_turn()
	if _alive_enemy_count() > 0 and int(player["hp"]) > 0:
		_begin_player_turn()
		message = "你的回合。"


func choose_reward(index: int) -> void:
	last_events.clear()
	if phase != "reward":
		return
	if index < 0 or index >= reward_options.size():
		return
	var reward := reward_options[index]
	match String(reward["kind"]):
		"tutorial_unlock":
			_apply_tutorial_unlock()
		"attack":
			player["attack_bonus"] += int(reward["value"])
		"defense":
			player["defense_bonus"] += int(reward["value"])
		"hp":
			player["max_hp_bonus"] += int(reward["value"])
		"heal":
			player["hp"] = mini(int(player["max_hp"]), int(player["hp"]) + int(reward["value"]))
		"skill":
			_unlock_next_skill()
		"state":
			player["state_attack_bonus"] += int(reward["value"])
	simulator._recalculate_player_stats(player, false)
	_advance_after_reward()


func _after_player_action() -> void:
	if _alive_enemy_count() == 0:
		_on_victory()
	elif action_points <= 0:
		message = "行动力已用完，请点击结束回合。"


func _enemy_turn() -> void:
	var attackers := 0
	for enemy in enemies:
		if int(enemy["hp"]) <= 0:
			continue
		if attackers >= 2:
			enemy["armor"] += int(enemy["defense"])
			continue
		_enemy_attack(enemy, false)
		attackers += 1
	if int(player["hp"]) <= 0:
		_on_defeat()


func _enemy_attack(enemy: Dictionary, first_strike: bool) -> void:
	var damage := int(enemy["attack"])
	if first_strike:
		damage = maxi(1, int(round(float(damage) * 0.75)))
	if dodge_layers > 0:
		dodge_layers -= 1
		battle_log.append("躲避了 %s 的攻击。" % enemy["name"])
		last_events.append({"kind": "dodge_enemy_attack", "target": "player", "source": enemy["name"], "amount": 0})
		return
	if player_armor > 0:
		var absorbed: int = mini(player_armor, damage)
		player_armor -= absorbed
		damage -= absorbed
	if damage > 0:
		player["hp"] = maxi(0, int(player["hp"]) - damage)
	battle_log.append("%s 造成 %d 点伤害。" % [enemy["name"], damage])
	last_events.append({"kind": "damage", "target": "player", "source": enemy["name"], "amount": damage})


func _apply_damage_to_enemy(target_index: int, damage: int) -> void:
	var enemy := enemies[target_index]
	var remaining := damage
	if int(enemy["armor"]) > 0:
		var absorbed: int = mini(int(enemy["armor"]), remaining)
		enemy["armor"] -= absorbed
		remaining -= absorbed
	if remaining > 0:
		enemy["hp"] = maxi(0, int(enemy["hp"]) - remaining)
	battle_log.append("命中 %s，造成 %d 点伤害。" % [enemy["name"], damage])
	last_events.append({"kind": "damage", "target": "enemy", "target_index": target_index, "amount": damage})


func _on_victory() -> void:
	player["battles_completed"] += 1
	phase = "reward"
	_build_reward_options()


func _on_defeat() -> void:
	if is_tutorial():
		player["tutorial_restarts"] += 1
		player["hp"] = player["max_hp"]
		message = "新手引导失败保护：当前战斗已重开。"
		_start_current_battle()
	else:
		phase = "game_over"
		message = "你在第 %d 层第 %d 场战斗中失败。" % [floor_index, battle_index]


func _build_reward_options() -> void:
	reward_options.clear()
	if is_tutorial():
		var unlock_id: String = DataCatalog.TUTORIAL_UNLOCKS[class_id][battle_index - 1]
		var label := ""
		if DataCatalog.EQUIPMENT.has(unlock_id):
			label = "解锁装备：%s" % DataCatalog.EQUIPMENT[unlock_id]["name"]
		else:
			label = "解锁第一个技能：%s" % DataCatalog.SKILLS[unlock_id]["name"]
		reward_options.append({"kind": "tutorial_unlock", "label": label, "value": 0})
		message = "获得新手引导固定奖励。"
		return
	var encounter_type := String(current_encounter["type"])
	if encounter_type == "normal":
		reward_options = [
			{"kind": "attack", "label": "塔内附着：攻击 +%d" % _floor_value(3), "value": _floor_value(3)},
			{"kind": "defense", "label": "塔内附着：护甲 +%d" % _floor_value(3), "value": _floor_value(3)},
			{"kind": "hp", "label": "塔内附着：生命上限 +%d" % _floor_value(6), "value": _floor_value(6)}
		]
		player["normal_rewards"] += 1
	elif encounter_type == "elite":
		reward_options = [
			{"kind": "attack", "label": "精英奖励：攻击 +%d" % _floor_value(5), "value": _floor_value(5)},
			{"kind": "defense", "label": "精英奖励：护甲 +%d" % _floor_value(5), "value": _floor_value(5)},
			{"kind": "hp", "label": "精英奖励：生命上限 +%d" % _floor_value(10), "value": _floor_value(10)},
			{"kind": "state", "label": "状态卡强化：暴击抽取权重 +1", "value": 1}
		]
		player["elite_rewards"] += 1
	else:
		reward_options = [
			{"kind": "attack", "label": "Boss 五选一卡牌：攻击 +%d" % _floor_value(8), "value": _floor_value(8)},
			{"kind": "hp", "label": "永久装备分支：生命上限 +%d" % _floor_value(18), "value": _floor_value(18)},
			{"kind": "skill", "label": "技能分支：解锁一个不重复技能", "value": 0}
		]
		player["boss_rewards"] += 1
	message = "选择一个奖励。"


func _advance_after_reward() -> void:
	if is_tutorial() and battle_index == 10:
		player["tutorial_completed"] = true
		player["hp"] = player["max_hp"]
		floor_index = 2
		battle_index = 1
		message = "新手引导完成，正式高塔开始。"
		_start_current_battle()
		return
	if battle_index >= 10:
		if floor_index >= 10:
			phase = "victory"
			message = "你已通关第 10 层，当前版本目标完成。"
			return
		floor_index += 1
		battle_index = 1
	else:
		battle_index += 1
	player["hp"] = mini(int(player["max_hp"]), int(player["hp"]) + _post_reward_heal_amount())
	_start_current_battle()


func _apply_tutorial_unlock() -> void:
	var unlock_id: String = DataCatalog.TUTORIAL_UNLOCKS[class_id][battle_index - 1]
	if DataCatalog.EQUIPMENT.has(unlock_id):
		simulator.equip_item(player, unlock_id)
	else:
		simulator.unlock_skill(player, unlock_id, true)


func _unlock_next_skill() -> void:
	simulator._unlock_next_skill(player)


func _floor_value(base: int) -> int:
	return base + maxi(0, int(floor(float(floor_index - 1) / 10.0)))


func _post_reward_heal_amount() -> int:
	var ratio := 0.08
	var encounter_type := String(current_encounter.get("type", "normal"))
	if encounter_type == "boss":
		ratio = 0.35
	elif encounter_type == "elite":
		ratio = 0.18
	return maxi(4, int(round(float(player["max_hp"]) * ratio)))


func _modified_value(base: int, tag: String) -> int:
	var multiplier := 1.0
	if pending_state_card != "":
		var card: Dictionary = DataCatalog.STATE_CARDS[pending_state_card]
		if card["tag"] == "numeric" or card["tag"] == tag:
			multiplier = float(card["multiplier"])
		if pending_state_card == "fallback" and tag == "attack":
			multiplier = 1.0
	return maxi(1, int(round(float(base) * multiplier)))


func _consume_pending_state() -> void:
	pending_state_card = ""


func _can_act(cost: int) -> bool:
	if phase != "battle":
		return false
	if action_points < cost:
		message = "行动力不足。"
		return false
	return true


func _valid_target(target_index: int) -> int:
	if enemies.is_empty():
		return -1
	if target_index < 0 or target_index >= enemies.size() or int(enemies[target_index]["hp"]) <= 0:
		for i in range(enemies.size()):
			if int(enemies[i]["hp"]) > 0:
				return i
		return -1
	return target_index


func _alive_enemy_count() -> int:
	var count := 0
	for enemy in enemies:
		if int(enemy["hp"]) > 0:
			count += 1
	return count


func _has_first_strike() -> bool:
	for enemy in enemies:
		var traits: Array = enemy["traits"]
		if traits.has("first_strike"):
			return true
	return false


func _state_name(card_id: String) -> String:
	return DataCatalog.STATE_CARDS[card_id]["name"]


func _battle_title() -> String:
	var label := "新手引导" if is_tutorial() else "高塔"
	return "%s 第 %d 层 第 %d 场：%s" % [label, floor_index, battle_index, current_encounter.get("name", current_encounter.get("id", "战斗"))]
