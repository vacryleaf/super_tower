extends RefCounted
class_name EnemyActionRules


func intent(enemy: Dictionary, round_index: int) -> String:
	var traits: Array = enemy["traits"]
	if traits.has("taunt") and int(enemy.get("taunt", 0)) <= 0 and round_index % 3 == 1:
		return "taunt"
	if traits.has("tank") or traits.has("guard"):
		return "defend" if round_index % 2 == 0 else "attack"
	if traits.has("evade") and round_index % 3 == 0:
		return "dodge"
	if traits.has("fortify") and round_index % 2 == 0:
		return "defend"
	return "attack"


func intent_text(enemy: Dictionary, round_index: int) -> String:
	var traits: Array = enemy.get("traits", [])
	if traits.has("cunning"):
		return "狡诈"
	match intent(enemy, round_index):
		"taunt":
			return "嘲讽/防守"
		"defend":
			return "防守"
		"dodge":
			return "闪避"
	return "攻击"


func attack_segments(enemy: Dictionary, round_index: int, first_strike: bool) -> Array[int]:
	var base_damage := int(enemy["attack"])
	var traits: Array = enemy.get("traits", [])
	if traits.has("claw"):
		base_damage = int(round(float(base_damage) * 1.15))
	if traits.has("enrage") and int(enemy["hp"]) <= int(enemy["max_hp"]) * 0.4:
		base_damage = int(round(float(base_damage) * 1.30))
	if first_strike:
		base_damage = maxi(1, int(round(float(base_damage) * 0.75)))
	var segments: Array[int] = [maxi(1, base_damage)]
	if traits.has("swarm"):
		segments.append(maxi(1, int(round(float(enemy["attack"]) * 0.35))))
	if traits.has("summon") and round_index % 4 == 0:
		segments.append(maxi(1, int(round(float(enemy["attack"]) * 0.50))))
	return segments


func has_first_strike(enemies: Array[Dictionary]) -> bool:
	for enemy in enemies:
		var traits: Array = enemy["traits"]
		if traits.has("first_strike"):
			return true
	return false
