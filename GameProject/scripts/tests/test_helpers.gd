extends RefCounted

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const CombatEngine = preload("res://scripts/core/combat_engine.gd")


static func test_enemy(enemy_name: String, hp: int, attack: int, traits: Array) -> Dictionary:
	return {
		"name": enemy_name,
		"rank": "normal",
		"max_hp": hp,
		"hp": hp,
		"attack": attack,
		"defense": 0,
		"armor": 0,
		"block_power": 1,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": traits
	}


static func force_win(session) -> void:
	for enemy in session.enemies:
		enemy["hp"] = 0
	session._on_victory()


static func encounter_threat(combat: CombatEngine, encounter: Dictionary, tower_floor: int) -> float:
	var total := 0.0
	for enemy in combat._build_enemies(encounter, tower_floor):
		total += float(enemy["max_hp"]) + float(enemy["attack"]) * 5.0 + float(enemy["defense"]) * 2.5 + float(enemy["armor"]) + float(enemy.get("block_power", 0))
	return total


static func failed_battle(result: Dictionary) -> int:
	var summaries: Array = result.get("floor_summaries", [])
	if summaries.is_empty():
		return 0
	var last: Dictionary = summaries[summaries.size() - 1]
	return int(last.get("battle", 0))


static func has_no_duplicates(values: Array) -> bool:
	var seen := {}
	for value in values:
		if seen.has(value):
			return false
		seen[value] = true
	return true


static func dictionary_total(groups: Dictionary) -> int:
	var total := 0
	for values in groups.values():
		total += values.size()
	return total


static func has_core_growth_reward(rewards: Array[Dictionary]) -> bool:
	for reward in rewards:
		if ["attack", "defense", "hp"].has(String(reward.get("kind", ""))):
			return true
	return false