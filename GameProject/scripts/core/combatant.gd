extends RefCounted
class_name Combatant

const ARMOR_BASE := 30.0


static func from_player(player: Dictionary, current_block: int = 0, current_dodge: int = 0) -> Dictionary:
	var armor := maxi(0, int(player.get("defense", 0)))
	return {
		"id": String(player.get("class_id", "player")),
		"name": String(player.get("name", player.get("class_id", "玩家"))),
		"side": "player",
		"rank": "player",
		"max_hp": int(player.get("max_hp", 1)),
		"hp": int(player.get("hp", 1)),
		"attack": int(player.get("attack", 1)),
		"defense": armor,
		"armor": armor,
		"block_power": maxi(1, int(player.get("block_power", player.get("defense", 1)))),
		"block": maxi(0, current_block),
		"dodge_layers": maxi(0, current_dodge),
		"taunt": 0,
		"traits": player.get("traits", [])
	}


static func sync_to_player(combatant: Dictionary, player: Dictionary) -> Dictionary:
	player["hp"] = maxi(0, int(combatant.get("hp", player.get("hp", 0))))
	return {
		"block": maxi(0, int(combatant.get("block", 0))),
		"dodge_layers": maxi(0, int(combatant.get("dodge_layers", 0)))
	}


static func from_enemy_unit(unit: Dictionary, encounter_type: String, tower_floor: int) -> Dictionary:
	var rank := String(unit.get("rank", encounter_type))
	var traits: Array = unit.get("traits", [])
	if unit.has("hp") and typeof(unit["hp"]) == TYPE_INT:
		var fixed_defense := int(unit.get("defense", 0))
		return _enemy_dictionary(
			String(unit.get("name", unit.get("id", "enemy"))),
			rank,
			int(unit.get("hp", 1)),
			int(unit.get("attack", 1)),
			fixed_defense,
			_enemy_base_armor(unit, fixed_defense, traits),
			traits
		)
	return scaled_enemy(unit, tower_floor, rank, float(unit.get("formation_scale", 1.0)))


static func scaled_enemy(unit: Dictionary, tower_floor: int, rank: String, formation_scale: float = 1.0) -> Dictionary:
	var post_gate := maxi(0, tower_floor - 5)
	var growth: float = 1.0 \
		+ 0.08 * float(tower_floor - 1) \
		+ 0.45 * float(post_gate) \
		+ 0.15 * float(post_gate * post_gate) \
		+ 0.25 * floor(float(tower_floor - 1) / 10.0)
	var base_hp := 22.0 + 4.6 * tower_floor
	var base_attack := 4.2 + 1.0 * tower_floor
	var base_defense := 1.6 + 0.5 * tower_floor
	var rank_hp := 1.0
	var rank_attack := 1.0
	var rank_defense := 1.0
	if rank == "elite":
		rank_hp = 2.0
		rank_attack = 1.2
		rank_defense = 1.3
	elif rank == "boss":
		rank_hp = 3.4
		rank_attack = 1.4
		rank_defense = 1.8

	var hp := maxi(1, int(round(base_hp * growth * float(unit.get("hp", 1.0)) * rank_hp * formation_scale)))
	var attack := maxi(1, int(round(base_attack * growth * float(unit.get("attack", 1.0)) * rank_attack * formation_scale)))
	var defense := maxi(0, int(round(base_defense * growth * float(unit.get("defense", 1.0)) * rank_defense * formation_scale)))
	var traits: Array = unit.get("traits", [])
	return _enemy_dictionary(
		String(unit.get("name", unit.get("id", "enemy"))),
		rank,
		hp,
		attack,
		defense,
		_enemy_base_armor(unit, defense, traits),
		traits
	)


static func add_block(combatant: Dictionary, scale: float = 1.0) -> int:
	var gained := maxi(1, int(round(float(combatant.get("block_power", combatant.get("defense", 1))) * scale)))
	combatant["block"] = int(combatant.get("block", 0)) + gained
	return gained


static func add_dodge(combatant: Dictionary, layers: int = 1) -> int:
	var gained := maxi(1, layers)
	combatant["dodge_layers"] = int(combatant.get("dodge_layers", 0)) + gained
	return gained


static func clear_block(combatant: Dictionary) -> void:
	combatant["block"] = 0


static func clear_taunt(combatant: Dictionary) -> void:
	combatant["taunt"] = 0


static func is_alive(combatant: Dictionary) -> bool:
	return int(combatant.get("hp", 0)) > 0


static func apply_damage(combatant: Dictionary, raw_damage: int) -> Dictionary:
	var result := {
		"dodged": false,
		"raw_damage": maxi(0, raw_damage),
		"armor_reduced": 0,
		"block_absorbed": 0,
		"damage": 0
	}
	if raw_damage <= 0:
		return result
	if int(combatant.get("dodge_layers", 0)) > 0:
		combatant["dodge_layers"] = int(combatant.get("dodge_layers", 0)) - 1
		result["dodged"] = true
		return result

	var after_armor := damage_after_armor(combatant, raw_damage)
	result["armor_reduced"] = maxi(0, raw_damage - after_armor)
	var remaining := after_armor
	if int(combatant.get("block", 0)) > 0:
		var absorbed: int = mini(int(combatant.get("block", 0)), remaining)
		combatant["block"] = int(combatant.get("block", 0)) - absorbed
		remaining -= absorbed
		result["block_absorbed"] = absorbed
	if remaining > 0:
		combatant["hp"] = maxi(0, int(combatant.get("hp", 0)) - remaining)
	result["damage"] = remaining
	return result


static func damage_after_armor(combatant: Dictionary, raw_damage: int) -> int:
	if raw_damage <= 0:
		return 0
	var armor := maxi(0, int(combatant.get("armor", combatant.get("defense", 0))))
	return maxi(1, int(ceil(float(raw_damage) * ARMOR_BASE / float(ARMOR_BASE + armor))))


static func normalize_enemy(enemy: Dictionary) -> void:
	var traits: Array = enemy.get("traits", [])
	var defense := int(enemy.get("defense", 0))
	if not enemy.has("side"):
		enemy["side"] = "enemy"
	if not enemy.has("block_power"):
		enemy["block_power"] = maxi(1, defense)
	if not enemy.has("block"):
		enemy["block"] = 0
	if not enemy.has("dodge_layers"):
		enemy["dodge_layers"] = 0
	if not enemy.has("taunt"):
		enemy["taunt"] = 0
	if traits.has("thick_skin") and int(enemy.get("armor", 0)) <= 0:
		enemy["armor"] = maxi(1, defense)
	elif not enemy.has("armor"):
		enemy["armor"] = 0


static func _enemy_dictionary(unit_name: String, rank: String, hp: int, attack: int, defense: int, armor: int, traits: Array) -> Dictionary:
	return {
		"name": unit_name,
		"side": "enemy",
		"rank": rank,
		"max_hp": hp,
		"hp": hp,
		"attack": attack,
		"defense": defense,
		"armor": armor,
		"block_power": maxi(1, defense),
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": traits
	}


static func _enemy_base_armor(unit: Dictionary, defense: int, traits: Array) -> int:
	var armor := int(unit.get("armor", 0))
	if traits.has("thick_skin"):
		armor += maxi(1, defense)
	return armor
