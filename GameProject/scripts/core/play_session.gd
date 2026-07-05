extends RefCounted
class_name PlaySession

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const CombatEngine = preload("res://scripts/core/combat_engine.gd")
const RunSimulator = preload("res://scripts/core/run_simulator.gd")
const RewardService = preload("res://scripts/core/reward_service.gd")
const SaveProfile = preload("res://scripts/core/save_profile.gd")
const BattleService = preload("res://scripts/core/battle_service.gd")

const MAX_CHARGES := 5

var simulator := RunSimulator.new()
var combat := CombatEngine.new()
var rewards := RewardService.new()
var save_profile := SaveProfile.new()
var battle_service := BattleService.new()
var rng := RandomNumberGenerator.new()

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
var battle_attack_multiplier := 1.0
var counter_stance_charges := 0
var counter_attack_multiplier := 1.0
var reward_options: Array[Dictionary] = []
var pending_reward: Dictionary = {}
var reward_targets: Array[Dictionary] = []
var battle_log: Array[String] = []
var last_events: Array[Dictionary] = []
var charge_used: Dictionary = {}
var charge_ready: Dictionary = {}
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
	return save_profile.has_save()


func has_active_run() -> bool:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	return not _dictionary(profile.get("active_run", {})).is_empty()


func get_roster_player(selected_class: String) -> Dictionary:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster := _dictionary(profile.get("roster", {}))
	return _dictionary(roster.get(selected_class, {}))


func save_game() -> bool:
	if phase == "menu" or player.is_empty():
		return false
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster := _dictionary(profile.get("roster", {}))
	roster[class_id] = _persistent_player_snapshot(player)
	profile["version"] = 2
	profile["roster"] = roster
	if phase == "game_over" or phase == "victory":
		profile["active_run"] = {}
	else:
		profile["active_run"] = _save_data()
	return save_profile.write_profile(profile)


func end_run_to_camp() -> bool:
	if player.is_empty() or class_id == "":
		phase = "menu"
		message = "已返回塔下营地。"
		return false
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster := _dictionary(profile.get("roster", {}))
	roster[class_id] = _persistent_player_snapshot(player)
	profile["version"] = 2
	profile["roster"] = roster
	profile["active_run"] = {}
	if not save_profile.write_profile(profile):
		return false
	_reset_to_camp_state()
	return true


func load_game() -> bool:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var active_run := _dictionary(profile.get("active_run", {}))
	if active_run.is_empty():
		return false
	return _load_save_data(active_run)


func delete_save() -> void:
	save_profile.delete_save()


func _reset_to_camp_state() -> void:
	player = {}
	class_id = ""
	floor_index = 1
	battle_index = 1
	phase = "menu"
	message = "已返回塔下营地。"
	enemies.clear()
	current_encounter = {}
	action_points = 1
	max_action_points = 1
	player_block = 0
	dodge_layers = 0
	round_index = 0
	pending_state_card = ""
	state_draw_cursor = 0
	battle_attack_multiplier = 1.0
	counter_stance_charges = 0
	counter_attack_multiplier = 1.0
	reward_options.clear()
	pending_reward = {}
	reward_targets.clear()
	battle_log.clear()
	last_events.clear()
	charge_used = {}
	charge_ready = {}
	pending_charge_effects = {}


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
	battle_attack_multiplier = 1.0
	counter_stance_charges = 0
	counter_attack_multiplier = 1.0
	charge_used = {}
	charge_ready = {}
	pending_charge_effects = _empty_charge_effects()
	battle_log.clear()
	phase = "battle"
	message = _battle_title()
	if _has_first_strike():
		_enemy_attack(enemies[0], 0, true)
	_begin_player_turn()


func _get_current_encounter() -> Dictionary:
	if is_tutorial():
		return DataCatalog.TUTORIAL_ENCOUNTERS[battle_index - 1]
	return simulator.generate_encounter(floor_index, battle_index)


func _build_enemies(encounter: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for unit in encounter["units"]:
		result.append(Combatant.from_enemy_unit(unit, String(encounter.get("type", "normal")), floor_index))
	return result

func _begin_player_turn() -> void:
	round_index += 1
	max_action_points = mini(round_index, 3)
	action_points = max_action_points
	player_block = 0
	pending_state_card = _draw_state_buff()
	var charged_label := _random_ready_charge()
	message = "你的回合。状态 Buff：%s" % _state_name(pending_state_card)
	if charged_label != "":
		message += " 随机充能：%s。" % charged_label


func _draw_state_buff() -> String:
	var cycle := ["steady", "good", "steady", "great", "steady", "critical", "steady", "read", "good", "perfect_guard", "steady", "fallback"]
	var card_id: String = cycle[state_draw_cursor % cycle.size()]
	state_draw_cursor += 1
	return card_id


func player_attack(target_index: int) -> void:
	battle_service.player_attack(self, target_index)


func player_defend() -> void:
	battle_service.player_defend(self)


func player_dodge() -> void:
	battle_service.player_dodge(self)


func use_skill(slot_index: int, target_index: int) -> void:
	battle_service.use_skill(self, slot_index, target_index)


func end_turn() -> void:
	battle_service.end_turn(self)


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
	if _is_charge_reward(pending_reward) and available_charges().size() >= MAX_CHARGES:
		message = "最多只能持有 %d 个充能，本次充能奖励已跳过。" % MAX_CHARGES
		pending_reward = {}
		reward_targets.clear()
		_advance_after_reward()
		return
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


func _player_combatant() -> Dictionary:
	return Combatant.from_player(player, player_block, dodge_layers)


func _current_attack_value() -> int:
	return maxi(1, int(round(float(player["attack"]) * battle_attack_multiplier)))


func _skill_attack_value(skill_id: String) -> int:
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var multiplier := float(skill.get("multiplier", 1.0)) + _skill_multiplier_bonus(skill_id, "attack")
	return maxi(1, int(round(float(player["attack"]) * battle_attack_multiplier * multiplier)))


func _skill_defense_value(skill_id: String) -> int:
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var multiplier := float(skill.get("multiplier", skill.get("block_multiplier", 1.0))) + _skill_multiplier_bonus(skill_id, "defense")
	return maxi(1, int(round(float(player["block_power"]) * multiplier)))


func _skill_dodge_block_value(skill_id: String) -> int:
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var multiplier := float(skill.get("block_multiplier", 0.0)) + _skill_multiplier_bonus(skill_id, "defense")
	if multiplier <= 0.0:
		return 0
	return maxi(1, int(round(float(player["block_power"]) * multiplier)))


func _skill_heal_value(skill_id: String) -> int:
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var multiplier := float(skill.get("heal_multiplier", 0.0)) + _skill_multiplier_bonus(skill_id, "hp")
	return maxi(1, int(round(float(player["max_hp"]) * multiplier)))


func _sync_player_combatant(combatant_unit: Dictionary) -> void:
	var synced := Combatant.sync_to_player(combatant_unit, player)
	player_block = int(synced["block"])
	dodge_layers = int(synced["dodge_layers"])


func _add_player_block(amount: int) -> void:
	var combatant_unit := _player_combatant()
	combatant_unit["block"] = int(combatant_unit.get("block", 0)) + maxi(0, amount)
	_sync_player_combatant(combatant_unit)


func _add_player_dodge(layers: int) -> void:
	var combatant_unit := _player_combatant()
	Combatant.add_dodge(combatant_unit, layers)
	_sync_player_combatant(combatant_unit)


func _enemy_turn() -> void:
	battle_service.enemy_turn(self)


func _clear_enemy_taunts() -> void:
	for enemy in enemies:
		Combatant.clear_taunt(enemy)


func _clear_enemy_blocks() -> void:
	for enemy in enemies:
		Combatant.clear_block(enemy)


func _resolve_enemy_action(enemy: Dictionary, enemy_index: int) -> void:
	battle_service.resolve_enemy_action(self, enemy, enemy_index)


func _enemy_defend(enemy: Dictionary, scale: float) -> int:
	return battle_service.enemy_defend(enemy, scale)


func _enemy_attack(enemy: Dictionary, enemy_index: int, first_strike: bool) -> void:
	battle_service.enemy_attack(self, enemy, enemy_index, first_strike)


func _enemy_attack_segments(enemy: Dictionary, first_strike: bool) -> Array[int]:
	return battle_service.enemy_attack_segments(self, enemy, first_strike)


func _trigger_counter_attack(enemy_index: int) -> void:
	if counter_stance_charges <= 0:
		return
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	if int(enemies[enemy_index]["hp"]) <= 0:
		return
	counter_stance_charges -= 1
	var damage := maxi(1, int(round(float(_current_attack_value()) * counter_attack_multiplier)))
	battle_log.append("反击架势触发，对 %s 反击 %d 点。" % [enemies[enemy_index]["name"], damage])
	_apply_damage_to_enemy(enemy_index, damage, true)
	if counter_stance_charges <= 0:
		counter_attack_multiplier = 1.0


func _apply_damage_to_enemy(target_index: int, damage: int, ignore_taunt: bool = false) -> void:
	var taunt_target := _active_taunt_target()
	if not ignore_taunt and taunt_target >= 0:
		target_index = taunt_target
	var enemy := enemies[target_index]
	var marked_damage := maxi(0, int(round(float(damage) * float(enemy.get("mark_multiplier", 1.0)))))
	var result := Combatant.apply_damage(enemy, marked_damage)
	if bool(result["dodged"]):
		battle_log.append("%s 闪避了这次命中。" % enemy["name"])
		last_events.append({"kind": "dodge_enemy_attack", "target": "enemy", "target_index": target_index, "amount": 0})
		return
	battle_log.append("命中 %s：护甲减免 %d，格挡吸收 %d，造成 %d 点伤害。" % [
		enemy["name"],
		int(result["armor_reduced"]),
		int(result["block_absorbed"]),
		int(result["damage"])
	])
	last_events.append({"kind": "damage", "target": "enemy", "target_index": target_index, "amount": int(result["damage"])})


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
		reward_options.append(rewards.tutorial_reward(class_id, battle_index))
		message = "获得新手引导固定奖励。"
		return
	var encounter_type := String(current_encounter["type"])
	if encounter_type == "normal":
		reward_options = rewards.random_options("normal", 3, floor_index, available_charges().size())
		player["normal_rewards"] += 1
	elif encounter_type == "elite":
		reward_options = rewards.random_options("elite", 4, floor_index, available_charges().size())
		player["elite_rewards"] += 1
	else:
		reward_options = rewards.random_options("boss", 4, floor_index, available_charges().size())
		reward_options.append({"kind": "skill", "label": "技能分支：解锁一个不重复技能", "value": 0})
		reward_options = rewards.sample_rewards(reward_options, reward_options.size())
		player["boss_rewards"] += 1
	message = "选择一个奖励。"


func _random_reward_options(reward_rank: String, count: int) -> Array[Dictionary]:
	return rewards.random_options(reward_rank, count, floor_index, available_charges().size())


func _reward_pool(reward_rank: String) -> Array[Dictionary]:
	return rewards.reward_pool(reward_rank, floor_index)


func _sample_rewards(pool: Array[Dictionary], count: int) -> Array[Dictionary]:
	return rewards.sample_rewards(pool, count)


func _sample_rewards_with_core(pool: Array[Dictionary], count: int) -> Array[Dictionary]:
	return rewards.sample_rewards_with_core(pool, count)


func _is_core_growth_reward(reward: Dictionary) -> bool:
	return RewardService.is_core_growth_reward(reward)


func _remove_matching_reward(rewards: Array[Dictionary], target: Dictionary) -> void:
	RewardService.remove_matching_reward(rewards, target)


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
	return RewardService.reward_needs_attachment(reward)


func _is_charge_reward(reward: Dictionary) -> bool:
	return RewardService.is_charge_reward(reward)


func _build_reward_targets() -> Array[Dictionary]:
	var targets: Array[Dictionary] = []
	for item_id in player.get("equipment_ids", []):
		targets.append({"type": "equipment", "id": String(item_id)})
	for skill_id in player.get("equipped_skills", []):
		targets.append({"type": "skill", "id": String(skill_id)})
	return targets


func _reward_short_label(reward: Dictionary) -> String:
	return RewardService.short_label(reward)


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


func _skill_multiplier_bonus(skill_id: String, kind: String = "") -> float:
	return simulator.skill_multiplier_bonus(player, skill_id, kind)


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
	if not bool(charge_ready.get(charge_id, false)):
		message = "该充能尚未就绪。"
		return
	var charge := _charge_by_id(charge_id)
	if charge.is_empty():
		message = "没有找到可用充能。"
		return
	charge_used[charge_id] = true
	charge_ready[charge_id] = false
	_apply_charge_effect(charge)
	var label := _reward_short_label(charge)
	battle_log.append("发动充能：%s。" % label)
	message = "已发动充能：%s。" % label
	last_events.append({"kind": "charge", "target": "player", "amount": 0})


func _collect_charges_from_group(result: Array[Dictionary], target_type: String, groups: Dictionary) -> void:
	for target_id in groups.keys():
		var attachments: Array = groups.get(target_id, [])
		for i in range(attachments.size()):
			if result.size() >= MAX_CHARGES:
				return
			var attachment: Dictionary = attachments[i]
			var kind := String(attachment.get("kind", ""))
			if not kind.begins_with("charge_"):
				continue
			var charge := attachment.duplicate(true)
			charge["charge_id"] = "%s:%s:%d" % [target_type, String(target_id), i]
			charge["source_label"] = _target_label({"type": target_type, "id": String(target_id)})
			charge["used"] = bool(charge_used.get(charge["charge_id"], false))
			charge["ready"] = bool(charge_ready.get(charge["charge_id"], false))
			result.append(charge)


func _charge_by_id(charge_id: String) -> Dictionary:
	for charge in available_charges():
		if String(charge.get("charge_id", "")) == charge_id:
			return charge
	return {}


func _random_ready_charge() -> String:
	var charges := available_charges()
	var candidates: Array[Dictionary] = []
	for charge in charges:
		var charge_id := String(charge.get("charge_id", ""))
		if bool(charge.get("used", false)):
			continue
		if bool(charge.get("ready", false)):
			continue
		candidates.append(charge)
	if candidates.is_empty():
		return ""
	rng.randomize()
	var selected: Dictionary = candidates[rng.randi_range(0, candidates.size() - 1)]
	var selected_id := String(selected.get("charge_id", ""))
	charge_ready[selected_id] = true
	return _reward_short_label(selected)


func _apply_charge_effect(charge: Dictionary) -> void:
	_ensure_charge_effects()
	var effects := _charge_effect_bucket(charge)
	var kind := String(charge.get("kind", ""))
	match kind:
		"charge_attack_multiplier":
			effects["attack_multiplier"] = float(effects.get("attack_multiplier", 1.0)) * float(charge.get("value", 1.0))
		"charge_defense_multiplier":
			effects["defense_multiplier"] = float(effects.get("defense_multiplier", 1.0)) * float(charge.get("value", 1.0))
		"charge_repeat_attack":
			effects["repeat_attack"] = int(effects.get("repeat_attack", 0)) + maxi(1, int(charge.get("value", 1)))
		"charge_repeat_defense":
			effects["repeat_defense"] = int(effects.get("repeat_defense", 0)) + maxi(1, int(charge.get("value", 1)))
		"charge_bonus_damage":
			effects["bonus_damage"] = int(effects.get("bonus_damage", 0)) + int(charge.get("value", 0))


func _charge_effect_bucket(charge: Dictionary) -> Dictionary:
	var target_type := String(charge.get("target_type", ""))
	var target_id := String(charge.get("target_id", ""))
	if target_type == "skill" and target_id != "":
		var skills: Dictionary = pending_charge_effects.get("skills", {})
		if not skills.has(target_id):
			skills[target_id] = _empty_charge_values()
		pending_charge_effects["skills"] = skills
		return skills[target_id]
	return pending_charge_effects["global"]


func _apply_charge_attack_modifiers(base: int, skill_id: String = "") -> int:
	_ensure_charge_effects()
	var effects := _merged_charge_effects(skill_id)
	var multiplier := float(effects.get("attack_multiplier", 1.0))
	var bonus := int(effects.get("bonus_damage", 0))
	_clear_charge_attack_effects(skill_id)
	return maxi(1, int(round(float(base) * multiplier)) + bonus)


func _apply_charge_defense_modifiers(base: int, skill_id: String = "") -> int:
	_ensure_charge_effects()
	var effects := _merged_charge_effects(skill_id)
	var multiplier := float(effects.get("defense_multiplier", 1.0))
	_clear_charge_defense_effects(skill_id)
	return maxi(1, int(round(float(base) * multiplier)))


func _consume_charge_repeat(action_tag: String, skill_id: String = "") -> int:
	_ensure_charge_effects()
	var key := "repeat_attack" if action_tag == "attack" else "repeat_defense"
	var repeats := int(pending_charge_effects["global"].get(key, 0))
	pending_charge_effects["global"][key] = 0
	if skill_id != "":
		var skills: Dictionary = pending_charge_effects.get("skills", {})
		if skills.has(skill_id):
			repeats += int(skills[skill_id].get(key, 0))
			skills[skill_id][key] = 0
	return repeats


func _merged_charge_effects(skill_id: String) -> Dictionary:
	var global_effects: Dictionary = pending_charge_effects["global"]
	var result := global_effects.duplicate(true)
	if skill_id != "":
		var skills: Dictionary = pending_charge_effects.get("skills", {})
		if skills.has(skill_id):
			var skill_effects: Dictionary = skills[skill_id]
			result["attack_multiplier"] = float(result.get("attack_multiplier", 1.0)) * float(skill_effects.get("attack_multiplier", 1.0))
			result["defense_multiplier"] = float(result.get("defense_multiplier", 1.0)) * float(skill_effects.get("defense_multiplier", 1.0))
			result["bonus_damage"] = int(result.get("bonus_damage", 0)) + int(skill_effects.get("bonus_damage", 0))
			result["repeat_attack"] = int(result.get("repeat_attack", 0)) + int(skill_effects.get("repeat_attack", 0))
			result["repeat_defense"] = int(result.get("repeat_defense", 0)) + int(skill_effects.get("repeat_defense", 0))
	return result


func _clear_charge_attack_effects(skill_id: String) -> void:
	pending_charge_effects["global"]["attack_multiplier"] = 1.0
	pending_charge_effects["global"]["bonus_damage"] = 0
	if skill_id != "":
		var skills: Dictionary = pending_charge_effects.get("skills", {})
		if skills.has(skill_id):
			skills[skill_id]["attack_multiplier"] = 1.0
			skills[skill_id]["bonus_damage"] = 0


func _clear_charge_defense_effects(skill_id: String) -> void:
	pending_charge_effects["global"]["defense_multiplier"] = 1.0
	if skill_id != "":
		var skills: Dictionary = pending_charge_effects.get("skills", {})
		if skills.has(skill_id):
			skills[skill_id]["defense_multiplier"] = 1.0


func _ensure_charge_effects() -> void:
	if pending_charge_effects.is_empty():
		pending_charge_effects = _empty_charge_effects()
	if not pending_charge_effects.has("global"):
		var legacy := pending_charge_effects.duplicate(true)
		pending_charge_effects = _empty_charge_effects()
		for key in _empty_charge_values().keys():
			if legacy.has(key):
				pending_charge_effects["global"][key] = legacy[key]
	if not pending_charge_effects.has("skills"):
		pending_charge_effects["skills"] = {}
	for key in _empty_charge_values().keys():
		if not pending_charge_effects["global"].has(key):
			pending_charge_effects["global"][key] = _empty_charge_values()[key]


func _empty_charge_effects() -> Dictionary:
	return {
		"global": _empty_charge_values(),
		"skills": {}
	}


func _empty_charge_values() -> Dictionary:
	return {
		"attack_multiplier": 1.0,
		"defense_multiplier": 1.0,
		"bonus_damage": 0,
		"repeat_attack": 0,
		"repeat_defense": 0
	}


func _floor_value(base: int) -> int:
	return RewardService.floor_value(base, floor_index)


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
		"battle_attack_multiplier": battle_attack_multiplier,
		"counter_stance_charges": counter_stance_charges,
		"counter_attack_multiplier": counter_attack_multiplier,
		"charge_used": charge_used,
		"charge_ready": charge_ready,
		"pending_charge_effects": pending_charge_effects,
		"reward_options": reward_options,
		"pending_reward": pending_reward,
		"reward_targets": reward_targets,
		"battle_log": battle_log
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
	_normalize_loaded_enemies()
	action_points = int(data.get("action_points", 1))
	max_action_points = int(data.get("max_action_points", 1))
	player_block = int(data.get("player_block", 0))
	dodge_layers = int(data.get("dodge_layers", 0))
	round_index = int(data.get("round_index", 0))
	pending_state_card = String(data.get("pending_state_card", ""))
	state_draw_cursor = int(data.get("state_draw_cursor", 0))
	battle_attack_multiplier = float(data.get("battle_attack_multiplier", 1.0))
	counter_stance_charges = int(data.get("counter_stance_charges", 0))
	counter_attack_multiplier = float(data.get("counter_attack_multiplier", 1.0))
	charge_used = _dictionary(data.get("charge_used", {}))
	charge_ready = _dictionary(data.get("charge_ready", {}))
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


func _normalize_loaded_enemies() -> void:
	for enemy in enemies:
		Combatant.normalize_enemy(enemy)


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
