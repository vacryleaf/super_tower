extends RefCounted
class_name CombatEngine

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

const MAX_ROUNDS := 40


func run_battle(player: Dictionary, encounter: Dictionary, tower_floor: int, battle_index: int) -> Dictionary:
	var enemies := _build_enemies(encounter, tower_floor)
	var log: Array[String] = []
	var rounds := 0
	var player_armor := 0
	var used_first_skill := false
	var first_strike_done := false

	if _has_first_strike(enemies):
		first_strike_done = true
		_apply_enemy_attack(player, enemies[0], 0, log)

	while player["hp"] > 0 and _alive_count(enemies) > 0 and rounds < MAX_ROUNDS:
		rounds += 1
		player_armor = 0
		var action_points: int = mini(rounds, 3)
		var incoming := _incoming_damage(enemies, rounds)

		if incoming >= int(player["defense"]) and action_points > 0:
			player_armor += int(player["defense"]) + _state_bonus(player, "defense")
			action_points -= 1
			log.append("round_%d:defend" % rounds)

		if _should_use_skill(player, used_first_skill) and action_points > 0:
			var skill_damage := _skill_damage(player)
			_damage_lowest_enemy(enemies, skill_damage, log, "skill")
			used_first_skill = true
			action_points -= 1

		while action_points > 0 and _alive_count(enemies) > 0:
			var attack_damage := int(player["attack"]) + _state_bonus(player, "attack")
			_damage_lowest_enemy(enemies, attack_damage, log, "attack")
			action_points -= 1

		if _alive_count(enemies) == 0:
			break

		var attackers := 0
		for enemy in enemies:
			if enemy["hp"] <= 0:
				continue
			if attackers >= 2:
				if rounds % 2 == 0:
					enemy["armor"] += int(enemy["defense"])
				continue
			var damage := _enemy_round_damage(enemy, rounds)
			player_armor = _apply_damage_to_player(player, player_armor, damage)
			attackers += 1

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
		if unit.has("hp") and typeof(unit["hp"]) == TYPE_INT:
			enemies.append({
				"name": unit["name"],
				"rank": unit.get("rank", encounter.get("type", "normal")),
				"max_hp": int(unit["hp"]),
				"hp": int(unit["hp"]),
				"attack": int(unit["attack"]),
				"defense": int(unit["defense"]),
				"armor": int(unit["defense"]) if unit.get("traits", []).has("thick_skin") else 0,
				"traits": unit.get("traits", [])
			})
		else:
			var stats := scale_enemy(unit, tower_floor, unit.get("rank", encounter.get("type", "normal")), float(unit.get("formation_scale", 1.0)))
			enemies.append(stats)
	return enemies


func scale_enemy(unit: Dictionary, tower_floor: int, rank: String, formation_scale: float = 1.0) -> Dictionary:
	var growth: float = 1.0 + 0.08 * float(tower_floor - 1) + 0.25 * floor(float(tower_floor - 1) / 10.0)
	var base_hp := 24.0 + 5.0 * tower_floor
	var base_attack := 5.0 + 1.2 * tower_floor
	var base_defense := 2.0 + 0.6 * tower_floor
	var rank_hp := 1.0
	var rank_attack := 1.0
	var rank_defense := 1.0
	if rank == "elite":
		rank_hp = 2.4
		rank_attack = 1.35
		rank_defense = 1.5
	elif rank == "boss":
		rank_hp = 5.0
		rank_attack = 1.7
		rank_defense = 2.2

	var hp := maxi(1, int(round(base_hp * growth * float(unit.get("hp", 1.0)) * rank_hp * formation_scale)))
	var attack := maxi(1, int(round(base_attack * growth * float(unit.get("attack", 1.0)) * rank_attack * formation_scale)))
	var defense := maxi(0, int(round(base_defense * growth * float(unit.get("defense", 1.0)) * rank_defense * formation_scale)))
	var traits: Array = unit.get("traits", [])
	return {
		"name": unit.get("name", unit.get("id", "enemy")),
		"rank": rank,
		"max_hp": hp,
		"hp": hp,
		"attack": attack,
		"defense": defense,
		"armor": defense * 2 if traits.has("thick_skin") else 0,
		"traits": traits
	}


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
		player["hp"] = mini(int(player["max_hp"]), int(player["hp"]) + int(skill["power"]))
		return 0
	return int(player["attack"]) + int(skill.get("power", 0)) + int(player.get("skill_bonus", 0))


func _damage_lowest_enemy(enemies: Array[Dictionary], amount: int, log: Array[String], source: String) -> void:
	if amount <= 0:
		return
	var target_index := -1
	var target_hp := 999999
	for i in range(enemies.size()):
		var enemy := enemies[i]
		if enemy["hp"] > 0 and enemy["hp"] < target_hp:
			target_hp = enemy["hp"]
			target_index = i
	if target_index < 0:
		return
	var target := enemies[target_index]
	var remaining := amount
	if target["armor"] > 0:
		var absorbed: int = mini(int(target["armor"]), remaining)
		target["armor"] -= absorbed
		remaining -= absorbed
	if remaining > 0:
		target["hp"] = maxi(0, int(target["hp"]) - remaining)
	log.append("%s:%s:%d" % [source, target["name"], amount])


func _apply_damage_to_player(player: Dictionary, armor: int, damage: int) -> int:
	if armor > 0:
		var absorbed: int = mini(armor, damage)
		armor -= absorbed
		damage -= absorbed
	if damage > 0:
		player["hp"] = maxi(0, int(player["hp"]) - damage)
	return armor


func _apply_enemy_attack(player: Dictionary, enemy: Dictionary, armor: int, log: Array[String]) -> void:
	var damage := int(round(float(enemy["attack"]) * 0.75))
	_apply_damage_to_player(player, armor, damage)
	log.append("first_strike:%s:%d" % [enemy["name"], damage])


func _enemy_round_damage(enemy: Dictionary, round_index: int) -> int:
	var damage := int(enemy["attack"])
	var traits: Array = enemy["traits"]
	if traits.has("claw"):
		damage = int(round(float(damage) * 1.15))
	if traits.has("enrage") and int(enemy["hp"]) <= int(enemy["max_hp"]) * 0.4:
		damage = int(round(float(damage) * 1.30))
	if traits.has("swarm"):
		damage += maxi(1, int(round(float(enemy["attack"]) * 0.35)))
	if traits.has("summon") and round_index % 4 == 0:
		damage += maxi(1, int(round(float(enemy["attack"]) * 0.50)))
	return damage


func _incoming_damage(enemies: Array[Dictionary], round_index: int) -> int:
	var total := 0
	var attackers := 0
	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		if attackers >= 2:
			break
		total += _enemy_round_damage(enemy, round_index)
		attackers += 1
	return total


func _apply_end_round_traits(player: Dictionary, enemies: Array[Dictionary], round_index: int) -> void:
	for enemy in enemies:
		if enemy["hp"] <= 0:
			continue
		var traits: Array = enemy["traits"]
		if traits.has("revive") and round_index % 3 == 0:
			enemy["hp"] = mini(int(enemy["max_hp"]), int(enemy["hp"]) + maxi(1, int(round(float(enemy["max_hp"]) * 0.05))))
		if traits.has("fortify") and round_index % 2 == 0:
			enemy["armor"] += int(enemy["defense"])
		if traits.has("curse") and round_index % 3 == 0:
			player["hp"] = maxi(0, int(player["hp"]) - 1)


func _state_bonus(player: Dictionary, tag: String) -> int:
	if tag == "attack":
		return int(player.get("state_attack_bonus", 0))
	if tag == "defense":
		return int(player.get("state_defense_bonus", 0))
	return 0


func _has_first_strike(enemies: Array[Dictionary]) -> bool:
	for enemy in enemies:
		var traits: Array = enemy["traits"]
		if traits.has("first_strike"):
			return true
	return false


func _alive_count(enemies: Array[Dictionary]) -> int:
	var count := 0
	for enemy in enemies:
		if enemy["hp"] > 0:
			count += 1
	return count
