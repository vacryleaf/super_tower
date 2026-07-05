extends RefCounted
class_name CombatEngine

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const EnemyActionRules = preload("res://scripts/core/enemy_action_rules.gd")

const MAX_ROUNDS := 40

var enemy_rules := EnemyActionRules.new()


func run_battle(player: Dictionary, encounter: Dictionary, tower_floor: int, battle_index: int) -> Dictionary:
	var enemies := _build_enemies(encounter, tower_floor)
	var log: Array[String] = []
	var rounds := 0
	var player_block := 0
	var used_first_skill := false
	var first_strike_done := false
	var charge_state := _battle_charge_state(player)
	var counter_state := {"charges": 0, "multiplier": 1.0}

	if _has_first_strike(enemies):
		first_strike_done = true
		var first_result := _apply_enemy_attack(player, enemies[0], 0, player_block, log, true, -1, counter_state)
		player_block = int(first_result["block"])

	while player["hp"] > 0 and _alive_count(enemies) > 0 and rounds < MAX_ROUNDS:
		rounds += 1
		player_block = 0
		var action_points: int = mini(rounds, 3)
		_charge_one_for_round(charge_state)
		var incoming := _incoming_damage(enemies, rounds)

		var defend_value := int(player.get("block_power", player.get("defense", 1))) + _state_bonus(player, "defense")
		if defend_value >= 3 and incoming >= defend_value * 2 and action_points > 1:
			defend_value = _apply_charge_defense_value(defend_value, charge_state)
			player_block += defend_value
			for _i in range(_consume_charge_repeats(charge_state, "defense")):
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
					skill_damage = _apply_charge_attack_value(skill_damage, charge_state, skill_id)
					var hits := maxi(1, int(skill.get("hits", 1)))
					for _hit in range(hits):
						_damage_lowest_enemy(enemies, skill_damage, log, "skill")
					for _i in range(_consume_charge_repeats(charge_state, "attack", skill_id)):
						for _hit in range(hits):
							_damage_lowest_enemy(enemies, skill_damage, log, "skill_charge_repeat")
			elif skill_type == "defense" or skill_type == "stance":
				var block_gain := maxi(1, int(round(float(player.get("block_power", player.get("defense", 1))) * (float(skill.get("multiplier", skill.get("block_multiplier", 1.0))) + _skill_multiplier_bonus(player, skill_id, "defense")))))
				block_gain = _apply_charge_defense_value(block_gain, charge_state, skill_id)
				player_block += block_gain
				for _i in range(_consume_charge_repeats(charge_state, "defense", skill_id)):
					player_block += block_gain
				if skill_type == "stance":
					counter_state["charges"] = int(counter_state["charges"]) + 1
					counter_state["multiplier"] = maxf(float(counter_state["multiplier"]), float(skill.get("counter_multiplier", 1.0)) + _skill_multiplier_bonus(player, skill_id, "attack"))
			elif skill_type == "heal":
				_skill_damage(player)
			used_first_skill = true
			action_points -= _first_skill_cost(player)

		while action_points > 0 and _alive_count(enemies) > 0:
			var attack_damage := int(player["attack"]) + _state_bonus(player, "attack")
			attack_damage = _apply_charge_attack_value(attack_damage, charge_state)
			_damage_lowest_enemy(enemies, attack_damage, log, "attack")
			for _i in range(_consume_charge_repeats(charge_state, "attack")):
				_damage_lowest_enemy(enemies, attack_damage, log, "attack_charge_repeat")
			action_points -= 1

		if _alive_count(enemies) == 0:
			break

		_clear_enemy_blocks(enemies)
		_clear_enemy_taunts(enemies)
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
	var enemies: Array[Dictionary] = []
	for unit in encounter["units"]:
		enemies.append(Combatant.from_enemy_unit(unit, String(encounter.get("type", "normal")), tower_floor))
	return enemies


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
		var healed := maxi(1, int(round(float(player["max_hp"]) * (float(skill.get("heal_multiplier", 0.0)) + _skill_multiplier_bonus(player, skill_id, "hp")))))
		player["hp"] = mini(int(player["max_hp"]), int(player["hp"]) + healed)
		return 0
	var multiplier := float(skill.get("multiplier", 1.0)) + _skill_multiplier_bonus(player, skill_id, "attack")
	return maxi(1, int(round(float(player["attack"]) * multiplier)))


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
	return enemy_rules.attack_segments(enemy, round_index, first_strike)


func _incoming_damage(enemies: Array[Dictionary], round_index: int) -> int:
	var total := 0
	var actions := 0
	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		if actions >= 2:
			break
		if _enemy_intent(enemy, round_index) == "attack":
			total += _enemy_round_damage(enemy, round_index)
		actions += 1
	return total


func _apply_end_round_traits(player: Dictionary, enemies: Array[Dictionary], round_index: int) -> void:
	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		var traits: Array = enemy["traits"]
		if traits.has("revive") and round_index % 3 == 0:
			enemy["hp"] = mini(int(enemy["max_hp"]), int(enemy["hp"]) + maxi(1, int(round(float(enemy["max_hp"]) * 0.05))))
		if traits.has("fortify") and round_index % 2 == 0:
			Combatant.add_block(enemy, 1.0)
		if traits.has("curse") and round_index % 3 == 0:
			player["hp"] = maxi(0, int(player["hp"]) - 1)


func _resolve_enemy_action(player: Dictionary, enemy: Dictionary, player_block: int, round_index: int, counter_state: Dictionary, log: Array[String]) -> Dictionary:
	var intent := _enemy_intent(enemy, round_index)
	match intent:
		"taunt":
			enemy["taunt"] = 1
			_enemy_defend(enemy, 1.0)
		"defend":
			_enemy_defend(enemy, 1.0)
		"dodge":
			Combatant.add_dodge(enemy, 1)
		_:
			var result := _apply_enemy_attack(player, enemy, -1, player_block, log, false, round_index, counter_state)
			player_block = int(result["block"])
	return {"block": player_block}


func _trigger_counter_attack(player: Dictionary, enemy: Dictionary, enemy_index: int, log: Array[String], counter_state: Dictionary) -> void:
	if int(counter_state.get("charges", 0)) <= 0:
		return
	if int(enemy.get("hp", 0)) <= 0:
		return
	counter_state["charges"] = int(counter_state["charges"]) - 1
	var damage := maxi(1, int(round(float(player["attack"]) * float(counter_state.get("multiplier", 1.0)))))
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


func _clear_enemy_taunts(enemies: Array[Dictionary]) -> void:
	for enemy in enemies:
		Combatant.clear_taunt(enemy)


func _clear_enemy_blocks(enemies: Array[Dictionary]) -> void:
	for enemy in enemies:
		Combatant.clear_block(enemy)


func _active_taunt_target(enemies: Array[Dictionary]) -> int:
	for i in range(enemies.size()):
		if int(enemies[i]["hp"]) > 0 and int(enemies[i].get("taunt", 0)) > 0:
			return i
	return -1


func _state_bonus(player: Dictionary, tag: String) -> int:
	if tag == "attack":
		return int(player.get("state_attack_bonus", 0))
	if tag == "defense":
		return int(player.get("state_defense_bonus", 0))
	return 0


func _battle_charge_state(player: Dictionary) -> Dictionary:
	var state := {
		"attack_multiplier": 1.0,
		"defense_multiplier": 1.0,
		"bonus_damage": 0,
		"repeat_attack": 0,
		"repeat_defense": 0,
		"pool": [],
		"activated": [],
		"skills": {}
	}
	_collect_charge_pool(state["pool"], player.get("equipment_attachments", {}))
	_collect_charge_pool(state["pool"], player.get("skill_attachments", {}))
	return state


func _collect_charge_pool(pool: Array, groups: Dictionary) -> void:
	for attachments in groups.values():
		for attachment in attachments:
			if pool.size() >= 5:
				return
			var charge: Dictionary = attachment
			if String(charge.get("kind", "")).begins_with("charge_"):
				pool.append(charge)


func _charge_one_for_round(state: Dictionary) -> void:
	var pool: Array = state.get("pool", [])
	var activated: Array = state.get("activated", [])
	var candidates: Array[int] = []
	for i in range(pool.size()):
		if not activated.has(i):
			candidates.append(i)
	if candidates.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var selected_index := candidates[rng.randi_range(0, candidates.size() - 1)]
	activated.append(selected_index)
	state["activated"] = activated
	_apply_charged_effect(state, pool[selected_index])


func _apply_charged_effect(state: Dictionary, charge: Dictionary) -> void:
	var target_type := String(charge.get("target_type", ""))
	var target_id := String(charge.get("target_id", ""))
	var bucket := state
	if target_type == "skill" and target_id != "":
		var skills: Dictionary = state.get("skills", {})
		if not skills.has(target_id):
			skills[target_id] = {
				"attack_multiplier": 1.0,
				"defense_multiplier": 1.0,
				"bonus_damage": 0,
				"repeat_attack": 0,
				"repeat_defense": 0
			}
		state["skills"] = skills
		bucket = skills[target_id]
	match String(charge.get("kind", "")):
		"charge_attack_multiplier":
			bucket["attack_multiplier"] = float(bucket["attack_multiplier"]) * float(charge.get("value", 1.0))
		"charge_defense_multiplier":
			bucket["defense_multiplier"] = float(bucket["defense_multiplier"]) * float(charge.get("value", 1.0))
		"charge_bonus_damage":
			bucket["bonus_damage"] = int(bucket["bonus_damage"]) + int(charge.get("value", 0))
		"charge_repeat_attack":
			bucket["repeat_attack"] = int(bucket["repeat_attack"]) + maxi(1, int(charge.get("value", 1)))
		"charge_repeat_defense":
			bucket["repeat_defense"] = int(bucket["repeat_defense"]) + maxi(1, int(charge.get("value", 1)))


func _apply_charge_attack_value(base: int, state: Dictionary, skill_id: String = "") -> int:
	var effects := _merged_charge_state(state, skill_id)
	var result := int(round(float(base) * float(effects.get("attack_multiplier", 1.0)))) + int(effects.get("bonus_damage", 0))
	state["attack_multiplier"] = 1.0
	state["bonus_damage"] = 0
	if skill_id != "":
		var skills: Dictionary = state.get("skills", {})
		if skills.has(skill_id):
			skills[skill_id]["attack_multiplier"] = 1.0
			skills[skill_id]["bonus_damage"] = 0
	return maxi(1, result)


func _apply_charge_defense_value(base: int, state: Dictionary, skill_id: String = "") -> int:
	var effects := _merged_charge_state(state, skill_id)
	var result := int(round(float(base) * float(effects.get("defense_multiplier", 1.0))))
	state["defense_multiplier"] = 1.0
	if skill_id != "":
		var skills: Dictionary = state.get("skills", {})
		if skills.has(skill_id):
			skills[skill_id]["defense_multiplier"] = 1.0
	return maxi(1, result)


func _consume_charge_repeats(state: Dictionary, action_tag: String, skill_id: String = "") -> int:
	var key := "repeat_attack" if action_tag == "attack" else "repeat_defense"
	var repeats := int(state.get(key, 0))
	state[key] = 0
	if skill_id != "":
		var skills: Dictionary = state.get("skills", {})
		if skills.has(skill_id):
			repeats += int(skills[skill_id].get(key, 0))
			skills[skill_id][key] = 0
	return repeats


func _merged_charge_state(state: Dictionary, skill_id: String) -> Dictionary:
	var result := state.duplicate(true)
	if skill_id != "":
		var skills: Dictionary = state.get("skills", {})
		if skills.has(skill_id):
			var skill_effects: Dictionary = skills[skill_id]
			result["attack_multiplier"] = float(result.get("attack_multiplier", 1.0)) * float(skill_effects.get("attack_multiplier", 1.0))
			result["defense_multiplier"] = float(result.get("defense_multiplier", 1.0)) * float(skill_effects.get("defense_multiplier", 1.0))
			result["bonus_damage"] = int(result.get("bonus_damage", 0)) + int(skill_effects.get("bonus_damage", 0))
	return result


func _skill_attachment_bonus(player: Dictionary, skill_id: String, kind: String) -> int:
	var total := 0
	var attachments: Dictionary = player.get("skill_attachments", {})
	for attachment in attachments.get(skill_id, []):
		var attachment_kind := String(attachment.get("kind", ""))
		if (attachment_kind == kind) or (attachment_kind == "skill_power" and kind == "attack"):
			total += int(attachment.get("value", 0))
	return total


func _skill_multiplier_bonus(player: Dictionary, skill_id: String, kind: String = "") -> float:
	var total := 0.0
	var attachments: Dictionary = player.get("skill_attachments", {})
	for attachment in attachments.get(skill_id, []):
		var attachment_kind := String(attachment.get("kind", ""))
		if attachment_kind == "skill_power" or attachment_kind == kind:
			total += _attachment_multiplier_value(float(attachment.get("value", 0.0)))
	return total


func _attachment_multiplier_value(value: float) -> float:
	if absf(value) >= 1.0:
		return value * 0.05
	return value


func _has_first_strike(enemies: Array[Dictionary]) -> bool:
	return enemy_rules.has_first_strike(enemies)


func _alive_count(enemies: Array[Dictionary]) -> int:
	var count := 0
	for enemy in enemies:
		if enemy["hp"] > 0:
			count += 1
	return count
