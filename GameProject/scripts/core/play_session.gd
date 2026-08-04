extends RefCounted
class_name PlaySession

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const EncounterService = preload("res://scripts/core/encounter_service.gd")
const CharacterService = preload("res://scripts/core/character_service.gd")
const RewardService = preload("res://scripts/core/reward_service.gd")
const SaveProfile = preload("res://scripts/core/save_profile.gd")
const BattleService = preload("res://scripts/core/battle_service.gd")
const ChargeService = preload("res://scripts/core/charge_service.gd")
const ConsumableService = preload("res://scripts/core/consumable_service.gd")
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
const BATTLE_LOG_LIMIT := 200

var debug_logger: Variant = null
var debug_mode := false
var encounters := EncounterService.new()
var character := CharacterService.new()
var rewards := RewardService.new()
var save_profile := SaveProfile.new()
var battle_service := BattleService.new()
var charge_service := ChargeService.new()
var consumable_service := ConsumableService.new()
var state_buffs := StateBuffService.new()
var run_progress := RunProgressService.new()
var reward_apply := RewardApplyService.new()
var run_state_serializer := RunStateSerializer.new()
var enemy_rules := EnemyActionRules.new()
var status_service := StatusService.new()
var rng := RandomNumberGenerator.new()

var battle_state := BattleState.new()
var scene_skill_sources: Array[Dictionary] = []

var tower_coins := 0
var npc_unlocks: Array[String] = []
var npc_features: Array[String] = []
var encountered_groups: Array[String] = []
var max_tower_bonus := 0
var cleared_tower_bonuses: Array[int] = []
var tower_seeds := 0
var tower_stash: Array = []
var profile_loaded := false
var pending_tutorial_epilogue := false

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
var tower_bonus: int:
	get:
		return battle_state.tower_bonus
	set(value):
		battle_state.tower_bonus = value
var floor_encounter_count: int:
	get:
		return battle_state.floor_encounter_count
	set(value):
		battle_state.floor_encounter_count = value
var floor_group_id: String:
	get:
		return battle_state.floor_group_id
	set(value):
		battle_state.floor_group_id = value
var encountered_groups_by_floor: Array:
	get:
		return battle_state.encountered_groups_by_floor
	set(value):
		battle_state.encountered_groups_by_floor = value
var tutorial_active: bool:
	get:
		return battle_state.tutorial_active
	set(value):
		battle_state.tutorial_active = value
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
var ai_turn_stage: String:
	get:
		return battle_state.ai_turn_stage
	set(value):
		battle_state.ai_turn_stage = value
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
var counters: Dictionary:
	get:
		return battle_state.counters
	set(value):
		battle_state.counters = value
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
var charge_uses_left: Dictionary:
	get:
		return battle_state.charge_uses_left
	set(value):
		battle_state.charge_uses_left = value
var pending_charge_effects: Dictionary:
	get:
		return battle_state.pending_charge_effects
	set(value):
		battle_state.pending_charge_effects = value

var deferred_damage: float:
	get:
		return battle_state.deferred_damage
	set(value):
		battle_state.deferred_damage = value
var duel_target_index: int:
	get:
		return battle_state.duel_target_index
	set(value):
		battle_state.duel_target_index = value
var perfect_deflect: bool:
	get:
		return battle_state.perfect_deflect
	set(value):
		battle_state.perfect_deflect = value


func _load_account() -> void:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	tower_coins = int(profile.get("tower_coins", 0))
	npc_unlocks = _string_array(profile.get("npc_unlocks", []))
	npc_features = _string_array(profile.get("npc_features", []))
	encountered_groups = _string_array(profile.get("encountered_groups", []))
	max_tower_bonus = clampi(int(profile.get("max_tower_bonus", 0)), 0, DataCatalog.MAX_TOWER_BONUS)
	cleared_tower_bonuses = _int_array(profile.get("cleared_tower_bonuses", []))
	tower_seeds = int(profile.get("tower_seeds", 0))
	tower_stash = (profile.get("tower_stash", []) as Array).duplicate(true)
	var profile_changed := _refresh_npc_unlocks(profile)
	if profile_changed:
		save_profile.write_profile(profile)
	profile_loaded = true


func start_new_game(selected_class: String, selected_tower_bonus: int = 0) -> void:
	selected_class = DataCatalog.normalize_class_id(selected_class)
	class_id = selected_class
	save_profile.set_slot(save_profile.current_slot())
	_load_account()
	rng.randomize()
	player = _roster_player_or_new(selected_class)
	player["tower_consumables"] = tower_stash.duplicate(true)
	tower_stash.clear()
	pending_tutorial_epilogue = false
	floor_group_id = ""
	encountered_groups_by_floor = []
	tower_bonus = clampi(selected_tower_bonus, 0, max_tower_bonus)
	floor_index = 1
	floor_encounter_count = 0
	tutorial_active = not bool(player.get("tutorial_completed", false))
	_ensure_tutorial_starting_equipment()
	character.recalculate_player_stats(player, false)
	battle_index = 1
	phase = "battle"
	message = "开始新手引导。" if tutorial_active else "派遣%s进入高塔。" % DataCatalog.CLASSES[selected_class]["name"]
	_debug_log("start_new_game class=%s floor=%d tutorial=%s" % [selected_class, floor_index, str(is_tutorial())])
	_start_current_battle()


func has_save() -> bool:
	return save_profile.has_save()


func has_any_save() -> bool:
	return save_profile.has_save()


func select_save_slot(slot_index: int) -> void:
	save_profile.set_slot(slot_index)


func save_slot_summaries() -> Array[Dictionary]:
	return save_profile.list_slot_profiles(Callable(self, "_persistent_player_snapshot"))


func has_active_run() -> bool:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	return not _dictionary(profile.get("active_run", {})).is_empty()


func get_roster_player(selected_class: String) -> Dictionary:
	var requested_class_id := selected_class
	selected_class = DataCatalog.normalize_class_id(selected_class)
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster := _dictionary(profile.get("roster", {}))
	var player := _dictionary(roster.get(selected_class, {}))
	if player.is_empty() and requested_class_id != selected_class:
		player = _dictionary(roster.get(requested_class_id, {}))
	if not player.is_empty():
		player["class_id"] = selected_class
		character.recalculate_player_stats(player, false)
	return player


func save_game() -> bool:
	if phase == "menu" or phase == "tutorial_epilogue" or player.is_empty():
		return false
	_trim_battle_log()
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster := _dictionary(profile.get("roster", {}))
	roster[class_id] = _persistent_player_snapshot(player)
	profile["version"] = 2
	profile["roster"] = roster
	profile["tower_coins"] = tower_coins
	_sync_profile_progress(profile)
	if phase == "game_over" or phase == "victory":
		var current_highest := int(player.get("highest_floor", 0))
		if floor_index > current_highest:
			player["highest_floor"] = floor_index
		profile["active_run"] = {}
	else:
		profile["active_run"] = _save_data()
	var ok := save_profile.write_profile(profile)
	_debug_log("save_game ok=%s phase=%s floor=%d battle=%d" % [str(ok), phase, floor_index, battle_index])
	return ok


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
	_sync_profile_progress(profile)
	profile["active_run"] = {}
	if not save_profile.write_profile(profile):
		return false
	profile_loaded = true
	pending_tutorial_epilogue = false
	_reset_to_camp_state()
	_debug_log("end_run_to_camp floor=%d battle=%d" % [floor_index, battle_index])
	return true


func load_game(slot_index: int = -1) -> bool:
	if slot_index >= 1:
		select_save_slot(slot_index)
	if not save_profile.has_save(save_profile.current_slot()):
		return false
	rng.randomize()
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var active_run := _dictionary(profile.get("active_run", {}))
	profile_loaded = not profile.is_empty()
	npc_unlocks = _string_array(profile.get("npc_unlocks", []))
	npc_features = _string_array(profile.get("npc_features", []))
	encountered_groups = _string_array(profile.get("encountered_groups", []))
	max_tower_bonus = clampi(int(profile.get("max_tower_bonus", 0)), 0, DataCatalog.MAX_TOWER_BONUS)
	cleared_tower_bonuses = _int_array(profile.get("cleared_tower_bonuses", []))
	tower_seeds = int(profile.get("tower_seeds", 0))
	tower_stash = (profile.get("tower_stash", []) as Array).duplicate(true)
	pending_tutorial_epilogue = false
	if active_run.is_empty():
		battle_state.reset()
		tower_coins = int(profile.get("tower_coins", 0))
		message = "已返回塔下营地。"
		phase = "menu"
		return profile_loaded
	_debug_log("load_game active_run floor=%d battle=%d" % [int(active_run.get("floor_index", 0)), int(active_run.get("battle_index", 0))])
	return _load_save_data(active_run)


func delete_save() -> void:
	save_profile.delete_save()
	npc_unlocks.clear()
	npc_features.clear()
	encountered_groups.clear()
	encountered_groups_by_floor = []
	cleared_tower_bonuses.clear()
	max_tower_bonus = 0
	tower_seeds = 0
	tower_stash.clear()
	profile_loaded = false
	pending_tutorial_epilogue = false


func _reset_to_camp_state() -> void:
	battle_state.reset()


func is_tutorial() -> bool:
	return tutorial_active


func _start_current_battle() -> void:
	last_events.clear()
	_ensure_floor_group_id()
	current_encounter = _get_current_encounter()
	if not is_tutorial():
		_record_group_encounter(String(current_encounter.get("group_id", floor_group_id)))
	enemies = _build_enemies(current_encounter)
	allies = []
	scene_skill_sources = CombatRules.collect_scene_skill_sources(enemies + allies)
	has_acted = false
	skill_cooldowns = {}
	player_block = 0
	dodge_layers = 0
	round_index = 0
	ai_turn_stage = "after_player_pending"
	pending_state_card = ""
	battle_attack_multiplier = 1.0
	player["statuses"] = []
	enemy_attack_multiplier = 1.0
	counter_stance_charges = 0
	counter_attack_multiplier = 1.0
	dodge_streak = 0
	counters = {}
	attacked_this_turn = false
	charge_used = {}
	charge_ready = {}
	charge_uses_left = {}
	pending_charge_effects = _empty_charge_effects()
	deferred_damage = 0.0
	duel_target_index = -1
	perfect_deflect = false
	battle_log.clear()
	phase = "battle"
	message = _battle_title()
	_debug_log("battle_start %s floor=%d battle=%d enemies=%d" % [String(current_encounter.get("name", current_encounter.get("id", "战斗"))), floor_index, battle_index, enemies.size()])
	_fire_battle_start_triggers()
	if _has_first_strike():
		_enemy_attack(enemies[0], 0, true)
	_begin_player_turn()


func _get_current_encounter() -> Dictionary:
	if is_tutorial():
		return DataCatalog.TUTORIAL_ENCOUNTERS[battle_index - 1]
	return encounters.generate_encounter(floor_index, battle_index, floor_group_id)


func _ensure_floor_group_id() -> void:
	if is_tutorial():
		floor_group_id = ""
		return
	if floor_group_id != "":
		return
	floor_group_id = encounters.select_floor_group_id(rng)


func _build_enemies(encounter: Dictionary) -> Array[Dictionary]:
	return CombatRules.build_enemies(encounter, floor_index, true, tower_bonus)


func effective_tower_level() -> int:
	return floor_index + tower_bonus

func _begin_player_turn() -> void:
	round_index += 1
	has_acted = false
	perfect_deflect = false
	ai_turn_stage = "after_player_pending"
	_tick_skill_cooldowns()
	player_block = 0
	pending_state_card = _draw_state_buff()
	var corruption_damage := CombatRules.resolve_corruption(player)
	if corruption_damage > 0:
		battle_log.append("腐败结算：受到 %d 点真实伤害。" % corruption_damage)
	if int(player["hp"]) <= 0:
		_on_defeat()
		return
	status_service.tick_statuses(player)
	_process_tick_effects(player)
	status_service.fire_trigger(player, TriggerEvents.ON_TURN_START, {"battle_log": battle_log, "session": self, "not_attacked_last_turn": not attacked_this_turn})
	for enemy in enemies:
		if int(enemy["hp"]) <= 0:
			continue
		CombatRules.tick_enemy_cooldowns(enemy)
		status_service.tick_statuses(enemy)
		_process_tick_effects(enemy)
		status_service.fire_trigger(enemy, TriggerEvents.ON_TURN_START, {"battle_log": battle_log, "session": self, "round_index": round_index})
	for ally in allies:
		if int(ally["hp"]) <= 0 or String(ally.get("controlled_by", "")) != "ai":
			continue
		status_service.tick_statuses(ally)
		_process_tick_effects(ally)
		status_service.fire_trigger(ally, TriggerEvents.ON_TURN_START, {"battle_log": battle_log, "session": self, "round_index": round_index})
	attacked_this_turn = false
	var action_order := CombatRules.action_order(player, enemies, allies, status_service, round_index)
	var player_position := -1
	for index in range(action_order.size()):
		if String(action_order[index].get("type", "")) == "player":
			player_position = index
			break
	if player_position > 0:
		# 敏捷较高的敌方单位先行动；之后仍保留玩家的一次手动行动。
		_enemy_turn(true)
		if int(player["hp"]) <= 0:
			_on_defeat()
			return
	var charged_label := _random_ready_charge()
	message = "你的回合。状态 Buff：%s" % _state_name(pending_state_card)
	if charged_label != "":
		message += " 随机充能：%s。" % charged_label
	var player_hint := String(current_encounter.get("player_hint", ""))
	if player_hint != "":
		message += " " + player_hint
	_debug_log("turn_start round=%d energy=%d hp=%d/%d block=%d action_order=%s" % [round_index, energy, int(player.get("hp", 0)), int(player.get("max_hp", player.get("base_max_hp", 0))), player_block, _action_order_debug_text(action_order)])


func _draw_state_buff() -> String:
	if is_tutorial():
		var tutorial_cards := ["critical", "perfect_guard", "read"]
		return String(tutorial_cards[clampi(battle_index - 1, 0, tutorial_cards.size() - 1)])
	return state_buffs.draw_state_buff(self)


func _action_order_debug_text(action_order: Array[Dictionary]) -> String:
	var labels: Array[String] = []
	for entry in action_order:
		var actor_type := String(entry.get("type", ""))
		var unit: Dictionary = entry.get("unit", {})
		labels.append("%s:%s" % [actor_type, String(unit.get("name", actor_type))])
	return ",".join(labels)


func _fire_battle_start_triggers() -> void:
	status_service.fire_trigger(player, TriggerEvents.ON_BATTLE_START, {"battle_log": battle_log, "session": self})
	for enemy in enemies:
		if int(enemy.get("hp", 0)) > 0:
			status_service.fire_trigger(enemy, TriggerEvents.ON_BATTLE_START, {"battle_log": battle_log, "session": self})
	for ally in allies:
		if int(ally.get("hp", 0)) > 0:
			status_service.fire_trigger(ally, TriggerEvents.ON_BATTLE_START, {"battle_log": battle_log, "session": self})


func player_attack(target_index: int) -> void:
	attacked_this_turn = true
	_debug_log("player_attack target=%d energy=%d" % [target_index, energy])
	battle_service.player_attack(self, target_index)


func player_defend() -> void:
	_debug_log("player_defend energy=%d" % energy)
	battle_service.player_defend(self)


func player_dodge() -> void:
	_debug_log("player_dodge energy=%d" % energy)
	battle_service.player_dodge(self)


func use_blood_potion_in_battle() -> void:
	_debug_log("use_blood_potion hp=%d/%d" % [int(player.get("hp", 0)), int(player.get("max_hp", 0))])
	battle_service.use_blood_potion(self)


func use_skill(slot_index: int, target_index: int) -> void:
	attacked_this_turn = true
	_debug_log("use_skill slot=%d target=%d energy=%d" % [slot_index, target_index, energy])
	battle_service.use_skill(self, slot_index, target_index)


func end_turn() -> void:
	_debug_log("end_turn round=%d energy=%d" % [round_index, energy])
	battle_service.end_turn(self)


func choose_reward(index: int) -> void:
	_debug_log("choose_reward index=%d" % index)
	reward_apply.choose_reward(self, index)


func choose_reward_target(index: int) -> void:
	_debug_log("choose_reward_target index=%d" % index)
	reward_apply.choose_reward_target(self, index)


func _after_player_action() -> void:
	if _opposing_units_alive() == 0:
		_on_victory()


func _player_combatant() -> Dictionary:
	return Combatant.from_player(player, player_block, dodge_layers, status_service)


func _current_attack_value(action_source: String = "") -> int:
	return CombatRules.current_attack_value(self, action_source)


func _defense_value() -> int:
	return CombatRules.defense_value(self)


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


func _enemy_turn(before_player: bool = false) -> void:
	battle_service.enemy_turn(self, before_player)


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
	battle_log.append("反击架势触发，对 %s 反击 %d 点。" % [enemies[enemy_index]["name"], damage])
	var counter_ctx := ActionContext.create_attack(ActionSource.COUNTER_ATTACK, enemy_index, "", "physical", 1)
	counter_ctx["final_damage"] = damage
	deal_damage(counter_ctx)
	if counter_stance_charges <= 0:
		counter_attack_multiplier = 1.0


func _trigger_reflect_damage(enemy_index: int) -> void:
	if enemy_index < 0 or enemy_index >= enemies.size():
		return
	if int(enemies[enemy_index]["hp"]) <= 0:
		return
	var reflect_mult := 0.0
	for status in player.get("statuses", []):
		reflect_mult = maxf(reflect_mult, float(status.get("reflect_multiplier", 0.0)))
	if reflect_mult <= 0.0:
		return
	var reflect_damage := maxi(1, int(round(float(_current_attack_value(ActionSource.COUNTER_ATTACK)) * reflect_mult)))
	battle_log.append("钢铁姿态：反弹 %d 点伤害给 %s。" % [reflect_damage, enemies[enemy_index]["name"]])
	var reflect_ctx := ActionContext.create_attack(ActionSource.COUNTER_ATTACK, enemy_index, "", "physical", 1)
	reflect_ctx["final_damage"] = reflect_damage
	deal_damage(reflect_ctx)


func _check_dodge_streak() -> void:
	dodge_streak += 1


func get_counter(name: String) -> int:
	if name == "":
		return 0
	return maxi(0, int(counters.get(name, 0)))


func set_counter(name: String, value: int) -> void:
	if name == "":
		return
	counters[name] = maxi(0, value)

func _apply_damage_to_enemy(target_index: int, damage: int, ignore_taunt: bool = false, damage_type: String = "physical") -> void:
	var taunt_target := _active_taunt_target()
	if not ignore_taunt and taunt_target >= 0:
		target_index = taunt_target
	var enemy := enemies[target_index]
	var result := battle_service.deal_damage_to_target(enemy, damage, damage_type, self, player)
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
		if duel_target_index == target_index:
			duel_target_index = -1
			battle_log.append("单挑领域：决斗目标已死亡，单挑结束。")


func deal_damage(ctx: Dictionary) -> void:
	battle_service.deal_damage(self, ctx)


func _on_victory() -> void:
	_debug_log("victory floor=%d battle=%d" % [floor_index, battle_index])
	run_progress.on_victory(self)


func _on_defeat() -> void:
	_debug_log("defeat floor=%d battle=%d" % [floor_index, battle_index])
	run_progress.on_defeat(self)


func _unlock_next_class_skill() -> void:
	character.unlock_next_skill(player)


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


func _tower_coin_reward() -> int:
	var rank := String(current_encounter.get("type", "normal"))
	var multiplier := int(DataCatalog.TOWER_COIN_MULTIPLIERS.get(rank, 0))
	var defeated_units := maxi(1, current_encounter.get("units", []).size())
	return multiplier * effective_tower_level() * defeated_units


func _unlock_boss_npc(boss_floor: int) -> void:
	for npc_id in DataCatalog.NPCS.keys():
		var npc: Dictionary = DataCatalog.NPCS[npc_id]
		if int(npc.get("unlock_boss_floor", 0)) != boss_floor or npc_unlocks.has(String(npc_id)):
			continue
		npc_unlocks.append(String(npc_id))
		_sync_profile_now()


func _record_tower_completion() -> void:
	if cleared_tower_bonuses.has(tower_bonus):
		return
	cleared_tower_bonuses.append(tower_bonus)
	tower_seeds += 1
	max_tower_bonus = maxi(max_tower_bonus, mini(DataCatalog.MAX_TOWER_BONUS, tower_bonus + 1))
	player["blood_potion_seed"] = int(player.get("blood_potion_seed", 0)) + 1
	player["blood_potion_uses"] = int(player.get("blood_potion_uses", 0)) + 1
	if int(player.get("passive_skill_slots", 0)) <= 0:
		player["passive_skill_slots"] = 1
		character.unlock_passive_skill(player, "iron_will", true)
	_sync_profile_now()


func _record_group_encounter(group_id: String) -> void:
	if group_id == "" or floor_index <= 0:
		return
	_ensure_encountered_groups_by_floor()
	var current_floor_groups: Array = encountered_groups_by_floor[floor_index - 1]
	current_floor_groups.append(group_id)
	encountered_groups_by_floor[floor_index - 1] = current_floor_groups
	floor_encounter_count = current_floor_groups.size()
	if not encountered_groups.has(group_id):
		encountered_groups.append(group_id)
	_unlock_npc_upgrades_for_current_floor(current_floor_groups.size())
	_sync_profile_now()


func _ensure_encountered_groups_by_floor() -> void:
	while encountered_groups_by_floor.size() < floor_index:
		encountered_groups_by_floor.append([])


func _current_floor_group_count() -> int:
	if floor_index <= 0 or encountered_groups_by_floor.size() < floor_index:
		return 0
	return (encountered_groups_by_floor[floor_index - 1] as Array).size()


func _restore_legacy_group_history(legacy_count: int) -> void:
	if legacy_count <= 0 or floor_group_id == "" or floor_index <= 0:
		return
	_ensure_encountered_groups_by_floor()
	var current_floor_groups: Array = encountered_groups_by_floor[floor_index - 1]
	if not current_floor_groups.is_empty():
		return
	var remaining_count := legacy_count
	while remaining_count > 0:
		current_floor_groups.append(floor_group_id)
		remaining_count -= 1
	encountered_groups_by_floor[floor_index - 1] = current_floor_groups
	floor_encounter_count = current_floor_groups.size()
	_unlock_npc_upgrades_for_current_floor(current_floor_groups.size())


func _unlock_npc_upgrades_for_current_floor(group_count: int) -> void:
	for npc_id in DataCatalog.NPCS.keys():
		var npc: Dictionary = DataCatalog.NPCS[npc_id]
		if int(npc.get("upgrade_floor", 0)) != floor_index:
			continue
		var required_groups := int(npc.get("upgrade_groups", 0))
		if required_groups <= 0 or group_count < required_groups:
			continue
		var feature_id := String(npc.get("upgrade_feature", "%s_upgraded" % String(npc_id)))
		_unlock_npc_feature(feature_id)


func get_bestiary() -> Dictionary:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	return profile.get("bestiary", {})


func get_npc_unlocks() -> Array[String]:
	return npc_unlocks.duplicate()


func get_max_tower_bonus() -> int:
	return max_tower_bonus


func is_npc_unlocked(npc_id: String) -> bool:
	if not DataCatalog.NPCS.has(npc_id):
		return false
	return npc_unlocks.has(npc_id)


func is_npc_feature_unlocked(feature_id: String) -> bool:
	return npc_features.has(feature_id)


func use_blood_potion(class_key: String = "") -> bool:
	if phase == "battle":
		return battle_service.use_blood_potion(self)
	if phase != "menu":
		return false
	var target_class := DataCatalog.normalize_class_id(class_key)
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	var roster_player: Dictionary = _dictionary(roster.get(target_class, {}))
	if roster_player.is_empty():
		return false
	var result := character.use_blood_potion(roster_player)
	if not bool(result.get("used", false)):
		message = "血瓶无法使用。"
		return false
	roster[target_class] = _persistent_player_snapshot(roster_player)
	profile["roster"] = roster
	if not save_profile.write_profile(profile):
		return false
	message = "血瓶恢复 %d 点生命，剩余 %d 次。" % [int(result["amount"]), int(result["uses_left"])]
	return true


func buy_common_skill(skill_id: String) -> bool:
	if not is_npc_unlocked("mage"):
		return false
	if tower_coins < DataCatalog.PERMANENT_SKILL_PRICE:
		return false
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	for class_key in roster.keys():
		if roster[class_key].get("unlocked_skills", []).has(skill_id):
			return false
	tower_coins -= DataCatalog.PERMANENT_SKILL_PRICE
	for class_key in roster.keys():
		var class_player: Dictionary = roster[class_key]
		character.unlock_skill(class_player, skill_id, _roster_has_empty_skill_slot(class_player))
	profile["roster"] = roster
	profile["tower_coins"] = tower_coins
	save_profile.write_profile(profile)
	return true


func buy_permanent_equipment(class_key: String, item_id: String) -> bool:
	if not is_npc_unlocked("blacksmith") or tower_coins < DataCatalog.PERMANENT_EQUIPMENT_PRICE:
		return false
	if not DataCatalog.EQUIPMENT.has(item_id):
		return false
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	var normalized_class := DataCatalog.normalize_class_id(class_key)
	var class_player: Dictionary = _dictionary(roster.get(normalized_class, {}))
	if class_player.is_empty() or class_player.get("equipment_ids", []).has(item_id):
		return false
	tower_coins -= DataCatalog.PERMANENT_EQUIPMENT_PRICE
	class_player["equipment_ids"].append(item_id)
	roster[normalized_class] = class_player
	profile["roster"] = roster
	profile["tower_coins"] = tower_coins
	save_profile.write_profile(profile)
	return true


func upgrade_equipment(class_key: String, item_id: String, kind: String = "attack", value: float = 1.0) -> bool:
	if not is_npc_feature_unlocked("blacksmith_upgraded") or tower_coins < DataCatalog.PERMANENT_EQUIPMENT_PRICE:
		return false
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	var normalized_class := DataCatalog.normalize_class_id(class_key)
	var class_player: Dictionary = _dictionary(roster.get(normalized_class, {}))
	if class_player.is_empty() or not class_player.get("equipment_ids", []).has(item_id):
		return false
	tower_coins -= DataCatalog.PERMANENT_EQUIPMENT_PRICE
	character.apply_permanent_upgrade(class_player, "equipment", item_id, kind, value)
	roster[normalized_class] = _persistent_player_snapshot(class_player)
	profile["roster"] = roster
	profile["tower_coins"] = tower_coins
	save_profile.write_profile(profile)
	return true


func upgrade_skill(class_key: String, skill_id: String, kind: String = "skill_power", value: float = 0.05) -> bool:
	if not is_npc_feature_unlocked("mage_upgraded") or tower_coins < DataCatalog.PERMANENT_SKILL_PRICE:
		return false
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	var normalized_class := DataCatalog.normalize_class_id(class_key)
	var class_player: Dictionary = _dictionary(roster.get(normalized_class, {}))
	if class_player.is_empty() or not class_player.get("unlocked_skills", []).has(skill_id):
		return false
	tower_coins -= DataCatalog.PERMANENT_SKILL_PRICE
	character.apply_permanent_upgrade(class_player, "skill", skill_id, kind, value)
	roster[normalized_class] = _persistent_player_snapshot(class_player)
	profile["roster"] = roster
	profile["tower_coins"] = tower_coins
	save_profile.write_profile(profile)
	return true


func buy_tower_consumable(item_id: String, upgraded: bool = false) -> bool:
	var price := 8 if upgraded else 5
	if not is_npc_unlocked("merchant") or phase not in ["battle", "reward", "npc_shop"] or tower_coins < price:
		return false
	if not DataCatalog.CONSUMABLES.has(item_id):
		return false
	tower_coins -= price
	if phase == "npc_shop":
		tower_stash.append({"id": item_id, "upgraded": upgraded})
	else:
		character.add_tower_consumable(player, item_id, upgraded)
	_sync_profile_now()
	return true

func _roster_has_empty_skill_slot(class_player: Dictionary) -> bool:
	for skill_id in class_player.get("equipped_skills", []):
		if String(skill_id) == "":
			return true
	return class_player.get("equipped_skills", []).size() < 4


func _build_reward_options() -> void:
	reward_apply.build_reward_options(self)


func _random_reward_options(reward_rank: String, count: int) -> Array[Dictionary]:
	return rewards.random_options(reward_rank, count, floor_index)


func _reward_pool(reward_rank: String) -> Array[Dictionary]:
	return rewards.reward_pool(reward_rank, floor_index)


func _sample_rewards(pool: Array[Dictionary], count: int) -> Array[Dictionary]:
	return rewards.sample_rewards(pool, count)


func _sample_rewards_with_core(pool: Array[Dictionary], count: int) -> Array[Dictionary]:
	return rewards.sample_rewards_with_core(pool, count)


func _is_core_growth_reward(reward: Dictionary) -> bool:
	return RewardService.is_core_growth_reward(reward)


func _debug_log(message: String) -> void:
	if debug_mode and debug_logger != null and debug_logger.has_method("log"):
		debug_logger.log(message)


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
	if target_type == "consumable" and DataCatalog.CONSUMABLES.has(target_id):
		var consumable: Dictionary = DataCatalog.CONSUMABLES[target_id]
		return "消耗品：%s" % consumable["name"]
	return target_id


func _skill_attachment_bonus(skill_id: String, kind: String) -> int:
	return character.skill_attachment_bonus(player, skill_id, kind)


func _skill_multiplier_bonus(skill_id: String, kind: String = "") -> float:
	return character.skill_multiplier_bonus(player, skill_id, kind)


func available_charges() -> Array[Dictionary]:
	return charge_service.available_charges(self)


func available_consumables() -> Array[Dictionary]:
	return consumable_service.available_consumables(self)


func use_consumable(reference: Variant) -> bool:
	return consumable_service.use_consumable(self, reference)


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
	var cd_reduction := int(status_service.resolve_stat(player, 0.0, StatusService.STAT_COOLDOWN))
	var expired: Array[String] = []
	for skill_id in skill_cooldowns.keys():
		var remaining := int(skill_cooldowns[skill_id]) - 1 - cd_reduction
		if remaining <= 0:
			expired.append(skill_id)
		else:
			skill_cooldowns[skill_id] = remaining
	for skill_id in expired:
		skill_cooldowns.erase(skill_id)


func _process_tick_effects(target: Dictionary) -> void:
	if not target.has("statuses"):
		return
	for status in target.get("statuses", []):
		for tick in status.get("tick_effects", []):
			var tick_stat := String(tick.get("stat", "hp"))
			var tick_type := String(tick.get("type", "percent"))
			var tick_value := float(tick.get("value", 0.0))
			if tick_stat == "hp":
				if tick_type == "percent":
					var amount := maxi(1, int(round(float(target["max_hp"]) * abs(tick_value))))
					if tick_value > 0.0:
						amount = maxi(1, int(ceil(status_service.resolve_stat(target, float(amount), StatusService.STAT_HEAL))))
						target["hp"] = mini(int(target["max_hp"]), int(target["hp"]) + amount)
						battle_log.append("%s：每回合恢复 %d 点 HP。" % [String(status.get("name", "")), amount])
					elif tick_value < 0.0:
						target["hp"] = maxi(1, int(target["hp"]) - amount)
						battle_log.append("%s：每回合失去 %d 点 HP。" % [String(status.get("name", "")), amount])
				elif tick_type == "flat":
					if tick_value > 0.0:
						var resolved_tick: int = maxi(1, int(ceil(status_service.resolve_stat(target, abs(tick_value), StatusService.STAT_HEAL))))
						target["hp"] = mini(int(target["max_hp"]), int(target["hp"]) + resolved_tick)
					elif tick_value < 0.0:
						target["hp"] = maxi(1, int(target["hp"]) + int(tick_value))
			elif tick_stat == "energy" and tick_type == "flat":
				energy = mini(DataCatalog.ENERGY_MAX, energy + int(tick_value))
	# 延迟伤害结算
	if target == player and deferred_damage > 0.0:
		var deferred_tick := maxi(1, int(round(deferred_damage / 3.0)))
		deferred_tick = mini(deferred_tick, int(deferred_damage))
		deferred_damage -= float(deferred_tick)
		target["hp"] = maxi(1, int(target["hp"]) - deferred_tick)
		battle_log.append("延迟伤害结算：受到 %d 点延迟伤害。" % deferred_tick)


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
	return enemy_rules.intent(enemy, round_index, player_context, _is_enemy_alone())


func _enemy_choose_skill(enemy: Dictionary) -> String:
	var player_context := {
		"hp": int(player.get("hp", 0)),
		"max_hp": int(player.get("max_hp", 1)),
		"block": player_block,
		"block_power": int(player.get("block_power", player.get("defense", 1))),
		"dodge_layers": dodge_layers
	}
	return enemy_rules.choose_skill(enemy, round_index, player_context, _is_enemy_alone(), rng)


func _is_enemy_alone() -> bool:
	var alive_ai := 0
	for e in enemies:
		if int(e.get("hp", 0)) > 0:
			alive_ai += 1
	for a in allies:
		if int(a.get("hp", 0)) > 0 and String(a.get("controlled_by", "")) == "ai":
			alive_ai += 1
	return alive_ai <= 1


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
	_trim_battle_log()
	return run_state_serializer.save_data(self)


func _trim_battle_log() -> void:
	var overflow := battle_log.size() - BATTLE_LOG_LIMIT
	if overflow <= 0:
		return
	var trimmed: Array[String] = []
	for i in range(overflow, battle_log.size()):
		trimmed.append(battle_log[i])
	battle_log = trimmed


func _roster_player_or_new(selected_class: String) -> Dictionary:
	selected_class = DataCatalog.normalize_class_id(selected_class)
	var saved_player := get_roster_player(selected_class)
	if saved_player.is_empty():
		return character.create_character(selected_class)
	if saved_player.get("equipment", {}).get("weapon", "") == "" and not bool(saved_player.get("tutorial_completed", false)):
		character.equip_tower_item(saved_player, "warrior_training_sword")
	if not saved_player.has("tower_equipment") and not bool(saved_player.get("tutorial_completed", false)):
		saved_player["tower_equipment"] = {}
	if not saved_player.has("side"):
		saved_player["side"] = "player"
		character.recalculate_player_stats(saved_player, true)
	return saved_player


func _ensure_tutorial_starting_equipment() -> void:
	if not is_tutorial():
		return
	var item_id := String(DataCatalog.TUTORIAL_STARTING_EQUIPMENT.get(class_id, ""))
	if item_id == "" or not DataCatalog.EQUIPMENT.has(item_id):
		return
	var tower_equipment: Dictionary = player.get("tower_equipment", {})
	if String(tower_equipment.get("weapon", "")) == "":
		character.equip_tower_item(player, item_id)


func _persistent_player_snapshot(source_player: Dictionary) -> Dictionary:
	var snapshot := source_player.duplicate(true)
	snapshot["equipment_attachments"] = {}
	snapshot["skill_attachments"] = {}
	snapshot["tower_equipment"] = {}
	snapshot["tower_equipment_ids"] = []
	snapshot["tower_consumables"] = []
	snapshot["tower_equipped_skills"] = ["", "", "", ""]
	snapshot["tower_passive_skills"] = []
	snapshot["state_attack_bonus"] = 0
	snapshot["state_defense_bonus"] = 0
	snapshot["statuses"] = []
	snapshot["normal_rewards"] = int(snapshot.get("normal_rewards", 0))
	snapshot["elite_rewards"] = int(snapshot.get("elite_rewards", 0))
	snapshot["boss_rewards"] = int(snapshot.get("boss_rewards", 0))
	character.recalculate_player_stats(snapshot, true)
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
	if is_tutorial():
		return "新手引导 第 %d 场：%s" % [battle_index, current_encounter.get("name", current_encounter.get("id", "战斗"))]
	return "+%d塔 高塔 第 %d 层 第 %d 场：%s" % [tower_bonus, floor_index, battle_index, current_encounter.get("name", current_encounter.get("id", "战斗"))]


func is_boss_battle() -> bool:
	return current_encounter.get("type") == "boss"


func set_skill_slot(class_key: String, slot: int, skill_id: String) -> void:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	if not roster.has(class_key):
		return
	var player_data: Dictionary = roster[class_key]
	var equipped: Array = player_data.get("equipped_skills", [])
	while equipped.size() < 4:
		equipped.append("")
	var idx := slot - 1
	if idx < 0 or idx >= 4:
		return
	if skill_id != "" and not player_data.get("unlocked_skills", []).has(skill_id):
		return
	if String(equipped[idx]) == skill_id:
		equipped[idx] = ""
	else:
		equipped[idx] = skill_id
	player_data["equipped_skills"] = equipped
	roster[class_key] = player_data
	profile["roster"] = roster
	save_profile.write_profile(profile)


func set_consumable_slot(class_key: String, slot: int, item_id: String) -> void:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	if not roster.has(class_key):
		return
	var player_data: Dictionary = roster[class_key]
	var equipped: Array = player_data.get("consumables", [])
	while equipped.size() < DataCatalog.NORMAL_CONSUMABLE_SLOTS:
		equipped.append("")
	if equipped.size() > DataCatalog.NORMAL_CONSUMABLE_SLOTS:
		equipped.resize(DataCatalog.NORMAL_CONSUMABLE_SLOTS)
	var idx := slot - 1
	if idx < 0 or idx >= DataCatalog.NORMAL_CONSUMABLE_SLOTS:
		return
	if String(equipped[idx]) == item_id:
		equipped[idx] = ""
	else:
		var displaced_slot := -1
		for i in range(equipped.size()):
			if String(equipped[i]) == item_id:
				displaced_slot = i
				break
		if displaced_slot >= 0:
			equipped[displaced_slot] = String(equipped[idx])
		equipped[idx] = item_id
	player_data["consumables"] = equipped
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
		target_slot = "accessory"
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
	return is_npc_unlocked("merchant")


func is_skill_owned(skill_id: String) -> bool:
	var profile = save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	var roster: Dictionary = profile.get("roster", {})
	for class_key in roster.keys():
		if roster[class_key].get("unlocked_skills", []).has(skill_id):
			return true
	return false


func _refresh_npc_unlocks(profile: Dictionary) -> bool:
	var changed := false
	var stored_unlocks: Array = profile.get("npc_unlocks", []).duplicate()
	for npc_id in stored_unlocks:
		if not npc_unlocks.has(String(npc_id)):
			npc_unlocks.append(String(npc_id))
			changed = true
	var stored_features: Array = profile.get("npc_features", []).duplicate()
	for feature_id in stored_features:
		if not npc_features.has(String(feature_id)):
			npc_features.append(String(feature_id))
			changed = true
	return changed


func _unlock_npc_feature(feature_id: String) -> void:
	if not npc_features.has(feature_id):
		npc_features.append(feature_id)


func _sync_profile_progress(profile: Dictionary) -> void:
	profile["tower_coins"] = tower_coins
	profile["npc_unlocks"] = npc_unlocks.duplicate()
	profile["npc_features"] = npc_features.duplicate()
	profile["encountered_groups"] = encountered_groups.duplicate()
	profile["max_tower_bonus"] = max_tower_bonus
	profile["cleared_tower_bonuses"] = cleared_tower_bonuses.duplicate()
	profile["tower_seeds"] = tower_seeds
	profile["tower_stash"] = tower_stash.duplicate(true)
	if class_id != "" and not player.is_empty():
		var roster: Dictionary = profile.get("roster", {})
		roster[class_id] = _persistent_player_snapshot(player)
		profile["roster"] = roster


func _sync_profile_now() -> void:
	var profile := save_profile.read_profile(Callable(self, "_persistent_player_snapshot"))
	_sync_profile_progress(profile)
	save_profile.write_profile(profile)


func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		var item_id := String(item)
		if item_id != "":
			result.append(item_id)
	return result


func _int_array(value: Variant) -> Array[int]:
	var result: Array[int] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		result.append(int(item))
	return result
