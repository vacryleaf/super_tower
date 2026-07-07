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


func choose_skill(enemy: Dictionary, round_index: int) -> String:
	var skills: Array = enemy.get("skills", [])
	var innate: Dictionary = enemy.get("innate_skills", {})
	var traits: Array = enemy["traits"]
	var hp_percent: float = float(enemy["hp"]) / float(maxi(1, enemy["max_hp"]))

	# 1. Taunt: has taunt trait, taunt not active, every 3rd+1 round
	if traits.has("taunt") and int(enemy.get("taunt", 0)) <= 0 and round_index % 3 == 1:
		if skills.has("enemy_taunt"):
			return "enemy_taunt"

	# 2. Low HP: prefer defense/dodge from special skills
	if hp_percent < 0.35:
		var defense_skills := _filter_by_type(skills, "defense")
		if not defense_skills.is_empty():
			return defense_skills[0]
		var dodge_skills := _filter_by_type(skills, "dodge")
		if not dodge_skills.is_empty():
			return dodge_skills[0]
		return innate.get("defend", "innate_defend")

	# 3. Tank/guard: defend on even rounds
	if (traits.has("tank") or traits.has("guard")) and round_index % 2 == 0:
		var defense_skills := _filter_by_type(skills, "defense")
		if not defense_skills.is_empty():
			return defense_skills[0]
		return innate.get("defend", "innate_defend")

	# 4. Evade: dodge every 3rd round
	if traits.has("evade") and round_index % 3 == 0:
		var dodge_skills := _filter_by_type(skills, "dodge")
		if not dodge_skills.is_empty():
			return dodge_skills[0]
		return innate.get("dodge", "innate_dodge")

	# 5. Fortify: defend on even rounds
	if traits.has("fortify") and round_index % 2 == 0:
		var defense_skills := _filter_by_type(skills, "defense")
		if not defense_skills.is_empty():
			return defense_skills[0]
		return innate.get("defend", "innate_defend")

	# 6. Default: prefer special attack skills, cycle through them
	var attack_skills := _filter_by_type(skills, "attack")
	if not attack_skills.is_empty():
		return attack_skills[round_index % attack_skills.size()]

	# 7. No attack skills: cycle through non-taunt special skills
	var non_taunt: Array[String] = []
	for skill_id in skills:
		if skill_id != "enemy_taunt":
			non_taunt.append(skill_id)
	if not non_taunt.is_empty():
		return non_taunt[round_index % non_taunt.size()]

	# 8. Fallback: innate attack
	return innate.get("attack", "innate_attack")


func _filter_by_type(skills: Array, skill_type: String) -> Array[String]:
	var DataCatalog = preload("res://scripts/core/data_catalog.gd")
	var result: Array[String] = []
	for skill_id in skills:
		var skill_data: Dictionary = DataCatalog.SKILLS.get(skill_id, {})
		if String(skill_data.get("type", "")) == skill_type:
			result.append(skill_id)
	return result
