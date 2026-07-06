extends RefCounted
class_name PlaySession

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const CombatEngine = preload("res://scripts/core/combat_engine.gd")
const RunSimulator = preload("res://scripts/core/run_simulator.gd")
const RewardService = preload("res://scripts/core/reward_service.gd")
const SaveProfile = preload("res://scripts/core/save_profile.gd")
const BattleService = preload("res://scripts/core/battle_service.gd")
const ChargeService = preload("res://scripts/core/charge_service.gd")
const StateBuffService = preload("res://scripts/core/state_buff_service.gd")
const RunProgressService = preload("res://scripts/core/run_progress_service.gd")
const RewardApplyService = preload("res://scripts/core/reward_apply_service.gd")
const EnemyActionRules = preload("res://scripts/core/enemy_action_rules.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const DamageType = preload("res://scripts/core/damage_type.gd")
const TriggerEvents = preload("res://scripts/core/trigger_events.gd")
const ModifierPipeline = preload("res://scripts/core/modifier_pipeline.gd")

const MAX_CHARGES := 5

var simulator := RunSimulator.new()
var combat := CombatEngine.new()
var rewards := RewardService.new()
var save_profile := SaveProfile.new()
var battle_service := BattleService.new()
var charge_service := ChargeService.new()
var state_buffs := StateBuffService.new()
var run_progress := RunProgressService.new()
var reward_apply := RewardApplyService.new()
var enemy_rules := EnemyActionRules.new()
var status_service := StatusService.new()
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
var enemy_attack_multiplier := 1.0
var focus_target_index := -1
var focus_combo_multiplier := 1.0
var counter_stance_charges := 0
var counter_attack_multiplier := 1.0
var dodge_streak := 0
var meticulous_stacks := 0
var seek_bloom_stacks := 0
var attacked_this_turn := false
var reward_options: Array[Dictionary] = []
var pending_reward: Dictionary = {}
var reward_targets: Array[Dictionary] = []
var battle_log: Array[String] = []
var last_events: Array[Dictionary] = []
var charge_used: Dictionary = {}
var charge_ready: Dictionary = {}
var pending_charge_effects: Dictionary = {}


func start_new_game(selected_class: String, start_floor: int = 0) -> void:
	class_id = selected_class
	player = _roster_player_or_new(selected_class)
	if start_floor >= 2:
		player["tutorial_completed"] = true
		floor_index = start_floor
	else:
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
		var current_highest := int(player.get("highest_floor", 0))
		if floor_index > current_highest:
			player["highest_floor"] = floor_index
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
	var current_highest := int(player.get("highest_floor", 0))
	if floor_index > current_highest:
		player["highest_floor"] = floor_index
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
	player["statuses"] = []
	enemy_attack_multiplier = 1.0
	focus_target_index = -1
	focus_combo_multiplier = 1.0
	counter_stance_charges = 0
	counter_attack_multiplier = 1.0
	dodge_streak = 0
	meticulous_stacks = 0
	seek_bloom_stacks = 0
	attacked_this_turn = false
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
	player["statuses"] = []
	enemy_attack_multiplier = 1.0
	focus_target_index = -1
	focus_combo_multiplier = 1.0
	counter_stance_charges = 0
	counter_attack_multiplier = 1.0
	dodge_streak = 0
	meticulous_stacks = 0
	seek_bloom_stacks = 0
	attacked_this_turn = false
	charge_used = {}
	charge_ready = {}
	pending_charge_effects = _empty_charge_effects()
	battle_log.clear()
	phase = "battle"
	message = _battle_title()
	_apply_opening_set_effects()
	if _has_first_strike():
		_enemy_attack(enemies[0], 0, true)
	status_service.fire_trigger(player, TriggerEvents.ON_BATTLE_START, {"battle_log": battle_log, "session": self})
	_begin_player_turn()


func _get_current_encounter() -> Dictionary:
	if is_tutorial():
		return DataCatalog.TUTORIAL_ENCOUNTERS[battle_index - 1]
	return simulator.generate_encounter(floor_index, battle_index)


func _build_enemies(encounter: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for unit in encounter["units"]:
		var enemy := Combatant.from_enemy_unit(unit, String(encounter.get("type", "normal")), floor_index)
		enemy["statuses"] = []
		result.append(enemy)
	return result

func _begin_player_turn() -> void:
	round_index += 1
	max_action_points = mini(round_index, 3)
	action_points = max_action_points
	player_block = 0
	pending_state_card = _draw_state_buff()
	status_service.tick_statuses(player)
	status_service.fire_trigger(player, TriggerEvents.ON_TURN_START, {"battle_log": battle_log, "session": self, "not_attacked_last_turn": not attacked_this_turn})
	for enemy in enemies:
		if int(enemy["hp"]) > 0:
			status_service.tick_statuses(enemy)
			status_service.fire_trigger(enemy, TriggerEvents.ON_TURN_START, {"battle_log": battle_log, "session": self, "not_attacked_last_turn": false})
	attacked_this_turn = false
	var charged_label := _random_ready_charge()
	message = "你的回合。状态 Buff：%s" % _state_name(pending_state_card)
	if charged_label != "":
		message += " 随机充能：%s。" % charged_label


func _draw_state_buff() -> String:
	return state_buffs.draw_state_buff(self)


func _apply_opening_set_effects() -> void:
	var set_effects: Dictionary = player.get("active_set_effects", {})
	for action in set_effects.get("on_battle_start", []):
		var action_type := String(action.get("action", ""))
		match action_type:
			"weaken_enemies":
				var weaken_value := float(action.get("value", 0.0))
				if weaken_value > 0.0:
					enemy_attack_multiplier = 1.0 - weaken_value
					battle_log.append("套装效果：所有敌人伤害降低 %.0f%%。" % (weaken_value * 100.0))
			"gain_block":
				var block_value := int(action.get("value", 0))
				if block_value > 0:
					_add_player_block(block_value)
					battle_log.append("套装效果：首回合获得 %d 点格挡。" % block_value)
			"gain_dodge":
				var dodge_value := int(action.get("value", 0))
				if dodge_value > 0:
					_add_player_dodge(dodge_value)
					battle_log.append("套装效果：首回合获得 %d 层躲避。" % dodge_value)
			"apply_status":
				var status_to_apply: Dictionary = action.get("status", {})
				if not status_to_apply.is_empty():
					status_service.add_status(player, status_to_apply)
					battle_log.append("套装效果：获得 %s。" % String(status_to_apply.get("name", "")))


func player_attack(target_index: int) -> void:
	attacked_this_turn = true
	battle_service.player_attack(self, target_index)


func player_defend() -> void:
	battle_service.player_defend(self)


func player_dodge() -> void:
	battle_service.player_dodge(self)


func use_skill(slot_index: int, target_index: int) -> void:
	attacked_this_turn = true
	battle_service.use_skill(self, slot_index, target_index)


func end_turn() -> void:
	battle_service.end_turn(self)


func choose_reward(index: int) -> void:
	reward_apply.choose_reward(self, index)


func choose_reward_target(index: int) -> void:
	reward_apply.choose_reward_target(self, index)


func _after_player_action() -> void:
	if _alive_enemy_count() == 0:
		_on_victory()
	elif action_points <= 0:
		message = "行动力已用完，请点击结束回合。"


func _player_combatant() -> Dictionary:
	return Combatant.from_player(player, player_block, dodge_layers)


func _resolve_focus_combo(target_index: int) -> float:
	if not _has_set_modifier("dynamic:focus_combo"):
		return 1.0
	if focus_target_index == target_index:
		focus_combo_multiplier *= 1.20
	else:
		focus_target_index = target_index
		focus_combo_multiplier = 1.0
	return focus_combo_multiplier


func _current_attack_value() -> int:
	var resolved_attack := status_service.resolve_stat(player, float(player["attack"]), StatusService.STAT_ATTACK)
	var modifiers := ModifierPipeline.collect_from_session(self, "attack", {"state_card": pending_state_card, "focus_combo_multiplier": focus_combo_multiplier})
	return maxi(1, int(round(ModifierPipeline.resolve(resolved_attack, modifiers))))


func _defense_value() -> int:
	var resolved_defense := status_service.resolve_stat(player, float(player["block_power"]), StatusService.STAT_DEFENSE)
	var modifiers := ModifierPipeline.collect_from_session(self, "defense", {})
	return maxi(1, int(round(ModifierPipeline.resolve(resolved_defense, modifiers))))


func _has_set_modifier(dynamic_value: String) -> bool:
	for mod in player.get("active_set_effects", {}).get("modifiers", []):
		if String(mod.get("value", "")) == dynamic_value:
			return true
	return false


func _skill_attack_value(skill_id: String) -> int:
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var multiplier := float(skill.get("multiplier", 1.0)) + _skill_multiplier_bonus(skill_id, "attack")
	var resolved_attack := status_service.resolve_stat(player, float(player["attack"]), StatusService.STAT_ATTACK)
	var modifiers := ModifierPipeline.collect_from_session(self, "attack", {"skill_id": skill_id, "skill_multiplier": multiplier})
	return maxi(1, int(round(ModifierPipeline.resolve(resolved_attack, modifiers))))


func _skill_defense_value(skill_id: String) -> int:
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var multiplier := float(skill.get("multiplier", skill.get("block_multiplier", 1.0))) + _skill_multiplier_bonus(skill_id, "defense")
	var resolved_defense := status_service.resolve_stat(player, float(player["block_power"]), StatusService.STAT_DEFENSE)
	var modifiers := ModifierPipeline.collect_from_session(self, "defense", {"skill_id": skill_id, "skill_multiplier": multiplier})
	return maxi(1, int(round(ModifierPipeline.resolve(resolved_defense, modifiers))))


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
	var segments := enemy_rules.attack_segments(enemy, round_index, first_strike)
	var base_attack := float(enemy["attack"])
	var resolved_attack := status_service.resolve_stat(enemy, base_attack, StatusService.STAT_ATTACK)
	var status_ratio := resolved_attack / maxf(1.0, base_attack)
	var total_multiplier := enemy_attack_multiplier * status_ratio
	if abs(total_multiplier - 1.0) < 0.001:
		return segments
	var result: Array[int] = []
	for damage in segments:
		result.append(maxi(1, int(round(float(damage) * total_multiplier))))
	return result


func _trigger_counter_attack(enemy_index: int) -> void:
	if counter_stance_charges <= 0:
		return
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	if int(enemies[enemy_index]["hp"]) <= 0:
		return
	counter_stance_charges -= 1
	var damage := maxi(1, int(round(float(_current_attack_value()) * counter_attack_multiplier)))
	damage = maxi(1, int(round(float(damage) * _resolve_focus_combo(enemy_index))))
	battle_log.append("反击架势触发，对 %s 反击 %d 点。" % [enemies[enemy_index]["name"], damage])
	_apply_damage_to_enemy(enemy_index, damage, true)
	if counter_stance_charges <= 0:
		counter_attack_multiplier = 1.0


func _check_dodge_streak() -> void:
	dodge_streak += 1


func get_counter(name: String) -> int:
	match name:
		"meticulous_stacks": return meticulous_stacks
		"seek_bloom_stacks": return seek_bloom_stacks
		_: return 0


func set_counter(name: String, value: int) -> void:
	match name:
		"meticulous_stacks": meticulous_stacks = value
		"seek_bloom_stacks": seek_bloom_stacks = value


func _apply_damage_to_enemy(target_index: int, damage: int, ignore_taunt: bool = false, damage_type: String = "physical") -> void:
	var taunt_target := _active_taunt_target()
	if not ignore_taunt and taunt_target >= 0:
		target_index = taunt_target
	var enemy := enemies[target_index]
	var damage_taken_mult := status_service.resolve_stat(enemy, 1.0, StatusService.STAT_DAMAGE_TAKEN)
	var marked_damage := maxi(0, int(round(float(damage) * damage_taken_mult)))
	if damage_type != DamageType.TRUE:
		var resist_key := DamageType.resist_key(damage_type)
		var base_resist := float(enemy.get("resistances", {}).get(damage_type, 1.0))
		var resist_mult := status_service.resolve_stat(enemy, base_resist, resist_key)
		marked_damage = maxi(0, int(round(float(marked_damage) * resist_mult)))
	var result := Combatant.apply_damage(enemy, marked_damage, damage_type)
	if bool(result["dodged"]):
		battle_log.append("%s 闪避了这次命中。" % enemy["name"])
		last_events.append({"kind": "dodge_enemy_attack", "target": "enemy", "target_index": target_index, "amount": 0})
		status_service.fire_trigger(enemy, TriggerEvents.ON_DODGE, {"battle_log": battle_log, "session": self, "source": player})
		return
	battle_log.append("命中 %s：护甲减免 %d，格挡吸收 %d，造成 %d 点伤害。" % [
		enemy["name"],
		int(result["armor_reduced"]),
		int(result["block_absorbed"]),
		int(result["damage"])
	])
	last_events.append({"kind": "damage", "target": "enemy", "target_index": target_index, "amount": int(result["damage"])})
	var hit_context := {"battle_log": battle_log, "session": self, "source": player, "damage": int(result["damage"]), "target": enemy}
	status_service.fire_trigger(player, TriggerEvents.ON_HIT_DEALT, hit_context)
	status_service.fire_trigger(enemy, TriggerEvents.ON_HIT_RECEIVED, hit_context)
	if int(enemy["hp"]) <= 0:
		status_service.fire_trigger(player, TriggerEvents.ON_KILL, {"battle_log": battle_log, "session": self, "source": player, "target": enemy})


func _on_victory() -> void:
	run_progress.on_victory(self)


func _on_defeat() -> void:
	run_progress.on_defeat(self)


func _build_reward_options() -> void:
	reward_apply.build_reward_options(self)


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
	run_progress.advance_after_reward(self)


func _apply_tutorial_unlock() -> void:
	reward_apply.apply_tutorial_unlock(self)


func _unlock_next_skill() -> void:
	reward_apply.unlock_next_skill(self)


func _reward_needs_attachment(reward: Dictionary) -> bool:
	return RewardService.reward_needs_attachment(reward)


func _is_charge_reward(reward: Dictionary) -> bool:
	return RewardService.is_charge_reward(reward)


func _build_reward_targets() -> Array[Dictionary]:
	return reward_apply.build_reward_targets(self)


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
	return charge_service.available_charges(self)


func use_charge(charge_id: String) -> void:
	charge_service.use_charge(self, charge_id)


func _collect_charges_from_group(result: Array[Dictionary], target_type: String, groups: Dictionary) -> void:
	charge_service.collect_charges_from_group(self, result, target_type, groups)


func _charge_by_id(charge_id: String) -> Dictionary:
	return charge_service.charge_by_id(self, charge_id)


func _random_ready_charge() -> String:
	return charge_service.random_ready_charge(self)


func _apply_charge_effect(charge: Dictionary) -> void:
	charge_service.apply_charge_effect(self, charge)


func _charge_effect_bucket(charge: Dictionary) -> Dictionary:
	return charge_service.charge_effect_bucket(self, charge)


func _apply_charge_attack_modifiers(base: int, skill_id: String = "") -> int:
	return charge_service.apply_charge_attack_modifiers(self, base, skill_id)


func _apply_charge_defense_modifiers(base: int, skill_id: String = "") -> int:
	return charge_service.apply_charge_defense_modifiers(self, base, skill_id)


func _consume_charge_repeat(action_tag: String, skill_id: String = "") -> int:
	return charge_service.consume_charge_repeat(self, action_tag, skill_id)


func _merged_charge_effects(skill_id: String) -> Dictionary:
	return charge_service.merged_charge_effects(self, skill_id)


func _clear_charge_attack_effects(skill_id: String) -> void:
	charge_service.clear_charge_attack_effects(self, skill_id)


func _clear_charge_defense_effects(skill_id: String) -> void:
	charge_service.clear_charge_defense_effects(self, skill_id)


func _ensure_charge_effects() -> void:
	charge_service.ensure_charge_effects(self)


func _empty_charge_effects() -> Dictionary:
	return charge_service.empty_charge_effects()


func _empty_charge_values() -> Dictionary:
	return charge_service.empty_charge_values()


func _floor_value(base: int) -> int:
	return RewardService.floor_value(base, floor_index)


func _apply_limited_post_battle_recovery() -> void:
	run_progress.apply_limited_post_battle_recovery(self)


func _post_reward_heal_amount() -> int:
	return run_progress.post_reward_heal_amount(self)


func _modified_value(base: int, tag: String) -> int:
	return state_buffs.modified_value(self, base, tag)


func _consume_state_after_action(action_tag: String) -> void:
	state_buffs.consume_state_after_action(self, action_tag)


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
	return enemy_rules.intent(enemy, round_index)


func enemy_intent_text(index: int) -> String:
	if index < 0 or index >= enemies.size():
		return "未知"
	return enemy_rules.intent_text(enemies[index], round_index)


func _alive_enemy_count() -> int:
	var count := 0
	for enemy in enemies:
		if int(enemy["hp"]) > 0:
			count += 1
	return count


func _has_first_strike() -> bool:
	return enemy_rules.has_first_strike(enemies)


func _state_name(card_id: String) -> String:
	return state_buffs.state_name(card_id)


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
		"enemy_attack_multiplier": enemy_attack_multiplier,
		"focus_target_index": focus_target_index,
		"focus_combo_multiplier": focus_combo_multiplier,
		"counter_stance_charges": counter_stance_charges,
		"counter_attack_multiplier": counter_attack_multiplier,
		"dodge_streak": dodge_streak,
		"meticulous_stacks": meticulous_stacks,
		"seek_bloom_stacks": seek_bloom_stacks,
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
	snapshot["statuses"] = []
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
	enemy_attack_multiplier = float(data.get("enemy_attack_multiplier", 1.0))
	focus_target_index = int(data.get("focus_target_index", -1))
	focus_combo_multiplier = float(data.get("focus_combo_multiplier", 1.0))
	counter_stance_charges = int(data.get("counter_stance_charges", 0))
	counter_attack_multiplier = float(data.get("counter_attack_multiplier", 1.0))
	dodge_streak = int(data.get("dodge_streak", 0))
	meticulous_stacks = int(data.get("meticulous_stacks", 0))
	seek_bloom_stacks = int(data.get("seek_bloom_stacks", 0))
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
		if not enemy.has("statuses"):
			enemy["statuses"] = []


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
