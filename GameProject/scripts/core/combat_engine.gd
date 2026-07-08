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

const MAX_ROUNDS := 40

var enemy_rules := EnemyActionRules.new()
var charge_sim := ChargeSimulator.new()
var char_service := CharacterService.new()
var status_service := StatusService.new()


func run_battle(player: Dictionary, encounter: Dictionary, tower_floor: int, battle_index: int) -> Dictionary:
	var enemies := _build_enemies(encounter, tower_floor)
	var log: Array[String] = []
	var rounds := 0
	var player_block := 0
	var used_first_skill := false
	var first_strike_done := false
	var charge_state := charge_sim.build_charge_state(player)
	var counter_state := {"charges": 0, "multiplier": 1.0}

	if _has_first_strike(enemies):
		first_strike_done = true
		var first_result := _apply_enemy_attack(player, enemies[0], 0, player_block, log, true, -1, counter_state)
		player_block = int(first_result["block"])

	while player["hp"] > 0 and _alive_count(enemies) > 0 and rounds < MAX_ROUNDS:
		rounds += 1
		player_block = 0
		var action_points: int = mini(rounds, 3)
		charge_sim.charge_one_for_round(charge_state)
		var incoming := _incoming_damage(enemies, rounds)

		var defend_value := int(player.get("block_power", player.get("defense", 1))) + _state_bonus(player, "defense")
		if defend_value >= 3 and incoming >= defend_value * 2 and action_points > 1:
			defend_value = charge_sim.apply_defense_modifiers(defend_value, charge_state)
			player_block += defend_value
			for _i in range(charge_sim.consume_repeats(charge_state, "defense")):
				player_block += defend_value
			action_points -= 1
			log.append("round_%d:defend" % rounds)

		if _should_use_skill(player, used_first_skill) and _can_pay_first_skill(player, action_points):
			var skill_id := _first_skill_id(player)
			var skill: Dictionary = DataCatalog.SKILLS[skill_id]
			var skill_type := String(skill.get("type", "attack"))
			if skill_type == "attack":
				var skill_damage := _skill_damage(player)
				if skill_damage > 0:
					skill_damage = charge_sim.apply_attack_modifiers(skill_damage, charge_state, skill_id)
					var hits := maxi(1, int(skill.get("hits", 1)))
					for _hit in range(hits):
						_damage_lowest_enemy(enemies, skill_damage, log, "skill")
					for _i in range(charge_sim.consume_repeats(charge_state, "attack", skill_id)):
						for _hit in range(hits):
							_damage_lowest_enemy(enemies, skill_damage, log, "skill_charge_repeat")
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
			used_first_skill = true
			action_points -= _first_skill_cost(player)

		while action_points > 0 and _alive_count(enemies) > 0:
			var attack_damage := int(status_service.resolve_stat(player, float(player["attack"]), StatusService.STAT_ATTACK)) + _state_bonus(player, "attack")
			attack_damage = charge_sim.apply_attack_modifiers(attack_damage, charge_state)
			_damage_lowest_enemy(enemies, attack_damage, log, "attack")
			for _i in range(charge_sim.consume_repeats(charge_state, "attack")):
				_damage_lowest_enemy(enemies, attack_damage, log, "attack_charge_repeat")
			action_points -= 1

		if _alive_count(enemies) == 0:
			break

		_clear_enemy_blocks(enemies)
		_clear_enemy_taunts(enemies)
		for enemy in enemies:
			if enemy["hp"] <= 0:
				continue
			status_service.fire_trigger(enemy, TriggerEvents.ON_TURN_START, {"battle_log": log, "session": null, "round_index": rounds})
		var actions := 0
		for enemy in enemies:
			if enemy["hp"] <= 0:
				continue
			if actions >= 2:
				_enemy_defend(enemy, 0.5)
				continue
			var action_result := _resolve_enemy_action(player, enemy, player_block, rounds, counter_state, log)
			player_block = int(action_result["block"])
			actions += 1
		for enemy in enemies:
			if enemy["hp"] <= 0:
				continue
			status_service.fire_trigger(enemy, TriggerEvents.ON_TURN_END, {"battle_log": log, "session": null, "round_index": rounds})

		_apply_end_round_traits(player, enemies, rounds)

	var victory: bool = int(player["hp"]) > 0 and _alive_count(enemies) == 0
	return {
		"victory": victory,
		"rounds": rounds,
		"first_strike": first_strike_done,
		"enemies_total": enemies.size(),
		"enemies_alive": _alive_count(enemies),
		"player_hp": int(player["hp"]),
		"log": log
	}


func _build_enemies(encounter: Dictionary, tower_floor: int) -> Array[Dictionary]:
	return CombatRules.build_enemies(encounter, tower_floor)


func scale_enemy(unit: Dictionary, tower_floor: int, rank: String, formation_scale: float = 1.0) -> Dictionary:
	return Combatant.scaled_enemy(unit, tower_floor, rank, formation_scale)


func _should_use_skill(player: Dictionary, used_first_skill: bool) -> bool:
	if player["equipped_skills"].is_empty():
		return false
	if not used_first_skill:
		return true
	return int(player.get("battle_skill_uses", 0)) % 2 == 0


func _skill_damage(player: Dictionary) -> int:
	var skill_id: String = player["equipped_skills"][0]
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	if skill.get("type", "") == "heal":
		var healed := maxi(1, int(round(float(player["max_hp"]) * (float(skill.get("heal_multiplier", 0.0)) + char_service.skill_multiplier_bonus(player, skill_id, "hp")))))
		player["hp"] = mini(int(player["max_hp"]), int(player["hp"]) + healed)
		return 0
	var multiplier := float(skill.get("multiplier", 1.0)) + char_service.skill_multiplier_bonus(player, skill_id, "attack")
	var base_attack: float = status_service.resolve_stat(player, float(player["attack"]), StatusService.STAT_ATTACK)
	return maxi(1, int(round(base_attack * multiplier)))


func _can_pay_first_skill(player: Dictionary, action_points: int) -> bool:
	return action_points >= _first_skill_cost(player)


func _first_skill_cost(player: Dictionary) -> int:
	var skill_id := _first_skill_id(player)
	if skill_id == "":
		return 999
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	return int(skill.get("cost", 2))


func _first_skill_id(player: Dictionary) -> String:
	if player["equipped_skills"].is_empty():
		return ""
	return String(player["equipped_skills"][0])


func _damage_lowest_enemy(enemies: Array[Dictionary], amount: int, log: Array[String], source: String) -> void:
	if amount <= 0:
		return
	var target_index := _active_taunt_target(enemies)
	var target_hp := 999999
	if target_index < 0:
		for i in range(enemies.size()):
			var enemy := enemies[i]
			if enemy["hp"] > 0 and enemy["hp"] < target_hp:
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


func _apply_damage_to_player(player: Dictionary, block: int, damage: int) -> Dictionary:
	var player_unit := Combatant.from_player(player, block, 0)
	var result := Combatant.apply_damage(player_unit, damage)
	var synced := Combatant.sync_to_player(player_unit, player)
	return {"block": int(synced["block"]), "hit": not bool(result["dodged"])}


func _apply_enemy_attack(player: Dictionary, enemy: Dictionary, enemy_index: int, block: int, log: Array[String], first_strike: bool, round_index: int, counter_state: Dictionary) -> Dictionary:
	var was_hit := false
	for damage in _enemy_attack_segments(enemy, round_index, first_strike):
		var result := _apply_damage_to_player(player, block, damage)
		block = int(result["block"])
		was_hit = was_hit or bool(result["hit"])
		log.append("enemy_attack:%s:%d" % [enemy["name"], damage])
	if was_hit:
		_trigger_counter_attack(player, enemy, enemy_index, log, counter_state)
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
	if abs(resolved_attack - base_attack) < 0.001:
		return segments
	var ratio := resolved_attack / maxf(1.0, base_attack)
	var result: Array[int] = []
	for damage in segments:
		result.append(maxi(1, int(round(float(damage) * ratio))))
	return result


func _incoming_damage(enemies: Array[Dictionary], round_index: int) -> int:
	var total := 0
	var actions := 0
	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		if actions >= 2:
			break
		var skill_id := enemy_rules.choose_skill(enemy, round_index)
		var skill: Dictionary = DataCatalog.SKILLS.get(skill_id, DataCatalog.INNATE_SKILLS.get(skill_id, {}))
		if skill.get("type", "") == "attack":
			if skill_id == "innate_attack":
				total += _enemy_round_damage(enemy, round_index)
			else:
				var hits := maxi(1, int(skill.get("hits", 1)))
				total += CombatRules.skill_attack_value_for_actor(enemy, skill_id) * hits
		actions += 1
	return total


func _apply_end_round_traits(player: Dictionary, enemies: Array[Dictionary], round_index: int) -> void:
	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		var traits: Array = enemy["traits"]
		if traits.has("curse") and round_index % 3 == 0:
			player["hp"] = maxi(0, int(player["hp"]) - 1)


func _resolve_enemy_action(player: Dictionary, enemy: Dictionary, player_block: int, round_index: int, counter_state: Dictionary, log: Array[String]) -> Dictionary:
	var skill_id := enemy_rules.choose_skill(enemy, round_index)
	return _execute_enemy_skill_in_sim(player, enemy, skill_id, player_block, round_index, counter_state, log)


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


func _enemy_intent(enemy: Dictionary, round_index: int) -> String:
	return enemy_rules.intent(enemy, round_index)


func _execute_enemy_skill_in_sim(player: Dictionary, enemy: Dictionary, skill_id: String, player_block: int, round_index: int, counter_state: Dictionary, log: Array[String]) -> Dictionary:
	var skill: Dictionary = DataCatalog.SKILLS.get(skill_id, DataCatalog.INNATE_SKILLS.get(skill_id, {}))
	if skill.is_empty():
		return {"block": player_block}
	var skill_type := String(skill.get("type", "attack"))
	match skill_type:
		"attack":
			if skill_id == "innate_attack":
				var result := _apply_enemy_attack(player, enemy, -1, player_block, log, false, round_index, counter_state)
				return {"block": int(result["block"])}
			var damage := CombatRules.skill_attack_value_for_actor(enemy, skill_id)
			var hits := maxi(1, int(skill.get("hits", 1)))
			var was_hit := false
			for _hit in range(hits):
				var result := _apply_damage_to_player(player, player_block, damage)
				player_block = int(result["block"])
				was_hit = was_hit or bool(result["hit"])
				log.append("enemy_skill:%s:%s:%d" % [skill_id, enemy["name"], damage])
			if was_hit:
				_trigger_counter_attack(player, enemy, -1, log, counter_state)
		"defense", "stance":
			enemy["block"] = int(enemy.get("block", 0)) + CombatRules.skill_defense_value_for_actor(enemy, skill_id)
			log.append("enemy_skill_defend:%s:%s" % [skill_id, enemy["name"]])
		"dodge":
			Combatant.add_dodge(enemy, int(skill.get("dodge_layers", 1)))
			log.append("enemy_skill_dodge:%s:%s" % [skill_id, enemy["name"]])
		"taunt":
			enemy["taunt"] = int(skill.get("taunt_duration", 1))
			Combatant.add_block(enemy, 1.0)
			log.append("enemy_skill_taunt:%s:%s" % [skill_id, enemy["name"]])
		"heal":
			var healed := CombatRules.skill_heal_value_for_actor(enemy, skill_id)
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