extends RefCounted
class_name Combatant

const TriggerEvents = preload("res://scripts/core/trigger_events.gd")
const ARMOR_BASE := 30.0
const DamageType = preload("res://scripts/core/damage_type.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const TraitCatalog = preload("res://scripts/core/trait_catalog.gd")
const DEFAULT_ENEMY_AGILITY := 9


static func from_player(player: Dictionary, current_block: int = 0, current_dodge: int = 0, status_service = null) -> Dictionary:
	var base_armor := int(player.get("defense", 0))
	var armor := base_armor
	if status_service:
		armor = int(round(status_service.resolve_stat(player, float(base_armor), StatusService.STAT_ARMOR)))
	return {
		"id": String(player.get("class_id", "player")),
		"name": String(player.get("name", player.get("class_id", "玩家"))),
		"side": "player",
		"rank": "player",
		"max_hp": int(player.get("max_hp", 1)),
		"hp": int(player.get("hp", 1)),
		"attack": int(player.get("attack", 1)),
		"agility": int(player.get("agility", 0)),
		"extra_hits": int(player.get("extra_hits", 0)),
		"critical_weight": int(player.get("critical_weight", 0)),
		"critical_damage_bonus": float(player.get("critical_damage_bonus", 0.0)),
		"weapon_skill_1": String(player.get("weapon_skill_1", "")),
		"weapon_skill_2": String(player.get("weapon_skill_2", "")),
		"defense": armor,
		"armor": armor,
		"block_power": maxi(1, int(player.get("block_power", player.get("defense", 1)))),
		"block": maxi(0, current_block),
		"dodge_layers": maxi(0, current_dodge),
		"taunt": 0,
		"passive_skills": passive_skill_slots(player.get("passive_skills", []) + player.get("tower_passive_skills", [])),
		"energy": int(player.get("energy", 0)),
		"skill_cooldowns": player.get("skill_cooldowns", {}).duplicate(),
		"controlled_by": "player"
	}


static func sync_to_player(combatant: Dictionary, player: Dictionary) -> Dictionary:
	player["hp"] = maxi(0, int(combatant.get("hp", player.get("hp", 0))))
	return {
		"block": maxi(0, int(combatant.get("block", 0))),
		"dodge_layers": maxi(0, int(combatant.get("dodge_layers", 0)))
	}


static func from_enemy_unit(unit: Dictionary, encounter_type: String, tower_floor: int) -> Dictionary:
	var rank := String(unit.get("rank", encounter_type))
	var passive_skills := passive_skill_slots(unit.get("passive_skills", unit.get("traits", [])))
	var skills: Array = unit.get("skills", [])
	if bool(unit.get("fixed_stats", false)):
		return fixed_enemy(unit, tower_floor, rank, passive_skills, skills)
	if unit.has("hp") and typeof(unit["hp"]) == TYPE_INT:
		# 直接定义属性的群落单位仍要应用遭遇战压力（如第 4-9 场），
		# 否则 formation_scale 只对浮点基础单位生效，导致后半段威胁曲线失真。
		var formation_scale := maxf(0.0, float(unit.get("formation_scale", 1.0)))
		var fixed_hp := maxi(1, int(round(float(unit.get("hp", 1)) * formation_scale)))
		var fixed_attack := maxi(1, int(round(float(unit.get("attack", 1)) * formation_scale)))
		var fixed_defense := maxi(0, int(round(float(unit.get("defense", 0)) * formation_scale)))
		var fixed_block_power := maxi(0, int(round(float(unit.get("block_power", fixed_defense)) * formation_scale)))
		var fixed_armor := maxi(0, int(round(float(_enemy_base_armor(unit, int(unit.get("defense", 0)), passive_skills)) * formation_scale)))
		var fixed_agility := maxi(1, int(unit.get("agility", DEFAULT_ENEMY_AGILITY)))
		return _enemy_dictionary(
			String(unit.get("name", unit.get("id", "enemy"))),
			rank,
			fixed_hp,
			fixed_attack,
			fixed_defense,
			fixed_armor,
			passive_skills,
			skills,
			fixed_block_power,
			unit.get("behavior_weights", {}),
			fixed_agility
		)
	return scaled_enemy(unit, tower_floor, rank, float(unit.get("formation_scale", 1.0)))


static func scaled_enemy(unit: Dictionary, tower_floor: int, rank: String, formation_scale: float = 1.0) -> Dictionary:
	var post_gate := maxi(0, tower_floor - 5)
	var growth: float = 1.0 \
		+ 0.10 * float(tower_floor - 1) \
		+ 0.52 * float(post_gate) \
		+ 0.18 * float(post_gate * post_gate) \
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
	var passive_skills := passive_skill_slots(unit.get("passive_skills", unit.get("traits", [])))
	var skills: Array = unit.get("skills", [])
	var agility := maxi(1, int(unit.get("agility", DEFAULT_ENEMY_AGILITY)))
	return _enemy_dictionary(
		String(unit.get("name", unit.get("id", "enemy"))),
		rank,
		hp,
		attack,
		defense,
		_enemy_base_armor(unit, defense, passive_skills),
		passive_skills,
		skills,
		int(unit.get("block_power", defense)),
		unit.get("behavior_weights", {}),
		agility
	)


static func fixed_enemy(unit: Dictionary, tower_floor: int, rank: String, passive_skills: Array, skills: Array) -> Dictionary:
	var floor_multiplier := pow(1.3, tower_floor - 1)
	var rank_multiplier := 1.5 if rank == "elite" else 1.0
	var hp := maxi(1, int(ceil(float(unit.get("hp", 1)) * floor_multiplier * rank_multiplier)))
	var attack := maxi(1, int(ceil(float(unit.get("attack", 1)) * floor_multiplier * rank_multiplier)))
	var defense := int(ceil(float(unit.get("defense", 0)) * floor_multiplier * rank_multiplier))
	var block_power := maxi(0, int(ceil(float(unit.get("block_power", defense)) * floor_multiplier * rank_multiplier)))
	var agility := maxi(1, int(unit.get("agility", DEFAULT_ENEMY_AGILITY)))
	var enemy := _enemy_dictionary(
		String(unit.get("name", unit.get("id", "enemy"))),
		rank,
		hp,
		attack,
		defense,
		_enemy_base_armor(unit, defense, passive_skills),
		passive_skills,
		skills,
		block_power,
		unit.get("behavior_weights", {}),
		agility
	)
	enemy["fixed_stats"] = true
	return enemy


static func add_block(combatant: Dictionary, scale: float = 1.0) -> int:
	var gained := maxi(0, int(round(float(combatant.get("block_power", combatant.get("defense", 1))) * scale)))
	combatant["block"] = int(combatant.get("block", 0)) + gained
	return gained


static func add_block_amount(combatant: Dictionary, amount: int) -> int:
	var gained := maxi(0, amount)
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


static func are_hostile(a: Dictionary, b: Dictionary) -> bool:
	return String(a.get("side", "")) != String(b.get("side", ""))


static func apply_damage(combatant: Dictionary, raw_damage: int, damage_type: String = "physical", armor_multiplier: float = 1.0, allow_dodge: bool = true) -> Dictionary:
	var result := {
		"dodged": false,
		"raw_damage": maxi(0, raw_damage),
		"damage_before_block": 0,
		"armor_reduced": 0,
		"block_before": int(combatant.get("block", 0)),
		"block_absorbed": 0,
		"block_after": int(combatant.get("block", 0)),
		"block_broken": false,
		"damage": 0
	}
	if raw_damage <= 0:
		return result
	if allow_dodge and int(combatant.get("dodge_layers", 0)) > 0:
		combatant["dodge_layers"] = int(combatant.get("dodge_layers", 0)) - 1
		result["dodged"] = true
		return result

	var after_armor := raw_damage
	if damage_type != DamageType.TRUE:
		after_armor = damage_after_armor(combatant, raw_damage, armor_multiplier)
	result["armor_reduced"] = maxi(0, raw_damage - after_armor)
	result["damage_before_block"] = after_armor
	var remaining := after_armor
	if int(combatant.get("block", 0)) > 0:
		var absorbed: int = mini(int(combatant.get("block", 0)), remaining)
		combatant["block"] = int(combatant.get("block", 0)) - absorbed
		remaining -= absorbed
		result["block_absorbed"] = absorbed
		result["block_after"] = int(combatant.get("block", 0))
		result["block_broken"] = int(result["block_before"]) > 0 and int(result["block_after"]) <= 0
	if remaining > 0:
		combatant["hp"] = maxi(0, int(combatant.get("hp", 0)) - remaining)
	result["damage"] = remaining
	return result


static func damage_after_armor(combatant: Dictionary, raw_damage: int, armor_multiplier: float = 1.0) -> int:
	if raw_damage <= 0:
		return 0
	var armor := int(combatant.get("armor", combatant.get("defense", 0)))
	armor = int(ceil(float(armor) * armor_multiplier))
	return maxi(1, int(ceil(float(raw_damage) * ARMOR_BASE / maxf(1.0, ARMOR_BASE + float(armor)))))


static func normalize_enemy(enemy: Dictionary) -> void:
	if not enemy.has("passive_skills"):
		enemy["passive_skills"] = enemy.get("traits", [])
	enemy["passive_skills"] = passive_skill_slots(enemy["passive_skills"])
	enemy.erase("traits")
	var passive_skills: Array = enemy["passive_skills"]
	var defense := int(enemy.get("defense", 0))
	if not enemy.has("side"):
		enemy["side"] = "enemy"
	if not enemy.has("agility"):
		enemy["agility"] = DEFAULT_ENEMY_AGILITY
	if not enemy.has("block_power"):
		enemy["block_power"] = maxi(1, defense)
	if not enemy.has("block"):
		enemy["block"] = 0
	if not enemy.has("dodge_layers"):
		enemy["dodge_layers"] = 0
	if not enemy.has("taunt"):
		enemy["taunt"] = 0
	var base_armor_effect := TraitCatalog.base_stat_effect("thick_skin")
	if not base_armor_effect.is_empty() and int(enemy.get("armor", 0)) <= 0:
		enemy["armor"] = maxi(1, int(ceil(float(defense) * float(base_armor_effect.get("value", 1.0)))))
	elif not enemy.has("armor"):
		enemy["armor"] = 0
	if not enemy.has("skills"):
		enemy["skills"] = []
	if not enemy.has("skill_cooldowns"):
		enemy["skill_cooldowns"] = {}
	if not enemy.has("behavior_weights"):
		enemy["behavior_weights"] = {}
	if not enemy.has("available_round"):
		enemy["available_round"] = 0
	if not enemy.has("shadow_armor_active"):
		enemy["shadow_armor_active"] = false
	if not enemy.has("innate_skills"):
		enemy["innate_skills"] = {
			"attack_1": "innate_attack_1",
			"defend": "innate_defend",
			"dodge": "innate_dodge"
		}
	if not enemy.has("statuses"):
		enemy["statuses"] = []
	if not enemy.has("controlled_by"):
		enemy["controlled_by"] = "ai"
	_apply_trait_statuses(enemy)


static func _apply_trait_statuses(enemy: Dictionary) -> void:
	var passive_skills := passive_skill_slots(enemy.get("passive_skills", enemy.get("traits", [])))
	var statuses: Array = enemy.get("statuses", [])
	for status_index in range(statuses.size() - 1, -1, -1):
		if String(statuses[status_index].get("id", "")).begins_with("trait_"):
			statuses.remove_at(status_index)
	for trait_id in passive_skills:
		var definition := TraitCatalog.status_definition(String(trait_id))
		if definition.is_empty():
			continue
		statuses.append(definition)

	enemy["statuses"] = statuses


static func _enemy_dictionary(unit_name: String, rank: String, hp: int, attack: int, defense: int, armor: int, passive_skills: Array, skills: Array = [], block_power: int = -1, behavior_weights: Dictionary = {}, agility: int = DEFAULT_ENEMY_AGILITY) -> Dictionary:
	var enemy := {
		"name": unit_name,
		"side": "enemy",
		"rank": rank,
		"max_hp": hp,
		"hp": hp,
		"attack": attack,
		"agility": maxi(1, agility),
		"defense": defense,
		"armor": armor,
		"block_power": maxi(0, defense if block_power < 0 else block_power),
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"passive_skills": passive_skill_slots(passive_skills),
		"skills": skills.duplicate(),
		"skill_cooldowns": {},
		"behavior_weights": behavior_weights.duplicate(),
		"available_round": 0,
		"shadow_armor_active": false,
		"innate_skills": {
			"attack_1": "innate_attack_1",
			"defend": "innate_defend",
			"dodge": "innate_dodge"
		},
		"statuses": [],
		"controlled_by": "ai"
	}
	_apply_trait_statuses(enemy)
	return enemy


static func _enemy_base_armor(unit: Dictionary, defense: int, passive_skills: Array) -> int:
	var armor := int(unit.get("armor", defense))
	if passive_skills.has("thick_skin"):
		armor = maxi(1, int(ceil(float(armor) * 1.20)))
	return armor


static func rat_minion(tower_floor: int, available_round: int) -> Dictionary:
	var unit := {
		"name": "小鼠",
		"fixed_stats": true,
		"hp": 20,
		"attack": 5,
		"defense": 0,
		"block_power": 0,
		"passive_skills": ["swarm", "", "", ""],
		"skills": [],
		"behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10}
	}
	var minion := from_enemy_unit(unit, "normal", tower_floor)
	minion["available_round"] = available_round
	return minion


static func passive_skill_slots(source_skills: Array) -> Array[String]:
	var slots: Array[String] = []
	for skill_id in source_skills:
		if slots.size() >= 4:
			break
		slots.append(String(skill_id))
	while slots.size() < 4:
		slots.append("")
	return slots
