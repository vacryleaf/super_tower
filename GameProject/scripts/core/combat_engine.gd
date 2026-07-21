extends RefCounted
class_name CombatEngine

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const EnemyActionRules = preload("res://scripts/core/enemy_action_rules.gd")
const ModifierPipeline = preload("res://scripts/core/modifier_pipeline.gd")
const CombatRules = preload("res://scripts/core/combat_rules.gd")
const ChargeSimulator = preload("res://scripts/core/charge_simulator.gd")
const ChargeService = preload("res://scripts/core/charge_service.gd")
const CharacterService = preload("res://scripts/core/character_service.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const TriggerEvents = preload("res://scripts/core/trigger_events.gd")
const SkillActionService = preload("res://scripts/core/skill_action_service.gd")
const SetEffectService = preload("res://scripts/core/set_effect_service.gd")
const ActionSource = preload("res://scripts/core/action_source.gd")

const MAX_ROUNDS := 40

var enemy_rules := EnemyActionRules.new()
var charge_sim := ChargeSimulator.new()
var char_service := CharacterService.new()
var status_service := StatusService.new()
var set_effect_service := SetEffectService.new()
var player: Dictionary = {}
var active_enemies: Array[Dictionary] = []
var active_log: Array[String] = []
var sim_counters: Dictionary = {}
var battle_attack_multiplier := 1.0
var enemy_attack_multiplier := 1.0
var pending_state_card := ""
var focus_combo_multiplier := 1.0
var meticulous_stacks := 0
var seek_bloom_stacks := 0
var ranger_hit_count := 0
var dodge_streak := 0
var duel_target_index := -1
var perfect_deflect := false
var deferred_damage := 0.0


func run_battle(player: Dictionary, encounter: Dictionary, tower_floor: int, battle_index: int, allies: Array[Dictionary] = []) -> Dictionary:
	var enemies := _build_enemies(encounter, tower_floor)
	var log: Array[String] = []
	var rounds := 0
	var player_block := 0
	var energy := int(player.get("energy", 0))
	var skill_cooldowns: Dictionary = player.get("skill_cooldowns", {}).duplicate()
	var first_strike_done := false
	var charge_state := charge_sim.build_charge_state(player)
	var counter_state := {"charges": 0, "multiplier": 1.0}
	self.player = player
	active_enemies = enemies
	active_log = log
	sim_counters = {}
	battle_attack_multiplier = 1.0
	enemy_attack_multiplier = 1.0
	pending_state_card = ""
	focus_combo_multiplier = 1.0
	meticulous_stacks = 0
	seek_bloom_stacks = 0
	ranger_hit_count = 0
	dodge_streak = 0
	duel_target_index = -1
	perfect_deflect = false
	deferred_damage = 0.0
	player["statuses"] = []
	player["dodge_layers"] = 0
	var opening_state := {
		"enemy_attack_multiplier": enemy_attack_multiplier,
		"player_block": player_block,
		"dodge_layers": int(player.get("dodge_layers", 0))
	}
	var opening_result := set_effect_service.apply_battle_start(player, opening_state, log, status_service)
	enemy_attack_multiplier = float(opening_result.get("enemy_attack_multiplier", 1.0))
	player_block = int(opening_result.get("player_block", 0))
	player["dodge_layers"] = int(opening_result.get("dodge_layers", 0))

	if _has_first_strike(enemies):
		first_strike_done = true
		var first_result := _apply_enemy_attack(player, enemies[0], 0, player_block, log, true, -1, counter_state)
		player_block = int(first_result["block"])
	status_service.fire_trigger(player, TriggerEvents.ON_BATTLE_START, {"battle_log": log, "session": self})

	while player["hp"] > 0 and _alive_count(enemies) > 0 and rounds < MAX_ROUNDS:
		rounds += 1
		player_block = 0
		perfect_deflect = false
		ranger_hit_count = 0
		sim_counters["ranger_hit_count"] = 0
		charge_sim.charge_one_for_round(charge_state)
		status_service.fire_trigger(player, TriggerEvents.ON_TURN_START, {"battle_log": log, "session": self, "round_index": rounds, "not_attacked_last_turn": false})

		# 每回合一次攻击
		if _alive_count(enemies) > 0:
			_execute_player_innate_attack_in_sim(player, enemies, log, charge_state)
			for _i in range(charge_sim.consume_repeats(charge_state, "attack")):
				_execute_player_innate_attack_in_sim(player, enemies, log, charge_state, "attack_charge_repeat")
			var innate_skill_id := _player_attack_skill_id(player)
			var innate_skill: Dictionary = DataCatalog.INNATE_SKILLS.get(innate_skill_id, DataCatalog.INNATE_SKILLS["innate_attack_1"])
			energy = mini(DataCatalog.ENERGY_MAX, energy + int(innate_skill.get("energy_gain", DataCatalog.ATTACK_ENERGY)))

			# 尝试使用技能
			if _should_use_skill_in_sim(player, energy, skill_cooldowns) and _alive_count(enemies) > 0:
				var skill_id := _first_skill_id(player)
				var skill: Dictionary = DataCatalog.SKILLS[skill_id]
				var skill_type := String(skill.get("type", "attack"))
				if SkillActionService.has_actions(skill):
					player_block += _execute_player_action_skill_in_sim(player, enemies, skill_id, skill, log, charge_state, counter_state)
				elif skill_type == "attack":
					var skill_damage := _skill_damage(player)
					if skill_damage > 0:
						skill_damage = charge_sim.apply_attack_modifiers(skill_damage, charge_state, skill_id)
						var is_aoe := bool(skill.get("aoe", false))
						var extra_hits_sim := int(status_service.resolve_stat(player, float(player.get("extra_hits", 0)), StatusService.STAT_EXTRA_HITS))
						var hits := maxi(1, int(skill.get("hits", 1)) + extra_hits_sim)
						# 护甲削减（碎裂斩等）
						var armor_reduce := float(skill.get("armor_reduce", 0.0))
						if armor_reduce > 0.0:
							var target_idx := _lowest_hp_enemy_index(enemies)
							if target_idx >= 0:
								var old_armor := int(enemies[target_idx].get("armor", 0))
								enemies[target_idx]["armor"] = maxi(0, int(round(float(old_armor) * (1.0 - armor_reduce))))
								log.append("skill_armor_reduce:%s:%d->%d" % [enemies[target_idx]["name"], old_armor, int(enemies[target_idx]["armor"])])
						# AOE / 单目标分支
						if is_aoe:
							for _hit in range(hits):
								for enemy in enemies:
									if int(enemy["hp"]) <= 0:
										continue
									_damage_enemy_direct(enemy, skill_damage, log, "skill")
							for _i in range(charge_sim.consume_repeats(charge_state, "attack", skill_id)):
								for _hit2 in range(hits):
									for enemy in enemies:
										if int(enemy["hp"]) <= 0:
											continue
										_damage_enemy_direct(enemy, skill_damage, log, "skill_charge_repeat")
						else:
							for _hit in range(hits):
								_damage_lowest_enemy(enemies, skill_damage, log, "skill")
							for _i in range(charge_sim.consume_repeats(charge_state, "attack", skill_id)):
								for _hit2 in range(hits):
									_damage_lowest_enemy(enemies, skill_damage, log, "skill_charge_repeat")
						# 溅射（爆裂猛击等）
						if bool(skill.get("splash", false)):
							var splash_mult := float(skill.get("splash_multiplier", 1.0))
							var splash_damage := maxi(1, int(round(float(skill_damage) * splash_mult)))
							var main_target := _lowest_hp_enemy_index(enemies)
							if main_target >= 0:
								for offset in [-1, 1]:
									var splash_idx: int = main_target + offset
									if splash_idx >= 0 and splash_idx < enemies.size() and splash_idx != main_target:
										if int(enemies[splash_idx]["hp"]) > 0:
											_damage_enemy_direct(enemies[splash_idx], splash_damage, log, "skill_splash")
						# 自身格挡（爆裂猛击等）
						var self_block_mult := float(skill.get("self_block_multiplier", 0.0))
						if self_block_mult > 0.0:
							var block_gain := maxi(1, int(round(float(player.get("block_power", player.get("defense", 1))) * self_block_mult)))
							player_block += block_gain
							log.append("skill_self_block:%s:%d" % [skill_id, block_gain])
						# 追加 AOE（碎裂斩等）
						var aoe_multiplier := float(skill.get("aoe_multiplier", 0.0))
						if aoe_multiplier > 0.0:
							var base_attack: float = status_service.resolve_stat(player, float(player["attack"]), StatusService.STAT_ATTACK)
							var aoe_damage := maxi(1, int(round(base_attack * aoe_multiplier)))
							for enemy in enemies:
								if int(enemy["hp"]) <= 0:
									continue
								_damage_enemy_direct(enemy, aoe_damage, log, "skill_aoe_followup")
						# 反击状态（反击风暴等）
						var counter_mult := float(skill.get("counter_attack_multiplier", 0.0))
						var counter_charges := int(skill.get("counter_charges", 0))
						if counter_mult > 0.0 and counter_charges > 0:
							counter_state["charges"] = int(counter_state["charges"]) + counter_charges
							counter_state["multiplier"] = maxf(float(counter_state["multiplier"]), counter_mult)
						# 削弱（真空斩/重砍等）
						var weaken_mult := float(skill.get("weaken_multiplier", 0.0))
						if weaken_mult > 0.0:
							var weaken_target := _lowest_hp_enemy_index(enemies)
							if weaken_target >= 0:
								var weaken_status := {
									"id": skill_id,
									"name": skill["name"],
									"kind": "debuff",
									"stack": "replace",
									"effects": [{"stat": "attack", "type": "multiply", "value": weaken_mult}],
									"duration": 2
								}
								status_service.add_status(enemies[weaken_target], weaken_status)
					# 铁血清算：回复 + 清debuff + DOT
					var heal_percent := float(skill.get("heal_percent", 0.0))
					if heal_percent > 0.0:
						var heal_amount := maxi(1, int(round(float(skill_damage) * heal_percent)))
						player["hp"] = mini(int(player["max_hp"]), int(player["hp"]) + heal_amount)
						log.append("skill_heal:%s:%d" % [skill_id, heal_amount])
					if bool(skill.get("clear_debuffs", false)):
						log.append("clear_debuffs:%s" % skill_id)
					var dot_mult := float(skill.get("dot_multiplier", 0.0))
					var dot_duration := int(skill.get("dot_duration", 0))
					if dot_mult > 0.0 and dot_duration > 0:
						var dot_damage := maxi(1, int(round(float(player["attack"]) * dot_mult)))
						var dot_status := {
							"id": skill_id + "_dot",
							"name": skill["name"] + " DOT",
							"kind": "debuff",
							"stack": "replace",
							"tick_effects": [{"stat": "hp", "type": "flat", "value": float(-dot_damage)}],
							"duration": dot_duration
						}
						for enemy in enemies:
							if int(enemy["hp"]) <= 0:
								continue
							status_service.add_status(enemy, dot_status)
						log.append("dot:%s:%d:%d" % [skill_id, dot_damage, dot_duration])
				elif skill_type == "defense" or skill_type == "stance":
					var block_gain := maxi(1, int(round(float(player.get("block_power", player.get("defense", 1))) * (float(skill.get("multiplier", skill.get("block_multiplier", 1.0))) + char_service.skill_multiplier_bonus(player, skill_id, "defense")))))
					block_gain = charge_sim.apply_defense_modifiers(block_gain, charge_state, skill_id)
					player_block += block_gain
					for _i in range(charge_sim.consume_repeats(charge_state, "defense", skill_id)):
						player_block += block_gain
					if skill_type == "stance":
						counter_state["charges"] = int(counter_state["charges"]) + 1
						counter_state["multiplier"] = maxf(float(counter_state["multiplier"]), float(skill.get("counter_multiplier", 1.0)) + char_service.skill_multiplier_bonus(player, skill_id, "attack"))
				elif skill_type == "heal":
					_skill_damage(player)
				elif skill_type == "buff":
					var effects: Array[Dictionary] = skill.get("effects", [])
					if effects.is_empty():
						var bonus: float = char_service.skill_multiplier_bonus(player, skill_id, "attack")
						var multiplier: float = float(skill.get("attack_multiplier", 1.0)) + bonus
						effects = [{"stat": "attack", "type": "multiply", "value": multiplier}]
					var status := {
						"id": skill_id,
						"name": skill["name"],
						"kind": "buff",
						"stack": "replace",
						"effects": effects,
						"duration": int(skill.get("duration", -1))
					}
					var tick_effects: Array = skill.get("tick_effects", [])
					if not tick_effects.is_empty():
						status["tick_effects"] = tick_effects
					var reflect_mult := float(skill.get("reflect_multiplier", 0.0))
					if reflect_mult > 0.0:
						status["reflect_multiplier"] = reflect_mult
					var deferred_pct := float(skill.get("deferred_damage_percent", 0.0))
					if deferred_pct > 0.0:
						status["deferred_damage_percent"] = deferred_pct
					status_service.add_status(player, status)
					log.append("buff:%s" % skill_id)
				elif skill_type == "duel":
					duel_target_index = _lowest_hp_enemy_index(enemies)
					if duel_target_index >= 0:
						var duel_buff := {
							"id": skill_id,
							"name": skill["name"],
							"kind": "buff",
							"stack": "replace",
							"effects": [{"stat": "attack", "type": "multiply", "value": float(skill.get("attack_multiplier", 2.0))}],
							"duration": -1
						}
						status_service.add_status(player, duel_buff)
						log.append("duel:%s:%s" % [skill_id, enemies[duel_target_index]["name"]])
				elif skill_type == "deflect":
					perfect_deflect = true
					log.append("deflect:%s" % skill_id)
				energy -= maxi(0, int(skill.get("energy_cost", 0)) + int(status_service.resolve_stat(player, 0.0, StatusService.STAT_ENERGY_COST)))
				var cooldown := int(skill.get("cooldown", 0))
				if cooldown > 0:
					skill_cooldowns[skill_id] = cooldown

		# 冷却回合递减
		var expired: Array[String] = []
		for sk_id in skill_cooldowns.keys():
			var cd_reduction := int(status_service.resolve_stat(player, 0.0, StatusService.STAT_COOLDOWN))
			var remaining := int(skill_cooldowns[sk_id]) - 1 - cd_reduction
			if remaining <= 0:
				expired.append(sk_id)
				skill_cooldowns[sk_id] = remaining
		for sk_id in expired:
			skill_cooldowns.erase(sk_id)

		# 每回合效果（回血/扣血等）
		_process_sim_tick_effects(player, log)
		for enemy in enemies:
			if int(enemy["hp"]) <= 0:
				continue
			_process_sim_tick_effects(enemy, log)

		# 延迟伤害结算
		if deferred_damage > 0.0:
			var deferred_tick := maxi(1, int(round(deferred_damage / 3.0)))
			deferred_tick = mini(deferred_tick, int(deferred_damage))
			deferred_damage -= float(deferred_tick)
			player["hp"] = maxi(1, int(player["hp"]) - deferred_tick)
			log.append("deferred_damage:%d" % deferred_tick)

		# 检查裂变特性：HP 低于阈值的敌人可能分裂
		CombatRules.check_split(enemies, log)
		CombatRules.check_summon(enemies, log)

		if duel_target_index >= 0 and (duel_target_index >= enemies.size() or int(enemies[duel_target_index]["hp"]) <= 0):
			duel_target_index = -1
			log.append("duel_end")
		if _alive_count(enemies) == 0:
			break

		_clear_enemy_blocks(enemies)
		_clear_enemy_taunts(enemies)
		_clear_enemy_blocks(allies)
		_clear_enemy_taunts(allies)
		for enemy in enemies:
			if enemy["hp"] <= 0:
				continue
			status_service.fire_trigger(enemy, TriggerEvents.ON_TURN_START, {"battle_log": log, "session": null, "round_index": rounds})
		var actions := 0
		var is_alone := _alive_count(enemies) + _alive_count(allies) <= 1
		for i in range(enemies.size()):
			var enemy: Dictionary = enemies[i]
			if enemy["hp"] <= 0:
				continue
			if bool(enemy.get("interrupted", false)):
				enemy["interrupted"] = false
				log.append("interrupt:%s" % enemy["name"])
				continue
			if actions >= 2:
				_enemy_defend(enemy, 0.5)
				continue
			var action_result := _resolve_enemy_action(player, enemy, player_block, rounds, counter_state, log, is_alone, i)
			player_block = int(action_result["block"])
			actions += 1
		for ally in allies:
			if int(ally.get("hp", 0)) <= 0 or String(ally.get("controlled_by", "")) != "ai":
				continue
			if bool(ally.get("interrupted", false)):
				ally["interrupted"] = false
				log.append("interrupt:%s" % ally["name"])
				continue
			status_service.fire_trigger(ally, TriggerEvents.ON_TURN_START, {"battle_log": log, "session": null, "round_index": rounds})
			if actions >= 2:
				_enemy_defend(ally, 0.5)
				continue
			var ally_result := _resolve_enemy_action(player, ally, player_block, rounds, counter_state, log, is_alone)
			player_block = int(ally_result["block"])
			actions += 1
			status_service.fire_trigger(ally, TriggerEvents.ON_TURN_END, {"battle_log": log, "session": null, "round_index": rounds})
		for enemy in enemies:
			if enemy["hp"] <= 0:
				continue
			status_service.fire_trigger(enemy, TriggerEvents.ON_TURN_END, {"battle_log": log, "session": null, "round_index": rounds})

		CombatRules.apply_end_round_traits(player, enemies, rounds, status_service, log)
		CombatRules.apply_arena_effects(player, enemies, rounds, status_service)

	var victory: bool = int(player["hp"]) > 0 and _alive_count(enemies) == 0
	return {
		"victory": victory,
		"rounds": rounds,
		"first_strike": first_strike_done,
		"enemies_total": enemies.size(),
		"enemies_alive": _alive_count(enemies),
		"player_hp": int(player["hp"]),
		"energy": energy,
		"skill_cooldowns": skill_cooldowns,
		"log": log
	}


func _build_enemies(encounter: Dictionary, tower_floor: int) -> Array[Dictionary]:
	return CombatRules.build_enemies(encounter, tower_floor)


func _execute_player_action_skill_in_sim(player: Dictionary, enemies: Array[Dictionary], skill_id: String, skill: Dictionary, log: Array[String], charge_state: Dictionary, counter_state: Dictionary) -> int:
	var attack_repeat_bonus := -1
	var defense_repeat_bonus := -1
	var block_gain := 0
	for action in SkillActionService.actions(skill):
		var action_type := String(action.get("type", ""))
		match action_type:
			SkillActionService.ACTION_DAMAGE:
				var damage_repeat_bonus := 0
				if bool(action.get("repeat_with_charge", true)):
					if attack_repeat_bonus < 0:
						attack_repeat_bonus = charge_sim.consume_repeats(charge_state, "attack", skill_id)
					damage_repeat_bonus = attack_repeat_bonus
				_execute_action_damage_in_sim(player, enemies, skill_id, skill, action, log, charge_state, damage_repeat_bonus)
			SkillActionService.ACTION_MODIFY_ARMOR:
				_execute_action_modify_armor_in_sim(enemies, skill, action, log)
			SkillActionService.ACTION_APPLY_STATUS:
				_execute_action_apply_status_in_sim(player, enemies, skill_id, action)
			SkillActionService.ACTION_GAIN_BLOCK:
				var block_repeat_bonus := 0
				if String(action.get("charge_tag", "")) == "defense" and bool(action.get("repeat_with_charge", true)):
					if defense_repeat_bonus < 0:
						defense_repeat_bonus = charge_sim.consume_repeats(charge_state, "defense", skill_id)
					block_repeat_bonus = defense_repeat_bonus
				block_gain += _action_block_amount_in_sim(player, skill_id, action, charge_state, block_repeat_bonus)
			SkillActionService.ACTION_GAIN_DODGE:
				_execute_action_gain_dodge_in_sim(player, action)
			SkillActionService.ACTION_INTERRUPT:
				_execute_action_interrupt_in_sim(enemies, skill, action, log)
			SkillActionService.ACTION_SET_COUNTER_ATTACK:
				var charges := int(action.get("charges", 0))
				if charges > 0:
					counter_state["charges"] = int(counter_state["charges"]) + charges
					var multiplier: float = float(action.get("multiplier", 1.0))
					var bonus_stat := String(action.get("skill_bonus_stat", ""))
					if bonus_stat != "":
						multiplier += char_service.skill_multiplier_bonus(player, skill_id, bonus_stat)
					counter_state["multiplier"] = maxf(float(counter_state["multiplier"]), multiplier)
			SkillActionService.ACTION_CLEAR_DEBUFFS:
				status_service.clear_debuffs(player)
			SkillActionService.ACTION_HEAL:
				_execute_action_heal_in_sim(player, skill_id, action)
			SkillActionService.ACTION_SET_DUEL:
				_execute_action_set_duel_in_sim(player, enemies, skill_id, skill, action, log)
			SkillActionService.ACTION_SET_DEFLECT:
				perfect_deflect = true
				log.append("deflect:%s" % skill_id)
	return block_gain


func _execute_action_damage_in_sim(player: Dictionary, enemies: Array[Dictionary], skill_id: String, skill: Dictionary, action: Dictionary, log: Array[String], charge_state: Dictionary, repeat_bonus: int) -> void:
	var targets := _action_target_indexes_in_sim(enemies, action)
	if targets.is_empty():
		return
	var extra_hits := int(status_service.resolve_stat(player, float(player.get("extra_hits", 0)), StatusService.STAT_EXTRA_HITS)) if bool(action.get("include_extra_hits", true)) else 0
	var hits := maxi(1, int(action.get("hits", skill.get("hits", 1))) + extra_hits)
	var multiplier: float = float(action.get("multiplier", skill.get("multiplier", 1.0))) + char_service.skill_multiplier_bonus(player, skill_id, "attack")
	var repeat_count := 1 + repeat_bonus if bool(action.get("repeat_with_charge", true)) else 1
	for _repeat in range(repeat_count):
		for target in targets:
			for _hit in range(hits):
				if _alive_count(enemies) <= 0:
					return
				if target < 0 or target >= enemies.size() or int(enemies[target]["hp"]) <= 0:
					continue
				var damage := _action_attack_value_in_sim(player, skill_id, multiplier)
				damage = charge_sim.apply_attack_modifiers(damage, charge_state, skill_id)
				_damage_enemy_direct(enemies[target], damage, log, "skill_action")


func _execute_action_modify_armor_in_sim(enemies: Array[Dictionary], skill: Dictionary, action: Dictionary, log: Array[String]) -> void:
	var targets := _action_target_indexes_in_sim(enemies, action)
	var multiplier: float = float(action.get("multiplier", 1.0))
	for target in targets:
		if target < 0 or target >= enemies.size() or int(enemies[target]["hp"]) <= 0:
			continue
		var old_armor := int(enemies[target].get("armor", 0))
		enemies[target]["armor"] = maxi(0, int(round(float(old_armor) * multiplier)))
		if old_armor != int(enemies[target]["armor"]):
			log.append("skill_action_armor:%s:%d->%d" % [skill["name"], old_armor, int(enemies[target]["armor"])])


func _execute_action_apply_status_in_sim(player: Dictionary, enemies: Array[Dictionary], skill_id: String, action: Dictionary) -> void:
	var status: Dictionary = _resolved_action_status_in_sim(player, skill_id, action)
	if status.is_empty():
		return
	var target_mode := String(action.get("target", SkillActionService.TARGET_SELECTED))
	if target_mode == SkillActionService.TARGET_SELF:
		status_service.add_status(player, status)
		return
	for target in _action_target_indexes_in_sim(enemies, action):
		if target >= 0 and target < enemies.size() and int(enemies[target]["hp"]) > 0:
			status_service.add_status(enemies[target], status)


func _resolved_action_status_in_sim(player: Dictionary, skill_id: String, action: Dictionary) -> Dictionary:
	var status: Dictionary = action.get("status", {})
	if status.is_empty():
		return {}
	var result := status.duplicate(true)
	for effect in result.get("effects", []):
		var bonus_stat := String(effect.get("skill_bonus_stat", ""))
		if bonus_stat == "":
			continue
		effect["value"] = float(effect.get("value", 0.0)) + char_service.skill_multiplier_bonus(player, skill_id, bonus_stat)
		effect.erase("skill_bonus_stat")
	for tick in result.get("tick_effects", []):
		if not tick.has("source_stat"):
			continue
		var stat := String(tick.get("source_stat", ""))
		var multiplier := float(tick.get("source_multiplier", 1.0))
		var amount := maxi(1, int(round(float(player.get(stat, 0)) * multiplier)))
		tick.erase("source_stat")
		tick.erase("source_multiplier")
		tick["value"] = -amount if bool(tick.get("negative", false)) else amount
		tick.erase("negative")
	return result


func _action_block_amount_in_sim(player: Dictionary, skill_id: String, action: Dictionary, charge_state: Dictionary, repeat_bonus: int = 0) -> int:
	var amount := int(action.get("amount", 0))
	if amount <= 0:
		var stat := String(action.get("stat", "block_power"))
		var multiplier: float = float(action.get("multiplier", 1.0))
		var bonus_stat := String(action.get("skill_bonus_stat", ""))
		if bonus_stat != "":
			multiplier += char_service.skill_multiplier_bonus(player, skill_id, bonus_stat)
		var base_value: float = float(player.get(stat, player.get("block_power", 1)))
		var resolved_value: float = status_service.resolve_stat(player, base_value, StatusService.STAT_DEFENSE)
		amount = maxi(1, int(round(resolved_value * multiplier)))
	if bool(action.get("apply_defense_charge", false)):
		amount = charge_sim.apply_defense_modifiers(amount, charge_state, skill_id)
	var total_amount := amount
	for _i in range(repeat_bonus):
		total_amount += amount
	return total_amount


func _execute_action_gain_dodge_in_sim(player: Dictionary, action: Dictionary) -> void:
	var gained := maxi(1, int(action.get("layers", 1)))
	player["dodge_layers"] = int(player.get("dodge_layers", 0)) + gained


func _execute_action_interrupt_in_sim(enemies: Array[Dictionary], skill: Dictionary, action: Dictionary, log: Array[String]) -> void:
	for target in _action_target_indexes_in_sim(enemies, action):
		if target >= 0 and target < enemies.size() and int(enemies[target]["hp"]) > 0:
			enemies[target]["interrupted"] = true
			log.append("skill_action_interrupt:%s:%s" % [skill["name"], enemies[target]["name"]])


func _execute_action_heal_in_sim(player: Dictionary, skill_id: String, action: Dictionary) -> void:
	var amount := int(action.get("amount", 0))
	if amount <= 0:
		var stat := String(action.get("stat", "attack"))
		var multiplier: float = float(action.get("multiplier", 1.0))
		var bonus_stat := String(action.get("skill_bonus_stat", stat))
		if bonus_stat != "":
			multiplier += char_service.skill_multiplier_bonus(player, skill_id, bonus_stat)
		amount = maxi(1, int(round(float(player.get(stat, 0)) * multiplier)))
	if bool(action.get("resolve_heal", true)):
		var resolved_heal: float = status_service.resolve_stat(player, float(amount), StatusService.STAT_HEAL)
		amount = maxi(1, int(round(resolved_heal)))
	player["hp"] = mini(int(player["max_hp"]), int(player["hp"]) + amount)


func _execute_action_set_duel_in_sim(player: Dictionary, enemies: Array[Dictionary], skill_id: String, skill: Dictionary, action: Dictionary, log: Array[String]) -> void:
	duel_target_index = _lowest_hp_enemy_index(enemies)
	if duel_target_index < 0:
		return
	var multiplier: float = float(action.get("multiplier", 1.0))
	var bonus_stat := String(action.get("skill_bonus_stat", ""))
	if bonus_stat != "":
		multiplier += char_service.skill_multiplier_bonus(player, skill_id, bonus_stat)
	var duel_buff := {
		"id": skill_id,
		"name": skill["name"],
		"kind": "buff",
		"stack": "replace",
		"effects": [{"stat": "attack", "type": "multiply", "value": multiplier}],
		"duration": int(action.get("duration", -1))
	}
	status_service.add_status(player, duel_buff)
	log.append("duel:%s:%s" % [skill_id, enemies[duel_target_index]["name"]])


func _action_attack_value_in_sim(player: Dictionary, skill_id: String, multiplier: float) -> int:
	var resolved_attack: float = status_service.resolve_stat(player, float(player["attack"]), StatusService.STAT_ATTACK)
	return maxi(1, int(round(resolved_attack * multiplier)))


func _action_target_indexes_in_sim(enemies: Array[Dictionary], action: Dictionary) -> Array[int]:
	var target_mode := String(action.get("target", SkillActionService.TARGET_SELECTED))
	var result: Array[int] = []
	match target_mode:
		SkillActionService.TARGET_ALL_ENEMIES:
			for i in range(enemies.size()):
				if int(enemies[i]["hp"]) > 0:
					result.append(i)
		SkillActionService.TARGET_ADJACENT:
			var center := _lowest_hp_enemy_index(enemies)
			if center < 0:
				return result
			for offset in [-1, 1]:
				var idx: int = center + offset
				if idx >= 0 and idx < enemies.size() and int(enemies[idx]["hp"]) > 0:
					result.append(idx)
		_:
			var selected := _lowest_hp_enemy_index(enemies)
			if selected >= 0:
				result.append(selected)
	return result


func scale_enemy(unit: Dictionary, tower_floor: int, rank: String, formation_scale: float = 1.0) -> Dictionary:
	return Combatant.scaled_enemy(unit, tower_floor, rank, formation_scale)


func _should_use_skill_in_sim(player: Dictionary, energy: int, skill_cooldowns: Dictionary) -> bool:
	if player["equipped_skills"].is_empty():
		return false
	var skill_id := _first_skill_id(player)
	if skill_id == "" or not DataCatalog.SKILLS.has(skill_id):
		return false
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var energy_cost := maxi(0, int(skill.get("energy_cost", 0)) + int(status_service.resolve_stat(player, 0.0, StatusService.STAT_ENERGY_COST)))
	if energy < energy_cost:
		return false
	var cooldown := int(skill.get("cooldown", 0))
	if cooldown > 0 and skill_cooldowns.get(skill_id, 0) > 0:
		return false
	return true


func _skill_damage(player: Dictionary) -> int:
	var skill_id: String = _first_skill_id(player)
	if skill_id == "" or not DataCatalog.SKILLS.has(skill_id):
		return 0
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	if skill.get("type", "") == "heal":
		var healed := maxi(1, int(round(float(player["max_hp"]) * (float(skill.get("heal_multiplier", 0.0)) + char_service.skill_multiplier_bonus(player, skill_id, "hp")))))
		player["hp"] = mini(int(player["max_hp"]), int(player["hp"]) + healed)
		return 0
	var multiplier := float(skill.get("multiplier", 1.0)) + char_service.skill_multiplier_bonus(player, skill_id, "attack")
	var base_attack: float = status_service.resolve_stat(player, float(player["attack"]), StatusService.STAT_ATTACK)
	return maxi(1, int(round(base_attack * multiplier)))



func _first_skill_id(player: Dictionary) -> String:
	if player["equipped_skills"].is_empty():
		return ""
	for skill_id in player["equipped_skills"]:
		var id := String(skill_id)
		if id != "" and DataCatalog.SKILLS.has(id):
			return id
	return ""


func _player_attack_skill_id(player: Dictionary) -> String:
	var innate_skills: Dictionary = player.get("innate_skills", {})
	var skill_id := String(innate_skills.get("attack_1", "innate_attack_1"))
	if DataCatalog.INNATE_SKILLS.has(skill_id):
		return skill_id
	return "innate_attack_1"


func _execute_player_innate_attack_in_sim(player: Dictionary, enemies: Array[Dictionary], log: Array[String], charge_state: Dictionary, source: String = "attack") -> void:
	var skill_id := _player_attack_skill_id(player)
	var skill: Dictionary = DataCatalog.INNATE_SKILLS[skill_id]
	var hits := maxi(1, int(skill.get("hits", 1)))
	var damage := _player_innate_attack_value_in_sim(player, skill_id, skill)
	damage = charge_sim.apply_attack_modifiers(damage, charge_state)
	for _hit in range(hits):
		if _alive_count(enemies) <= 0:
			break
		_damage_lowest_enemy_from_player(player, enemies, damage, log, source)
	status_service.fire_trigger(player, TriggerEvents.ON_ATTACK_COMPLETE, {
		"battle_log": log, "session": self, "skill_id": skill_id, "source": player
	})


func _player_innate_attack_value_in_sim(player: Dictionary, skill_id: String, skill: Dictionary) -> int:
	var multiplier := float(skill.get("multiplier", 1.0))
	var resolved_attack: float = status_service.resolve_stat(player, float(player["attack"]), StatusService.STAT_ATTACK)
	var modifiers := ModifierPipeline.collect_from_session(self, "attack", {"skill_id": skill_id, "skill_multiplier": multiplier}, ActionSource.ACTIVE_ATTACK)
	return maxi(1, int(round(ModifierPipeline.resolve(resolved_attack, modifiers)))) + _state_bonus(player, "attack")


func _damage_lowest_enemy(enemies: Array[Dictionary], amount: int, log: Array[String], source: String) -> void:
	if amount <= 0:
		return
	var target_index := _active_taunt_target(enemies)
	var target_hp := 999999
	if target_index < 0:
		var has_frontline := CombatRules.has_active_frontline(enemies)
		for i in range(enemies.size()):
			var enemy := enemies[i]
			if enemy["hp"] <= 0:
				continue
			# 有前排存活时跳过 backline 目标
			if CombatRules.is_backline_protected_by_frontline(enemy, has_frontline):
				continue
			if enemy["hp"] < target_hp:
				target_hp = enemy["hp"]
				target_index = i
	if target_index < 0:
		return
	var target := enemies[target_index]
	var result := Combatant.apply_damage(target, amount)
	if bool(result["dodged"]):
		log.append("%s:%s:dodge" % [source, target["name"]])
		return
	log.append("%s:%s:%d" % [source, target["name"], int(result["damage"])])


func _damage_lowest_enemy_from_player(player: Dictionary, enemies: Array[Dictionary], amount: int, log: Array[String], source: String) -> void:
	if amount <= 0:
		return
	var target_index := _active_taunt_target(enemies)
	var target_hp := 999999
	if target_index < 0:
		var has_frontline := CombatRules.has_active_frontline(enemies)
		for i in range(enemies.size()):
			var enemy := enemies[i]
			if enemy["hp"] <= 0:
				continue
			if CombatRules.is_backline_protected_by_frontline(enemy, has_frontline):
				continue
			if enemy["hp"] < target_hp:
				target_hp = enemy["hp"]
				target_index = i
	if target_index < 0:
		return
	_damage_enemy_index_from_player(player, enemies, target_index, amount, log, source)


func _damage_enemy_index_from_player(player: Dictionary, enemies: Array[Dictionary], target_index: int, amount: int, log: Array[String], source: String) -> void:
	if target_index < 0 or target_index >= enemies.size() or amount <= 0:
		return
	var target := enemies[target_index]
	if int(target.get("hp", 0)) <= 0:
		return
	var result := Combatant.apply_damage(target, amount)
	if bool(result["dodged"]):
		log.append("%s:%s:dodge" % [source, target["name"]])
		status_service.fire_trigger(target, TriggerEvents.ON_DODGE, {"battle_log": log, "session": self, "source": player})
		return
	var damage := int(result["damage"])
	log.append("%s:%s:%d" % [source, target["name"], damage])
	var hit_context := {"battle_log": log, "session": self, "source": player, "target": target, "damage": damage}
	status_service.fire_trigger(player, TriggerEvents.ON_HIT_DEALT, hit_context)
	status_service.fire_trigger(target, TriggerEvents.ON_HIT_RECEIVED, hit_context)
	if int(target.get("hp", 0)) <= 0:
		status_service.fire_trigger(player, TriggerEvents.ON_KILL, hit_context)


func _apply_damage_to_player(player: Dictionary, block: int, damage: int) -> Dictionary:
	var player_unit := Combatant.from_player(player, block, int(player.get("dodge_layers", 0)), status_service)
	# 应用玩家身上的 damage_taken 乘数（mark 等特性施加的易伤 debuff）
	var damage_taken_mult: float = status_service.resolve_stat(player_unit, 1.0, StatusService.STAT_DAMAGE_TAKEN)
	var adjusted_damage := maxi(1, int(round(float(damage) * damage_taken_mult)))
	var result := Combatant.apply_damage(player_unit, adjusted_damage)
	var synced := Combatant.sync_to_player(player_unit, player)
	player["dodge_layers"] = int(synced["dodge_layers"])
	# 延迟伤害追踪
	if not bool(result["dodged"]):
		var deferred_pct := 0.0
		for status in player.get("statuses", []):
			deferred_pct = maxf(deferred_pct, float(status.get("deferred_damage_percent", 0.0)))
		if deferred_pct > 0.0:
			deferred_damage += float(int(result["damage"])) * deferred_pct
	return {"block": int(synced["block"]), "hit": not bool(result["dodged"])}


func _apply_enemy_attack(player: Dictionary, enemy: Dictionary, enemy_index: int, block: int, log: Array[String], first_strike: bool, round_index: int, counter_state: Dictionary) -> Dictionary:
	# 决斗免疫
	if duel_target_index >= 0 and enemy_index != duel_target_index:
		log.append("duel_block:%s" % enemy["name"])
		return {"block": block, "hit": false}
	# 完美偏转
	if perfect_deflect:
		var total_reflect := 0
		for damage in _enemy_attack_segments(enemy, round_index, first_strike):
			total_reflect += damage
		total_reflect = maxi(1, total_reflect)
		log.append("perfect_deflect:%s:%d" % [enemy["name"], total_reflect])
		return {"block": block, "hit": false}
	var was_hit := false
	var dodge_counted := false
	for damage in _enemy_attack_segments(enemy, round_index, first_strike):
		var result := _apply_damage_to_player(player, block, damage)
		block = int(result["block"])
		var hit := bool(result["hit"])
		was_hit = was_hit or hit
		log.append("enemy_attack:%s:%d" % [enemy["name"], damage])
		if hit:
			var hit_context := {
				"battle_log": log, "session": self, "round_index": round_index,
				"source": enemy, "target": player, "damage": damage
			}
			status_service.fire_trigger(enemy, TriggerEvents.ON_HIT_DEALT, hit_context)
			status_service.fire_trigger(player, TriggerEvents.ON_HIT_RECEIVED, hit_context)
		else:
			if not dodge_counted:
				dodge_streak += 1
				dodge_counted = true
			status_service.fire_trigger(player, TriggerEvents.ON_DODGE, {"battle_log": log, "session": self, "source": enemy})
	if was_hit:
		_trigger_counter_attack(player, enemy, enemy_index, log, counter_state)
		_sim_reflect_damage(player, enemy, enemy_index, log)
	return {"block": block, "hit": was_hit}


func _enemy_round_damage(enemy: Dictionary, round_index: int) -> int:
	var total := 0
	for damage in _enemy_attack_segments(enemy, round_index, false):
		total += damage
	return total


func _enemy_attack_segments(enemy: Dictionary, round_index: int, first_strike: bool) -> Array[int]:
	var segments := enemy_rules.attack_segments(enemy, round_index, first_strike)
	var base_attack := float(enemy["attack"])
	var resolved_attack: float = status_service.resolve_stat(enemy, base_attack, StatusService.STAT_ATTACK)
	var total_multiplier := enemy_attack_multiplier * (resolved_attack / maxf(1.0, base_attack))
	if abs(total_multiplier - 1.0) < 0.001:
		return segments
	var result: Array[int] = []
	for damage in segments:
		result.append(maxi(1, int(round(float(damage) * total_multiplier))))
	return result


func _incoming_damage(enemies: Array[Dictionary], round_index: int) -> int:
	var total := 0
	var actions := 0
	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		if actions >= 2:
			break
		var is_alone := _alive_count(enemies) <= 1
		var skill_id := enemy_rules.choose_skill(enemy, round_index, {}, is_alone)
		var skill: Dictionary = DataCatalog.SKILLS.get(skill_id, DataCatalog.INNATE_SKILLS.get(skill_id, {}))
		if skill.get("type", "") == "attack":
			if skill_id.begins_with("innate_attack_"):
				total += _enemy_round_damage(enemy, round_index)
			else:
				var hits := maxi(1, int(skill.get("hits", 1)))
				total += CombatRules.skill_attack_value_for_actor(enemy, skill_id) * hits
		actions += 1
	return total


func get_counter(name: String) -> int:
	match name:
		"meticulous_stacks": return meticulous_stacks
		"seek_bloom_stacks": return seek_bloom_stacks
		"ranger_hit_count": return ranger_hit_count
		_: return int(sim_counters.get(name, 0))


func set_counter(name: String, value: int) -> void:
	sim_counters[name] = value
	match name:
		"meticulous_stacks": meticulous_stacks = value
		"seek_bloom_stacks": seek_bloom_stacks = value
		"ranger_hit_count": ranger_hit_count = value


func _opposing_units(actor: Dictionary) -> Array[Dictionary]:
	if actor == player:
		return active_enemies
	var result: Array[Dictionary] = []
	result.append(player)
	return result


func find_enemy_index(target: Dictionary) -> int:
	for i in range(active_enemies.size()):
		if active_enemies[i] == target:
			return i
	return -1


func deal_damage(ctx: Dictionary) -> void:
	var target_index := int(ctx.get("target_index", 0))
	var damage := int(ctx.get("final_damage", ctx.get("base_damage", 0)))
	if target_index < 0 or target_index >= active_enemies.size():
		return
	_damage_enemy_index_from_player(player, active_enemies, target_index, damage, active_log, "trigger")




func _build_player_context(player: Dictionary, block: int) -> Dictionary:
	return {
		"hp": int(player.get("hp", 0)),
		"max_hp": int(player.get("max_hp", 1)),
		"block": block,
		"block_power": int(player.get("block_power", player.get("defense", 1))),
		"dodge_layers": 0
	}


func _resolve_enemy_action(player: Dictionary, enemy: Dictionary, player_block: int, round_index: int, counter_state: Dictionary, log: Array[String], is_alone: bool = false, enemy_index: int = -1) -> Dictionary:
	var player_context := _build_player_context(player, player_block)
	var skill_id := enemy_rules.choose_skill(enemy, round_index, player_context, is_alone)
	return _execute_enemy_skill_in_sim(player, enemy, skill_id, player_block, round_index, counter_state, log, enemy_index)


func _trigger_counter_attack(player: Dictionary, enemy: Dictionary, enemy_index: int, log: Array[String], counter_state: Dictionary) -> void:
	if int(counter_state.get("charges", 0)) <= 0:
		return
	if int(enemy.get("hp", 0)) <= 0:
		return
	counter_state["charges"] = int(counter_state["charges"]) - 1
	var base_attack: float = status_service.resolve_stat(player, float(player["attack"]), StatusService.STAT_ATTACK)
	var damage := maxi(1, int(round(base_attack * float(counter_state.get("multiplier", 1.0)))))
	_damage_enemy_direct(enemy, damage, log, "counter")
	if int(counter_state["charges"]) <= 0:
		counter_state["multiplier"] = 1.0


func _damage_enemy_direct(enemy: Dictionary, amount: int, log: Array[String], source: String) -> void:
	if amount <= 0:
		return
	var result := Combatant.apply_damage(enemy, amount)
	if bool(result["dodged"]):
		log.append("%s:%s:dodge" % [source, enemy["name"]])
		return
	log.append("%s:%s:%d" % [source, enemy["name"], int(result["damage"])])


func _enemy_defend(enemy: Dictionary, scale: float) -> void:
	Combatant.add_block(enemy, scale)


func _enemy_intent(enemy: Dictionary, round_index: int, is_alone: bool = false) -> String:
	return enemy_rules.intent(enemy, round_index, {}, is_alone)


func _execute_enemy_skill_in_sim(player: Dictionary, enemy: Dictionary, skill_id: String, player_block: int, round_index: int, counter_state: Dictionary, log: Array[String], enemy_index: int = -1) -> Dictionary:
	var skill: Dictionary = DataCatalog.SKILLS.get(skill_id, DataCatalog.INNATE_SKILLS.get(skill_id, {}))
	if skill.is_empty():
		return {"block": player_block}
	var skill_type := String(skill.get("type", "attack"))
	match skill_type:
		"attack":
			if skill_id.begins_with("innate_attack_"):
				var result := _apply_enemy_attack(player, enemy, enemy_index, player_block, log, false, round_index, counter_state)
				return {"block": int(result["block"])}
			var damage := CombatRules.skill_attack_value_for_actor(enemy, skill_id, status_service)
			var hits := maxi(1, int(skill.get("hits", 1)))
			var was_hit := false
			for _hit in range(hits):
				var result := _apply_damage_to_player(player, player_block, damage)
				player_block = int(result["block"])
				was_hit = was_hit or bool(result["hit"])
				log.append("enemy_skill:%s:%s:%d" % [skill_id, enemy["name"], damage])
			if was_hit:
				# 技能命中后触发 ON_HIT_DEALT，使 break_armor/mark 等命中触发特性生效
				status_service.fire_trigger(enemy, TriggerEvents.ON_HIT_DEALT, {
					"battle_log": log, "session": null, "round_index": round_index,
					"source": enemy, "target": player, "damage": damage
				})
				_trigger_counter_attack(player, enemy, -1, log, counter_state)
		"defense", "stance":
			enemy["block"] = int(enemy.get("block", 0)) + CombatRules.skill_defense_value_for_actor(enemy, skill_id, status_service)
			log.append("enemy_skill_defend:%s:%s" % [skill_id, enemy["name"]])
		"dodge":
			Combatant.add_dodge(enemy, int(skill.get("dodge_layers", 1)))
			log.append("enemy_skill_dodge:%s:%s" % [skill_id, enemy["name"]])
		"taunt":
			enemy["taunt"] = int(skill.get("taunt_duration", 1))
			Combatant.add_block(enemy, 1.0)
			log.append("enemy_skill_taunt:%s:%s" % [skill_id, enemy["name"]])
		"heal":
			var healed := CombatRules.skill_heal_value_for_actor(enemy, skill_id, status_service)
			enemy["hp"] = mini(int(enemy["max_hp"]), int(enemy["hp"]) + healed)
			log.append("enemy_skill_heal:%s:%s" % [skill_id, enemy["name"]])
		"buff":
			var attack_mult := float(skill.get("attack_multiplier", 1.0))
			var status := {
				"id": skill_id,
				"name": skill["name"],
				"kind": "buff",
				"stack": "replace",
				"effects": [{"stat": "attack", "type": "multiply", "value": attack_mult}],
				"duration": -1
			}
			status_service.add_status(enemy, status)
			log.append("enemy_skill_buff:%s:%s" % [skill_id, enemy["name"]])
		"debuff":
			var weaken := float(skill.get("weaken_multiplier", 1.0))
			var status := {
				"id": skill_id,
				"name": skill["name"],
				"kind": "debuff",
				"stack": "replace",
				"effects": [{"stat": "attack", "type": "multiply", "value": weaken}],
				"duration": -1
			}
			status_service.add_status(player, status)
			log.append("enemy_skill_debuff:%s:%s" % [skill_id, enemy["name"]])
	return {"block": player_block}


func _clear_enemy_taunts(enemies: Array[Dictionary]) -> void:
	CombatRules.clear_enemy_taunts(enemies)


func _clear_enemy_blocks(enemies: Array[Dictionary]) -> void:
	CombatRules.clear_enemy_blocks(enemies)


func _active_taunt_target(enemies: Array[Dictionary]) -> int:
	return CombatRules.active_taunt_target(enemies)


func _state_bonus(player: Dictionary, tag: String) -> int:
	if tag == "attack":
		return int(player.get("state_attack_bonus", 0))
	if tag == "defense":
		return int(player.get("state_defense_bonus", 0))
	return 0


func _has_first_strike(enemies: Array[Dictionary]) -> bool:
	return enemy_rules.has_first_strike(enemies)


func _alive_count(enemies: Array[Dictionary]) -> int:
	return CombatRules.alive_count(enemies)


func _sim_reflect_damage(player: Dictionary, enemy: Dictionary, enemy_index: int, log: Array[String]) -> void:
	if int(enemy["hp"]) <= 0:
		return
	var reflect_mult := 0.0
	for status in player.get("statuses", []):
		reflect_mult = maxf(reflect_mult, float(status.get("reflect_multiplier", 0.0)))
	if reflect_mult <= 0.0:
		return
	var reflect_damage := maxi(1, int(round(float(player["attack"]) * reflect_mult)))
	_damage_enemy_direct(enemy, reflect_damage, log, "reflect")


func _process_sim_tick_effects(target: Dictionary, log: Array[String]) -> void:
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
						target["hp"] = mini(int(target["max_hp"]), int(target["hp"]) + amount)
					elif tick_value < 0.0:
						target["hp"] = maxi(1, int(target["hp"]) - amount)
				elif tick_type == "flat":
					if tick_value > 0.0:
						target["hp"] = mini(int(target["max_hp"]), int(target["hp"]) + int(tick_value))
					elif tick_value < 0.0:
						target["hp"] = maxi(1, int(target["hp"]) + int(tick_value))


func _lowest_hp_enemy_index(enemies: Array[Dictionary]) -> int:
	var target_index := _active_taunt_target(enemies)
	if target_index >= 0:
		return target_index
	var target_hp := 999999
	var has_frontline := CombatRules.has_active_frontline(enemies)
	for i in range(enemies.size()):
		var enemy := enemies[i]
		if enemy["hp"] <= 0:
			continue
		if CombatRules.is_backline_protected_by_frontline(enemy, has_frontline):
			continue
		if enemy["hp"] < target_hp:
			target_hp = enemy["hp"]
			target_index = i
	return target_index
