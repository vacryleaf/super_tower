extends RefCounted
class_name PlaySession

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const RunSimulator = preload("res://scripts/core/run_simulator.gd")
const RewardService = preload("res://scripts/core/reward_service.gd")
const SaveProfile = preload("res://scripts/core/save_profile.gd")
const BattleService = preload("res://scripts/core/battle_service.gd")
const ChargeService = preload("res://scripts/core/charge_service.gd")
const StateBuffService = preload("res://scripts/core/state_buff_service.gd")
const RunProgressService = preload("res://scripts/core/run_progress_service.gd")
const RewardApplyService = preload("res://scripts/core/reward_apply_service.gd")
const RunStateSerializer = preload("res://scripts/core/run_state_serializer.gd")
const EnemyActionRules = preload("res://scripts/core/enemy_action_rules.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const DamageType = preload("res://scripts/core/damage_type.gd")
const TriggerEvents = preload("res://scripts/core/trigger_events.gd")
const CombatRules = preload("res://scripts/core/combat_rules.gd")
const BattleState = preload("res://scripts/core/battle_state.gd")
const ActionSource = preload("res://scripts/core/action_source.gd")
const ActionContext = preload("res://scripts/core/action_context.gd")
const ActionPipeline = preload("res://scripts/core/action_pipeline.gd")

const MAX_CHARGES := 5

var simulator := RunSimulator.new()
var rewards := RewardService.new()
var save_profile := SaveProfile.new()
var battle_service := BattleService.new()
var charge_service := ChargeService.new()
var state_buffs := StateBuffService.new()
var run_progress := RunProgressService.new()
var reward_apply := RewardApplyService.new()
var run_state_serializer := RunStateSerializer.new()
var enemy_rules := EnemyActionRules.new()
var status_service := StatusService.new()
var rng := RandomNumberGenerator.new()

var battle_state := BattleState.new()

var tower_coins := 0

var player: Dictionary:
	get:
		return battle_state.player
	set(value):
		battle_state.player = value
var class_id: String:
	get:
		return battle_state.class_id
	set(value):
		battle_state.class_id = value
var floor_index: int:
	get:
		return battle_state.floor_index
	set(value):
		battle_state.floor_index = value
var battle_index: int:
	get:
		return battle_state.battle_index
	set(value):
		battle_state.battle_index = value
var phase: String:
	get:
		return battle_state.phase
	set(value):
		battle_state.phase = value
var message: String:
	get:
		return battle_state.message
	set(value):
		battle_state.message = value
var enemies: Array[Dictionary]:
	get:
		return battle_state.enemies
	set(value):
		battle_state.enemies = value
var allies: Array[Dictionary]:
	get:
		return battle_state.allies
	set(value):
		battle_state.allies = value
var current_encounter: Dictionary:
	get:
		return battle_state.current_encounter
	set(value):
		battle_state.current_encounter = value
var energy: int:
	get:
		return battle_state.energy
	set(value):
		battle_state.energy = value
var has_acted: bool:
	get:
		return battle_state.has_acted
	set(value):
		battle_state.has_acted = value
var skill_cooldowns: Dictionary:
	get:
		return battle_state.skill_cooldowns
	set(value):
		battle_state.skill_cooldowns = value
var player_block: int:
	get:
		return battle_state.player_block
	set(value):
		battle_state.player_block = value
var dodge_layers: int:
	get:
		return battle_state.dodge_layers
	set(value):
		battle_state.dodge_layers = value
var round_index: int:
	get:
		return battle_state.round_index
	set(value):
		battle_state.round_index = value
var pending_state_card: String:
	get:
		return battle_state.pending_state_card
	set(value):
		battle_state.pending_state_card = value
var state_draw_cursor: int:
	get:
		return battle_state.state_draw_cursor
	set(value):
		battle_state.state_draw_cursor = value
var battle_attack_multiplier: float:
	get:
		return battle_state.battle_attack_multiplier
	set(value):
		battle_state.battle_attack_multiplier = value
var enemy_attack_multiplier: float:
	get:
		return battle_state.enemy_attack_multiplier
	set(value):
		battle_state.enemy_attack_multiplier = value
var focus_target_index: int:
	get:
		return battle_state.focus_target_index
	set(value):
		battle_state.focus_target_index = value
var focus_combo_multiplier: float:
	get:
		return battle_state.focus_combo_multiplier
	set(value):
		battle_state.focus_combo_multiplier = value
var counter_stance_charges: int:
	get:
		return battle_state.counter_stance_charges
	set(value):
		battle_state.counter_stance_charges = value
var counter_attack_multiplier: float:
	get:
		return battle_state.counter_attack_multiplier
	set(value):
		battle_state.counter_attack_multiplier = value
var dodge_streak: int:
	get:
		return battle_state.dodge_streak
	set(value):
		battle_state.dodge_streak = value
var meticulous_stacks: int:
	get:
		return battle_state.meticulous_stacks
	set(value):
		battle_state.meticulous_stacks = value
var seek_bloom_stacks: int:
	get:
		return battle_state.seek_bloom_stacks
	set(value):
		battle_state.seek_bloom_stacks = value
var ranger_hit_count: int:
	get:
		return battle_state.ranger_hit_count
	set(value):
		battle_state.ranger_hit_count = value
var attacked_this_turn: bool:
	get:
		return battle_state.attacked_this_turn
	set(value):
		battle_state.attacked_this_turn = value
var reward_options: Array[Dictionary]:
	get:
		return battle_state.reward_options
	set(value):
		battle_state.reward_options = value
var pending_reward: Dictionary:
	get:
		return battle_state.pending_reward
	set(value):
		battle_state.pending_reward = value
var reward_targets: Array[Dictionary]:
	get:
		return battle_state.reward_targets
	set(value):
		battle_state.reward_targets = value
var battle_log: Array[String]:
	get:
		return battle_state.battle_log
	set(value):
		battle_state.battle_log = value
var last_events: Array[Dictionary]:
	get:
		return battle_state.last_events
	set(value):
		battle_state.last_events = value
var charge_used: Dictionary:
	get:
		return battle_state.charge_used
	set(value):
		battle_state.charge_used = value
var charge_ready: Dictionary:
	get:
		return battle_state.charge_ready
	set(value):
		battle_state.charge_ready = value
var pending_charge_effects: Dictionary:
	get:
		return battle_state.pending_charge_effects
	set(value):
		battle_state.pending_charge_effects = value


func _load_account() -> void:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	tower_coins = int(profile.get("tower_coins", 0))


func start_new_game(selected_class: String, start_floor: int = 0) -> void:
	class_id = selected_class
	_load_account()
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
	profile["tower_coins"] = tower_coins
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
	profile["tower_coins"] = tower_coins
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
	battle_state.reset()


func is_tutorial() -> bool:
	return floor_index == 1 and not bool(player.get("tutorial_completed", false))


func _start_current_battle() -> void:
	last_events.clear()
	current_encounter = _get_current_encounter()
	enemies = _build_enemies(current_encounter)
	allies = []
	has_acted = false
	skill_cooldowns = {}
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
	return CombatRules.build_enemies(encounter, floor_index)

func _begin_player_turn() -> void:
	round_index += 1
	has_acted = false
	_tick_skill_cooldowns()
	player_block = 0
	pending_state_card = _draw_state_buff()
	status_service.tick_statuses(player)
	status_service.fire_trigger(player, TriggerEvents.ON_TURN_START, {"battle_log": battle_log, "session": self, "not_attacked_last_turn": not attacked_this_turn})
	for enemy in enemies:
		if int(enemy["hp"]) > 0:
			status_service.tick_statuses(enemy)
			status_service.fire_trigger(enemy, TriggerEvents.ON_TURN_START, {"battle_log": battle_log, "session": self, "not_attacked_last_turn": false})
	for ally in allies:
		if int(ally["hp"]) > 0:
			status_service.tick_statuses(ally)
			status_service.fire_trigger(ally, TriggerEvents.ON_TURN_START, {"battle_log": battle_log, "session": self, "not_attacked_last_turn": false})
	attacked_this_turn = false
	ranger_hit_count = 0
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
			"set_innate_skill":
				var slot := String(action.get("slot", ""))
				var new_skill_id := String(action.get("skill_id", ""))
				if slot != "" and new_skill_id != "" and player["innate_skills"].has(slot):
					player["innate_skills"][slot] = new_skill_id


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
	if _opposing_units_alive() == 0:
		_on_victory()


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


func _current_attack_value(action_source: String = "") -> int:
	return CombatRules.current_attack_value(self, action_source)


func _defense_value() -> int:
	return CombatRules.defense_value(self)


func _has_set_modifier(dynamic_value: String) -> bool:
	for mod in player.get("active_set_effects", {}).get("modifiers", []):
		if String(mod.get("value", "")) == dynamic_value:
			return true
	return false


func _skill_attack_value(skill_id: String, action_source: String = "") -> int:
	return CombatRules.skill_attack_value(self, skill_id, action_source)


func _skill_defense_value(skill_id: String) -> int:
	return CombatRules.skill_defense_value(self, skill_id)


func _skill_dodge_block_value(skill_id: String) -> int:
	return CombatRules.skill_dodge_block_value(self, skill_id)


func _skill_heal_value(skill_id: String) -> int:
	return CombatRules.skill_heal_value(self, skill_id)


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
	CombatRules.clear_enemy_taunts(enemies)
	CombatRules.clear_enemy_taunts(allies)


func _clear_enemy_blocks() -> void:
	CombatRules.clear_enemy_blocks(enemies)
	CombatRules.clear_enemy_blocks(allies)


func _resolve_enemy_action(enemy: Dictionary, enemy_index: int) -> void:
	battle_service.resolve_enemy_action(self, enemy, enemy_index)


func _enemy_defend(enemy: Dictionary, scale: float) -> int:
	return battle_service.enemy_defend(enemy, scale)


func _enemy_attack(enemy: Dictionary, enemy_index: int, first_strike: bool) -> void:
	battle_service.enemy_attack(self, enemy, enemy_index, first_strike)


func _enemy_attack_segments(enemy: Dictionary, first_strike: bool) -> Array[int]:
	return CombatRules.enemy_attack_segments(self, enemy, first_strike)


func _trigger_counter_attack(enemy_index: int) -> void:
	if counter_stance_charges <= 0:
		return
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	if int(enemies[enemy_index]["hp"]) <= 0:
		return
	counter_stance_charges -= 1
	var damage := maxi(1, int(round(float(_current_attack_value(ActionSource.COUNTER_ATTACK)) * counter_attack_multiplier)))
	damage = maxi(1, int(round(float(damage) * _resolve_focus_combo(enemy_index))))
	battle_log.append("反击架势触发，对 %s 反击 %d 点。" % [enemies[enemy_index]["name"], damage])
	var counter_ctx := ActionContext.create_attack(ActionSource.COUNTER_ATTACK, enemy_index, "", "physical", 1)
	counter_ctx["final_damage"] = damage
	deal_damage(counter_ctx)
	if counter_stance_charges <= 0:
		counter_attack_multiplier = 1.0


func _check_dodge_streak() -> void:
	dodge_streak += 1


func get_counter(name: String) -> int:
	match name:
		"meticulous_stacks": return meticulous_stacks
		"seek_bloom_stacks": return seek_bloom_stacks
		"ranger_hit_count": return ranger_hit_count
		_: return 0


func set_counter(name: String, value: int) -> void:
	match name:
		"meticulous_stacks": meticulous_stacks = value
		"seek_bloom_stacks": seek_bloom_stacks = value
		"ranger_hit_count": ranger_hit_count = value


func _apply_damage_to_enemy(target_index: int, damage: int, ignore_taunt: bool = false, damage_type: String = "physical") -> void:
	var taunt_target := _active_taunt_target()
	if not ignore_taunt and taunt_target >= 0:
		target_index = taunt_target
	var enemy := enemies[target_index]
	var result := battle_service.deal_damage_to_target(enemy, damage, damage_type, self)
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


func deal_damage(ctx: Dictionary) -> void:
	var source := String(ctx.get("source", ""))
	var target_index := int(ctx.get("target_index", 0))
	var damage := int(ctx.get("final_damage", 0))
	var damage_type := String(ctx.get("damage_type", "physical"))
	var ignore_taunt := not ActionSource.is_interactive(source)
	var source_actor: Dictionary = ctx.get("source_actor", player)

	if not ignore_taunt:
		var taunt_target := _active_taunt_target()
		if taunt_target >= 0:
			target_index = taunt_target
			ctx["target_index"] = target_index

	var target_pool := _opposing_units(source_actor)
	var target := target_pool[target_index]
	var result := battle_service.deal_damage_to_target(target, damage, damage_type, self)
	if bool(result["dodged"]):
		battle_log.append("%s 闪避了这次命中。" % target["name"])
		last_events.append({"kind": "dodge_enemy_attack", "target": "enemy", "target_index": target_index, "amount": 0})
		status_service.fire_trigger(target, TriggerEvents.ON_DODGE, {"battle_log": battle_log, "session": self, "source": source_actor})
		return

	battle_log.append("命中 %s：护甲减免 %d，格挡吸收 %d，造成 %d 点伤害。" % [
		target["name"],
		int(result["armor_reduced"]),
		int(result["block_absorbed"]),
		int(result["damage"])
	])
	last_events.append({"kind": "damage", "target": "enemy", "target_index": target_index, "amount": int(result["damage"])})

	if ActionSource.is_interactive(source):
		var hit_context := {"battle_log": battle_log, "session": self, "source": source_actor, "damage": int(result["damage"]), "target": target}
		status_service.fire_trigger(source_actor, TriggerEvents.ON_HIT_DEALT, hit_context)
		status_service.fire_trigger(target, TriggerEvents.ON_HIT_RECEIVED, hit_context)
		if int(target["hp"]) <= 0:
			status_service.fire_trigger(source_actor, TriggerEvents.ON_KILL, {"battle_log": battle_log, "session": self, "source": source_actor, "target": target})


func _on_victory() -> void:
	run_progress.on_victory(self)


func _on_defeat() -> void:
	run_progress.on_defeat(self)


func _unlock_next_class_skill() -> void:
	simulator._unlock_next_skill(player)


func _unlock_enemies_in_bestiary() -> void:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var bestiary: Dictionary = profile.get("bestiary", {})
	for unit in current_encounter.get("units", []):
		var enemy_id := String(unit.get("id", unit.get("name", "")))
		if enemy_id == "":
			continue
		if not bestiary.has(enemy_id):
			bestiary[enemy_id] = {"defeated_count": 0}
		bestiary[enemy_id]["defeated_count"] = int(bestiary[enemy_id]["defeated_count"]) + 1
	profile["bestiary"] = bestiary
	save_profile.write_profile(profile)


func get_bestiary() -> Dictionary:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	return profile.get("bestiary", {})


func buy_common_skill(skill_id: String) -> bool:
	if tower_coins < 15:
		return false
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	for class_key in roster.keys():
		if roster[class_key].get("unlocked_skills", []).has(skill_id):
			return false
	tower_coins -= 15
	for class_key in roster.keys():
		var class_player: Dictionary = roster[class_key]
		simulator.unlock_skill(class_player, skill_id, class_player["equipped_skills"].size() < 4)
	profile["roster"] = roster
	profile["tower_coins"] = tower_coins
	save_profile.write_profile(profile)
	return true

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


func _can_act() -> bool:
	if phase != "battle":
		return false
	if has_acted:
		message = "本回合已经行动过了。"
		return false
	return true


func _tick_skill_cooldowns() -> void:
	var expired: Array[String] = []
	for skill_id in skill_cooldowns.keys():
		var remaining := int(skill_cooldowns[skill_id]) - 1
		if remaining <= 0:
			expired.append(skill_id)
		else:
			skill_cooldowns[skill_id] = remaining
	for skill_id in expired:
		skill_cooldowns.erase(skill_id)


func _valid_target(target_index: int) -> int:
	return CombatRules.valid_target(enemies, target_index)


func _active_taunt_target() -> int:
	return CombatRules.active_taunt_target(enemies)


func find_enemy_index(enemy: Dictionary) -> int:
	for i in range(enemies.size()):
		if enemies[i] == enemy:
			return i
	return -1


func _enemy_intent(enemy: Dictionary) -> String:
	var player_context := {
		"hp": int(player.get("hp", 0)),
		"max_hp": int(player.get("max_hp", 1)),
		"block": player_block,
		"block_power": int(player.get("block_power", player.get("defense", 1))),
		"dodge_layers": dodge_layers
	}
	return enemy_rules.intent(enemy, round_index, player_context)


func _enemy_choose_skill(enemy: Dictionary) -> String:
	var player_context := {
		"hp": int(player.get("hp", 0)),
		"max_hp": int(player.get("max_hp", 1)),
		"block": player_block,
		"block_power": int(player.get("block_power", player.get("defense", 1))),
		"dodge_layers": dodge_layers
	}
	return enemy_rules.choose_skill(enemy, round_index, player_context)


func enemy_intent_text(index: int) -> String:
	if index < 0 or index >= enemies.size():
		return "未知"
	return enemy_rules.intent_text(enemies[index], round_index)


func _alive_enemy_count() -> int:
	return CombatRules.alive_count(enemies)


func _opposing_units(actor: Dictionary) -> Array[Dictionary]:
	if String(actor.get("side", "")) == "player":
		return enemies
	return _player_side_units()


func _allied_units(actor: Dictionary) -> Array[Dictionary]:
	if String(actor.get("side", "")) == "player":
		return _player_side_units()
	return enemies


func _player_side_units() -> Array[Dictionary]:
	var units: Array[Dictionary] = [_player_combatant()]
	units.append_array(allies)
	return units


func _ai_units() -> Array[Dictionary]:
	var units: Array[Dictionary] = []
	for enemy in enemies:
		units.append(enemy)
	for ally in allies:
		if String(ally.get("controlled_by", "")) == "ai":
			units.append(ally)
	return units


func _opposing_units_alive() -> int:
	return CombatRules.alive_count(_opposing_units(player))


func _has_first_strike() -> bool:
	return enemy_rules.has_first_strike(enemies)


func _state_name(card_id: String) -> String:
	return state_buffs.state_name(card_id)


func _save_data() -> Dictionary:
	return run_state_serializer.save_data(self)


func _roster_player_or_new(selected_class: String) -> Dictionary:
	var saved_player := get_roster_player(selected_class)
	if saved_player.is_empty():
		return simulator.create_character(selected_class)
	if not saved_player.has("side"):
		saved_player["side"] = "player"
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
	return run_state_serializer.load_save_data(self, data)


func _normalize_loaded_enemies() -> void:
	run_state_serializer._normalize_loaded_enemies(enemies)


func _dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	return {}


func _battle_title() -> String:
	var label := "新手引导" if is_tutorial() else "高塔"
	return "%s 第 %d 层 第 %d 场：%s" % [label, floor_index, battle_index, current_encounter.get("name", current_encounter.get("id", "战斗"))]


func is_boss_battle() -> bool:
	return current_encounter.get("type") == "boss"


func toggle_equipped_skill(class_key: String, skill_id: String) -> void:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	if not roster.has(class_key):
		return
	var player_data: Dictionary = roster[class_key]
	var equipped: Array = player_data.get("equipped_skills", [])
	if equipped.has(skill_id):
		equipped.erase(skill_id)
	elif equipped.size() < 4:
		equipped.append(skill_id)
	player_data["equipped_skills"] = equipped
	roster[class_key] = player_data
	profile["roster"] = roster
	save_profile.write_profile(profile)


func swap_equipment(class_key: String, slot: String, item_id: String) -> void:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	if not roster.has(class_key):
		return
	var player_data: Dictionary = roster[class_key]
	var equipment: Dictionary = player_data.get("equipment", {})
	var item: Dictionary = DataCatalog.EQUIPMENT[item_id]
	var item_slot := String(item.get("slot", ""))
	var target_slot := slot
	if item_slot == "ring" and slot == "ring" and equipment.has("ring"):
		target_slot = "ring2"
	var previous := String(equipment.get(target_slot, ""))
	var displaced_slot := ""
	for existing_slot in equipment.keys():
		if String(equipment[existing_slot]) == item_id:
			displaced_slot = existing_slot
			break
	if displaced_slot != "":
		if previous != "":
			equipment[displaced_slot] = previous
		else:
			equipment.erase(displaced_slot)
	else:
		equipment[target_slot] = item_id
	player_data["equipment"] = equipment
	roster[class_key] = player_data
	profile["roster"] = roster
	save_profile.write_profile(profile)


func is_shop_unlocked() -> bool:
	var profile = save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	for class_key in roster.keys():
		if int(roster[class_key].get("highest_floor", 0)) >= 10:
			return true
	return false


func is_skill_owned(skill_id: String) -> bool:
	var profile = save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	for class_key in roster.keys():
		if roster[class_key].get("unlocked_skills", []).has(skill_id):
			return true
	return false
