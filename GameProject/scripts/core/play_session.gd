extends RefCounted
class_name PlaySession

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const CombatEngine = preload("res://scripts/core/combat_engine.gd")
const RunSimulator = preload("res://scripts/core/run_simulator.gd")

const SAVE_PATH := "user://savegame.json"

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
var max_action_points := 1
var player_block := 0
var dodge_layers := 0
var round_index := 0
var pending_state_card := ""
var state_draw_cursor := 0
var reward_options: Array[Dictionary] = []
var pending_reward: Dictionary = {}
var reward_targets: Array[Dictionary] = []
var battle_log: Array[String] = []
var last_events: Array[Dictionary] = []
var charge_used: Dictionary = {}
var pending_charge_effects: Dictionary = {}


func start_new_game(selected_class: String) -> void:
	class_id = selected_class
	player = _roster_player_or_new(selected_class)
	floor_index = 2 if bool(player.get("tutorial_completed", false)) else 1
	battle_index = 1
	phase = "battle"
	message = "派遣%s进入高塔。" % DataCatalog.CLASSES[selected_class]["name"]
	_start_current_battle()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func has_active_run() -> bool:
	var profile := _read_profile()
	return not _dictionary(profile.get("active_run", {})).is_empty()


func get_roster_player(selected_class: String) -> Dictionary:
	var profile := _read_profile()
	var roster := _dictionary(profile.get("roster", {}))
	return _dictionary(roster.get(selected_class, {}))


func save_game() -> bool:
	if phase == "menu" or player.is_empty():
		return false
	var profile := _read_profile()
	var roster := _dictionary(profile.get("roster", {}))
	roster[class_id] = _persistent_player_snapshot(player)
	profile["version"] = 2
	profile["roster"] = roster
	if phase == "game_over" or phase == "victory":
		profile["active_run"] = {}
	else:
		profile["active_run"] = _save_data()
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(profile))
	return true


func load_game() -> bool:
	var profile := _read_profile()
	var active_run := _dictionary(profile.get("active_run", {}))
	if active_run.is_empty():
		return false
	return _load_save_data(active_run)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func is_tutorial() -> bool:
	return floor_index == 1 and not bool(player.get("tutorial_completed", false))


func _start_current_battle() -> void:
	last_events.clear()
	current_encounter = _get_current_encounter()
	enemies = _build_enemies(current_encounter)
	action_points = 1
	max_action_points = 1
	player_block = 0
	dodge_layers = 0
	round_index = 0
	pending_state_card = ""
	charge_used = {}
	pending_charge_effects = _empty_charge_effects()
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
				"dodge_layers": 0,
				"taunt": 0,
				"traits": traits
			})
		else:
			result.append(combat.scale_enemy(unit, floor_index, unit.get("rank", encounter.get("type", "normal")), float(unit.get("formation_scale", 1.0))))
	return result


func _begin_player_turn() -> void:
	round_index += 1
	max_action_points = mini(round_index, 3)
	action_points = max_action_points
	player_block = 0
	pending_state_card = _draw_state_buff()
	message = "你的回合。状态 Buff：%s" % _state_name(pending_state_card)


func _draw_state_buff() -> String:
	var cycle := ["steady", "good", "steady", "great", "steady", "critical", "steady", "read", "good", "perfect_guard", "steady", "fallback"]
	var card_id: String = cycle[state_draw_cursor % cycle.size()]
	state_draw_cursor += 1
	return card_id


func player_attack(target_index: int) -> void:
	last_events.clear()
	if not _can_act(1):
		return
	var target := _valid_target(target_index)
	if target < 0:
		return
	var damage := _modified_value(int(player["attack"]), "attack")
	damage = _apply_charge_attack_modifiers(damage)
	_apply_damage_to_enemy(target, damage)
	var repeats := _consume_charge_repeat("attack")
	for _i in range(repeats):
		if _alive_enemy_count() <= 0:
			break
		_apply_damage_to_enemy(target, damage)
	if pending_state_card == "fallback":
		player_block += maxi(1, int(round(float(player["block_power"]) * 0.5)))
	action_points -= 1
	_consume_state_after_action("attack")
	_after_player_action()


func player_defend() -> void:
	last_events.clear()
	if not _can_act(1):
		return
	var gained := _modified_value(int(player["block_power"]), "defense")
	gained = _apply_charge_defense_modifiers(gained)
	var total_gained := gained
	var repeats := _consume_charge_repeat("defense")
	for _i in range(repeats):
		total_gained += gained
	player_block += total_gained
	action_points -= 1
	battle_log.append("防御：获得 %d 点格挡值。" % total_gained)
	last_events.append({"kind": "defense", "target": "player", "amount": total_gained})
	_consume_state_after_action("defense")
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
	_consume_state_after_action("dodge")
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
		var damage := _modified_value(int(player["attack"]) + int(skill.get("power", 0)) + _skill_attachment_bonus(skill_id, "attack"), "attack")
		damage = _apply_charge_attack_modifiers(damage)
		_apply_damage_to_enemy(target, damage)
		var repeats := _consume_charge_repeat("attack")
		for _i in range(repeats):
			if _alive_enemy_count() <= 0:
				break
			_apply_damage_to_enemy(target, damage)
		if pending_state_card == "fallback":
			player_block += maxi(1, int(round(float(player["block_power"]) * 0.5)))
	elif skill_type == "defense" or skill_type == "stance":
		var gained := _modified_value(int(skill.get("power", 0)) + int(player["block_power"]) + _skill_attachment_bonus(skill_id, "defense"), "defense")
		gained = _apply_charge_defense_modifiers(gained)
		var total_gained := gained
		var repeats := _consume_charge_repeat("defense")
		for _i in range(repeats):
			total_gained += gained
		player_block += total_gained
		battle_log.append("%s：获得 %d 点格挡值。" % [skill["name"], total_gained])
		last_events.append({"kind": "defense", "target": "player", "amount": total_gained})
	elif skill_type == "dodge":
		var gained := 1
		if pending_state_card == "read":
			gained = 2
		dodge_layers += gained
		player_block += int(skill.get("power", 0)) + _skill_attachment_bonus(skill_id, "defense")
		battle_log.append("%s：获得 %d 层躲避。" % [skill["name"], gained])
		last_events.append({"kind": "dodge", "target": "player", "amount": gained})
	elif skill_type == "heal":
		var healed := int(skill.get("power", 0)) + _skill_attachment_bonus(skill_id, "hp")
		player["hp"] = mini(int(player["max_hp"]), int(player["hp"]) + healed)
		battle_log.append("%s：恢复 %d 点生命。" % [skill["name"], healed])
		last_events.append({"kind": "heal", "target": "player", "amount": healed})
	else:
		simulator.attach_reward(player, {"type": "skill", "id": skill_id}, {"kind": "attack", "value": 1, "label": "攻击 +1"})
		simulator._recalculate_player_stats(player, false)
		battle_log.append("%s：攻击提高。" % skill["name"])
	action_points -= cost
	_consume_state_after_action(skill_type)
	_after_player_action()


func end_turn() -> void:
	last_events.clear()
	if phase != "battle":
		return
	_enemy_turn()
	if _alive_enemy_count() > 0 and int(player["hp"]) > 0:
		_begin_player_turn()


func choose_reward(index: int) -> void:
	last_events.clear()
	if phase != "reward":
		return
	if index < 0 or index >= reward_options.size():
		return
	var reward := reward_options[index]
	if _reward_needs_attachment(reward):
		pending_reward = reward.duplicate(true)
		reward_targets = _build_reward_targets()
		if reward_targets.is_empty():
			message = "没有可附着目标，奖励已跳过。"
			_advance_after_reward()
			return
		phase = "reward_target"
		message = "选择「%s」要附着到的装备或技能。" % _reward_short_label(pending_reward)
		return
	match String(reward["kind"]):
		"tutorial_unlock":
			_apply_tutorial_unlock()
		"heal":
			player["hp"] = mini(int(player["max_hp"]), int(player["hp"]) + int(reward["value"]))
		"skill":
			_unlock_next_skill()
	simulator._recalculate_player_stats(player, false)
	_advance_after_reward()


func choose_reward_target(index: int) -> void:
	last_events.clear()
	if phase != "reward_target":
		return
	if index < 0 or index >= reward_targets.size():
		return
	var target := reward_targets[index]
	simulator.attach_reward(player, target, pending_reward)
	simulator._recalculate_player_stats(player, false)
	message = "%s 已附着到 %s。" % [_reward_short_label(pending_reward), _target_label(target)]
	pending_reward = {}
	reward_targets.clear()
	_advance_after_reward()


func _after_player_action() -> void:
	if _alive_enemy_count() == 0:
		_on_victory()
	elif action_points <= 0:
		message = "行动力已用完，请点击结束回合。"


func _enemy_turn() -> void:
	_clear_enemy_taunts()
	var actions := 0
	for i in range(enemies.size()):
		var enemy := enemies[i]
		if int(enemy["hp"]) <= 0:
			continue
		if actions >= 2:
			_enemy_defend(enemy, 0.5)
			continue
		_resolve_enemy_action(enemy, i)
		actions += 1
	if int(player["hp"]) <= 0:
		_on_defeat()


func _clear_enemy_taunts() -> void:
	for enemy in enemies:
		enemy["taunt"] = 0


func _resolve_enemy_action(enemy: Dictionary, enemy_index: int) -> void:
	var intent := _enemy_intent(enemy)
	match intent:
		"taunt":
			enemy["taunt"] = 1
			_enemy_defend(enemy, 1.0)
			battle_log.append("%s 嘲讽并防守。" % enemy["name"])
			last_events.append({"kind": "defense", "target": "enemy", "target_index": enemy_index, "source": enemy["name"], "amount": maxi(1, int(enemy["defense"]))})
		"defend":
			_enemy_defend(enemy, 1.0)
			battle_log.append("%s 进入防守。" % enemy["name"])
			last_events.append({"kind": "defense", "target": "enemy", "target_index": enemy_index, "source": enemy["name"], "amount": maxi(1, int(enemy["defense"]))})
		"dodge":
			enemy["dodge_layers"] = int(enemy.get("dodge_layers", 0)) + 1
			battle_log.append("%s 准备闪避下一次命中。" % enemy["name"])
			last_events.append({"kind": "dodge", "target": "enemy", "target_index": enemy_index, "source": enemy["name"], "amount": 1})
		_:
			_enemy_attack(enemy, false)


func _enemy_defend(enemy: Dictionary, scale: float) -> void:
	enemy["armor"] = int(enemy.get("armor", 0)) + maxi(1, int(round(float(enemy["defense"]) * scale)))


func _enemy_attack(enemy: Dictionary, first_strike: bool) -> void:
	var damage := int(enemy["attack"])
	if first_strike:
		damage = maxi(1, int(round(float(damage) * 0.75)))
	if dodge_layers > 0:
		dodge_layers -= 1
		battle_log.append("躲避了 %s 的攻击。" % enemy["name"])
		last_events.append({"kind": "dodge_enemy_attack", "target": "player", "source": enemy["name"], "amount": 0})
		return
	var raw_damage := damage
	damage = _damage_after_armor(raw_damage)
	var armor_reduced: int = maxi(0, raw_damage - damage)
	if player_block > 0:
		var absorbed: int = mini(player_block, damage)
		player_block -= absorbed
		damage -= absorbed
	if damage > 0:
		player["hp"] = maxi(0, int(player["hp"]) - damage)
	battle_log.append("%s 攻击：护甲减免 %d，造成 %d 点伤害。" % [enemy["name"], armor_reduced, damage])
	last_events.append({"kind": "damage", "target": "player", "source": enemy["name"], "amount": damage})


func _damage_after_armor(raw_damage: int) -> int:
	if raw_damage <= 0:
		return 0
	var armor := maxi(0, int(player["defense"]))
	return maxi(1, int(ceil(float(raw_damage) * 30.0 / float(30 + armor))))


func _apply_damage_to_enemy(target_index: int, damage: int) -> void:
	var taunt_target := _active_taunt_target()
	if taunt_target >= 0:
		target_index = taunt_target
	var enemy := enemies[target_index]
	if int(enemy.get("dodge_layers", 0)) > 0:
		enemy["dodge_layers"] = int(enemy.get("dodge_layers", 0)) - 1
		battle_log.append("%s 闪避了这次命中。" % enemy["name"])
		last_events.append({"kind": "dodge_enemy_attack", "target": "enemy", "target_index": target_index, "amount": 0})
		return
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
			{"kind": "attack", "label": "攻击 +%d" % _floor_value(3), "value": _floor_value(3)},
			{"kind": "hp", "label": "生命上限 +%d" % _floor_value(6), "value": _floor_value(6)},
			{"kind": "charge_bonus_damage", "label": "充能：下一次攻击附加 %d 点伤害" % _floor_value(8), "value": _floor_value(8)}
		]
		player["normal_rewards"] += 1
	elif encounter_type == "elite":
		reward_options = [
			{"kind": "attack", "label": "精英奖励：攻击 +%d" % _floor_value(5), "value": _floor_value(5)},
			{"kind": "defense", "label": "精英奖励：护甲 +%d" % _floor_value(2), "value": _floor_value(2)},
			{"kind": "charge_attack_multiplier", "label": "充能：下一次攻击效果 x1.2", "value": 1.2},
			{"kind": "charge_repeat_attack", "label": "充能：下一次攻击追加一次结算", "value": 1}
		]
		player["elite_rewards"] += 1
	else:
		reward_options = [
			{"kind": "attack", "label": "Boss 五选一卡牌：攻击 +%d" % _floor_value(8), "value": _floor_value(8)},
			{"kind": "charge_defense_multiplier", "label": "Boss 五选一卡牌：充能：下一次防御效果 x1.25", "value": 1.25},
			{"kind": "skill", "label": "技能分支：解锁一个不重复技能", "value": 0}
		]
		player["boss_rewards"] += 1
	message = "选择一个奖励。"


func _advance_after_reward() -> void:
	if is_tutorial() and battle_index == 10:
		player["tutorial_completed"] = true
		floor_index = 2
		battle_index = 1
		message = "新手引导完成，正式高塔开始。"
		_apply_limited_post_battle_recovery()
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
	_apply_limited_post_battle_recovery()
	_start_current_battle()


func _apply_tutorial_unlock() -> void:
	var unlock_id: String = DataCatalog.TUTORIAL_UNLOCKS[class_id][battle_index - 1]
	if DataCatalog.EQUIPMENT.has(unlock_id):
		simulator.equip_item(player, unlock_id)
	else:
		simulator.unlock_skill(player, unlock_id, true)


func _unlock_next_skill() -> void:
	simulator._unlock_next_skill(player)


func _reward_needs_attachment(reward: Dictionary) -> bool:
	var kind := String(reward.get("kind", ""))
	return ["attack", "defense", "hp", "state"].has(kind) or kind.begins_with("charge_")


func _build_reward_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for item_id in player.get("equipment_ids", []):
		targets.append({"type": "equipment", "id": String(item_id)})
	for skill_id in player.get("equipped_skills", []):
		targets.append({"type": "skill", "id": String(skill_id)})
	return targets


func _reward_short_label(reward: Dictionary) -> String:
	var label := String(reward.get("label", "奖励"))
	label = label.replace("精英奖励：", "")
	label = label.replace("Boss 五选一卡牌：", "")
	label = label.replace("永久装备分支：", "")
	label = label.replace("状态卡强化：", "状态 Buff强化：")
	return label


func _target_label(target: Dictionary) -> String:
	var target_type := String(target.get("type", ""))
	var target_id := String(target.get("id", ""))
	if target_type == "equipment" and DataCatalog.EQUIPMENT.has(target_id):
		var item: Dictionary = DataCatalog.EQUIPMENT[target_id]
		return "装备：%s" % item["name"]
	if target_type == "skill" and DataCatalog.SKILLS.has(target_id):
		var skill: Dictionary = DataCatalog.SKILLS[target_id]
		return "技能：%s" % skill["name"]
	return target_id


func _skill_attachment_bonus(skill_id: String, kind: String) -> int:
	return simulator.skill_attachment_bonus(player, skill_id, kind)


func available_charges() -> Array[Dictionary]:
	var charges: Array[Dictionary] = []
	_collect_charges_from_group(charges, "equipment", player.get("equipment_attachments", {}))
	_collect_charges_from_group(charges, "skill", player.get("skill_attachments", {}))
	return charges


func use_charge(charge_id: String) -> void:
	last_events.clear()
	if phase != "battle":
		return
	if bool(charge_used.get(charge_id, false)):
		message = "该充能本场战斗已经使用。"
		return
	var charge := _charge_by_id(charge_id)
	if charge.is_empty():
		message = "没有找到可用充能。"
		return
	charge_used[charge_id] = true
	_apply_charge_effect(charge)
	var label := _reward_short_label(charge)
	battle_log.append("发动充能：%s。" % label)
	message = "已发动充能：%s。" % label
	last_events.append({"kind": "charge", "target": "player", "amount": 0})


func _collect_charges_from_group(result: Array[Dictionary], target_type: String, groups: Dictionary) -> void:
	for target_id in groups.keys():
		var attachments: Array = groups.get(target_id, [])
		for i in range(attachments.size()):
			var attachment: Dictionary = attachments[i]
			var kind := String(attachment.get("kind", ""))
			if not kind.begins_with("charge_"):
				continue
			var charge := attachment.duplicate(true)
			charge["charge_id"] = "%s:%s:%d" % [target_type, String(target_id), i]
			charge["source_label"] = _target_label({"type": target_type, "id": String(target_id)})
			charge["used"] = bool(charge_used.get(charge["charge_id"], false))
			result.append(charge)


func _charge_by_id(charge_id: String) -> Dictionary:
	for charge in available_charges():
		if String(charge.get("charge_id", "")) == charge_id:
			return charge
	return {}


func _apply_charge_effect(charge: Dictionary) -> void:
	_ensure_charge_effects()
	var kind := String(charge.get("kind", ""))
	match kind:
		"charge_attack_multiplier":
			pending_charge_effects["attack_multiplier"] = float(pending_charge_effects.get("attack_multiplier", 1.0)) * float(charge.get("value", 1.0))
		"charge_defense_multiplier":
			pending_charge_effects["defense_multiplier"] = float(pending_charge_effects.get("defense_multiplier", 1.0)) * float(charge.get("value", 1.0))
		"charge_repeat_attack":
			pending_charge_effects["repeat_attack"] = int(pending_charge_effects.get("repeat_attack", 0)) + maxi(1, int(charge.get("value", 1)))
		"charge_repeat_defense":
			pending_charge_effects["repeat_defense"] = int(pending_charge_effects.get("repeat_defense", 0)) + maxi(1, int(charge.get("value", 1)))
		"charge_bonus_damage":
			pending_charge_effects["bonus_damage"] = int(pending_charge_effects.get("bonus_damage", 0)) + int(charge.get("value", 0))


func _apply_charge_attack_modifiers(base: int) -> int:
	_ensure_charge_effects()
	var multiplier := float(pending_charge_effects.get("attack_multiplier", 1.0))
	var bonus := int(pending_charge_effects.get("bonus_damage", 0))
	pending_charge_effects["attack_multiplier"] = 1.0
	pending_charge_effects["bonus_damage"] = 0
	return maxi(1, int(round(float(base) * multiplier)) + bonus)


func _apply_charge_defense_modifiers(base: int) -> int:
	_ensure_charge_effects()
	var multiplier := float(pending_charge_effects.get("defense_multiplier", 1.0))
	pending_charge_effects["defense_multiplier"] = 1.0
	return maxi(1, int(round(float(base) * multiplier)))


func _consume_charge_repeat(action_tag: String) -> int:
	_ensure_charge_effects()
	var key := "repeat_attack" if action_tag == "attack" else "repeat_defense"
	var repeats := int(pending_charge_effects.get(key, 0))
	pending_charge_effects[key] = 0
	return repeats


func _ensure_charge_effects() -> void:
	if pending_charge_effects.is_empty():
		pending_charge_effects = _empty_charge_effects()
	for key in _empty_charge_effects().keys():
		if not pending_charge_effects.has(key):
			pending_charge_effects[key] = _empty_charge_effects()[key]


func _empty_charge_effects() -> Dictionary:
	return {
		"attack_multiplier": 1.0,
		"defense_multiplier": 1.0,
		"bonus_damage": 0,
		"repeat_attack": 0,
		"repeat_defense": 0
	}


func _floor_value(base: int) -> int:
	return base + maxi(0, int(floor(float(floor_index - 1) / 10.0)))


func _apply_limited_post_battle_recovery() -> void:
	var cap := int(floor(float(player["max_hp"]) * 0.80))
	if int(player["hp"]) >= cap:
		return
	player["hp"] = mini(cap, int(player["hp"]) + _post_reward_heal_amount())


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


func _consume_state_after_action(action_tag: String) -> void:
	if pending_state_card == "":
		return
	var card: Dictionary = DataCatalog.STATE_CARDS[pending_state_card]
	var card_tag := String(card.get("tag", ""))
	if card_tag == "attack" and action_tag == "attack":
		pending_state_card = ""
	elif card_tag == "defense" and (action_tag == "defense" or action_tag == "stance"):
		pending_state_card = ""
	elif card_tag == "dodge" and action_tag == "dodge":
		pending_state_card = ""
	elif pending_state_card == "fallback" and action_tag == "attack":
		pending_state_card = ""


func _can_act(cost: int) -> bool:
	if phase != "battle":
		return false
	if action_points < cost:
		message = "行动力不足。"
		return false
	return true


func _valid_target(target_index: int) -> int:
	var taunt_target := _active_taunt_target()
	if taunt_target >= 0:
		return taunt_target
	if enemies.is_empty():
		return -1
	if target_index < 0 or target_index >= enemies.size() or int(enemies[target_index]["hp"]) <= 0:
		for i in range(enemies.size()):
			if int(enemies[i]["hp"]) > 0:
				return i
		return -1
	return target_index


func _active_taunt_target() -> int:
	for i in range(enemies.size()):
		if int(enemies[i]["hp"]) > 0 and int(enemies[i].get("taunt", 0)) > 0:
			return i
	return -1


func _enemy_intent(enemy: Dictionary) -> String:
	var traits: Array = enemy["traits"]
	if traits.has("taunt") and int(enemy.get("taunt", 0)) <= 0 and round_index % 3 == 1:
		return "taunt"
	if traits.has("tank") or traits.has("guard"):
		return "defend" if round_index % 2 == 0 else "attack"
	if traits.has("evade") and round_index % 3 == 0:
		return "dodge"
	if traits.has("fortify") and round_index % 2 == 0:
		return "defend"
	return "attack"


func enemy_intent_text(index: int) -> String:
	if index < 0 or index >= enemies.size():
		return "未知"
	var traits: Array = enemies[index].get("traits", [])
	if traits.has("cunning"):
		return "狡诈"
	var intent := _enemy_intent(enemies[index])
	match intent:
		"taunt":
			return "嘲讽/防守"
		"defend":
			return "防守"
		"dodge":
			return "闪避"
	return "攻击"


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


func _save_data() -> Dictionary:
	return {
		"version": 1,
		"class_id": class_id,
		"floor_index": floor_index,
		"battle_index": battle_index,
		"phase": phase,
		"message": message,
		"player": player,
		"current_encounter": current_encounter,
		"enemies": enemies,
		"action_points": action_points,
		"max_action_points": max_action_points,
		"player_block": player_block,
		"dodge_layers": dodge_layers,
		"round_index": round_index,
		"pending_state_card": pending_state_card,
		"state_draw_cursor": state_draw_cursor,
		"charge_used": charge_used,
		"pending_charge_effects": pending_charge_effects,
		"reward_options": reward_options,
		"pending_reward": pending_reward,
		"reward_targets": reward_targets,
		"battle_log": battle_log
	}


func _read_profile() -> Dictionary:
	if not has_save():
		return _empty_profile()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return _empty_profile()
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK or typeof(json.data) != TYPE_DICTIONARY:
		return _empty_profile()
	var data: Dictionary = json.data
	if int(data.get("version", 0)) == 2:
		if not data.has("roster"):
			data["roster"] = {}
		if not data.has("active_run"):
			data["active_run"] = {}
		return data
	if int(data.get("version", 0)) == 1:
		return _profile_from_legacy_run(data)
	return _empty_profile()


func _empty_profile() -> Dictionary:
	return {
		"version": 2,
		"roster": {},
		"active_run": {}
	}


func _profile_from_legacy_run(run_data: Dictionary) -> Dictionary:
	var roster := {}
	var saved_player := _dictionary(run_data.get("player", {}))
	var saved_class := String(run_data.get("class_id", saved_player.get("class_id", "")))
	if saved_class != "" and DataCatalog.CLASSES.has(saved_class) and not saved_player.is_empty():
		roster[saved_class] = _persistent_player_snapshot(saved_player)
	return {
		"version": 2,
		"roster": roster,
		"active_run": run_data
	}


func _roster_player_or_new(selected_class: String) -> Dictionary:
	var saved_player := get_roster_player(selected_class)
	if saved_player.is_empty():
		return simulator.create_character(selected_class)
	simulator._recalculate_player_stats(saved_player, true)
	return saved_player


func _persistent_player_snapshot(source_player: Dictionary) -> Dictionary:
	var snapshot := source_player.duplicate(true)
	snapshot["equipment_attachments"] = {}
	snapshot["skill_attachments"] = {}
	snapshot["state_attack_bonus"] = 0
	snapshot["state_defense_bonus"] = 0
	snapshot["normal_rewards"] = int(snapshot.get("normal_rewards", 0))
	snapshot["elite_rewards"] = int(snapshot.get("elite_rewards", 0))
	snapshot["boss_rewards"] = int(snapshot.get("boss_rewards", 0))
	simulator._recalculate_player_stats(snapshot, true)
	return snapshot


func _load_save_data(data: Dictionary) -> bool:
	if int(data.get("version", 0)) != 1:
		return false
	var saved_player: Dictionary = _dictionary(data.get("player", {}))
	var saved_class := String(data.get("class_id", saved_player.get("class_id", "")))
	if saved_class == "" or not DataCatalog.CLASSES.has(saved_class):
		return false
	class_id = saved_class
	player = saved_player
	if not player.has("class_id"):
		player["class_id"] = class_id
	floor_index = int(data.get("floor_index", 1))
	battle_index = int(data.get("battle_index", 1))
	phase = String(data.get("phase", "battle"))
	message = String(data.get("message", "继续游戏。"))
	current_encounter = _dictionary(data.get("current_encounter", {}))
	enemies = _dictionary_array(data.get("enemies", []))
	action_points = int(data.get("action_points", 1))
	max_action_points = int(data.get("max_action_points", 1))
	player_block = int(data.get("player_block", 0))
	dodge_layers = int(data.get("dodge_layers", 0))
	round_index = int(data.get("round_index", 0))
	pending_state_card = String(data.get("pending_state_card", ""))
	state_draw_cursor = int(data.get("state_draw_cursor", 0))
	charge_used = _dictionary(data.get("charge_used", {}))
	pending_charge_effects = _dictionary(data.get("pending_charge_effects", {}))
	_ensure_charge_effects()
	reward_options = _dictionary_array(data.get("reward_options", []))
	pending_reward = _dictionary(data.get("pending_reward", {}))
	reward_targets = _dictionary_array(data.get("reward_targets", []))
	battle_log = _string_array(data.get("battle_log", []))
	last_events.clear()
	if phase == "battle" and (current_encounter.is_empty() or enemies.is_empty()):
		_start_current_battle()
	else:
		simulator._recalculate_player_stats(player, false)
	return true


func _dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	return {}


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		if typeof(item) == TYPE_DICTIONARY:
			result.append((item as Dictionary).duplicate(true))
	return result


func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		result.append(String(item))
	return result


func _battle_title() -> String:
	var label := "新手引导" if is_tutorial() else "高塔"
	return "%s 第 %d 层 第 %d 场：%s" % [label, floor_index, battle_index, current_encounter.get("name", current_encounter.get("id", "战斗"))]
