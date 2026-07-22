extends RefCounted
class_name EnemyActionRules


func intent(enemy: Dictionary, round_index: int, player_context: Dictionary = {}, is_alone: bool = false) -> String:
	var passive_skills: Array = enemy.get("passive_skills", enemy.get("traits", []))
	if passive_skills.has("tutorial_evade"):
		return "dodge" if round_index % 2 == 1 else "attack"
	if passive_skills.has("tutorial_ramp"):
		return "defend" if round_index % 2 == 1 else "attack"
	if is_alone:
		return "attack"
	if passive_skills.has("taunt") and int(enemy.get("taunt", 0)) <= 0 and round_index % 3 == 1:
		return "taunt"
	if passive_skills.has("tank") or passive_skills.has("guard"):
		return "defend" if round_index % 2 == 0 else "attack"
	if passive_skills.has("evade") and round_index % 3 == 0:
		return "dodge"
	if passive_skills.has("fortify") and round_index % 2 == 0:
		return "defend"
	# 充能状态激活时优先使用攻击技能
	if passive_skills.has("charge") and _has_status(enemy, "charged_up"):
		return "charge"
	# 响应式：根据玩家状态调整意图
	if not player_context.is_empty():
		var player_hp_percent: float = float(player_context.get("hp", 1)) / float(maxi(1, player_context.get("max_hp", 1)))
		var player_block: int = int(player_context.get("block", 0))
		var player_block_power: int = maxi(1, int(player_context.get("block_power", 1)))
		var player_dodge: int = int(player_context.get("dodge_layers", 0))
		if player_hp_percent < 0.30:
			return "attack"
		if player_dodge > 0 or player_block > int(round(float(player_block_power) * 1.5)):
			return "attack"
		if float(enemy.get("hp", 1)) / float(maxi(1, enemy.get("max_hp", 1))) < 0.25:
			return "defend"
	# 辅助特性：奇数回合防守以持续辅助友军
	if passive_skills.has("support"):
		# 与 choose_skill 一致：奇数回合防守，偶数回合攻击
		return "defend" if round_index % 2 == 1 else "attack"
	return "attack"


func intent_text(enemy: Dictionary, round_index: int) -> String:
	var passive_skills: Array = enemy.get("passive_skills", enemy.get("traits", []))
	if passive_skills.has("cunning"):
		return "狡诈"
	match intent(enemy, round_index):
		"taunt":
			return "嘲讽/防守"
		"defend":
			return "防守"
		"dodge":
			return "闪避"
		"charge":
			return "充能攻击"
	return "攻击"


func attack_segments(enemy: Dictionary, round_index: int, first_strike: bool) -> Array[int]:
	var base_damage := int(enemy["attack"])
	if first_strike:
		base_damage = maxi(1, int(round(float(base_damage) * 0.75)))
	return [maxi(1, base_damage)]


func has_first_strike(enemies: Array[Dictionary]) -> bool:
	for enemy in enemies:
		var passive_skills: Array = enemy.get("passive_skills", enemy.get("traits", []))
		if passive_skills.has("first_strike"):
			return true
	return false


func choose_skill(enemy: Dictionary, round_index: int, player_context: Dictionary = {}, is_alone: bool = false, rng: RandomNumberGenerator = null) -> String:
	var skills: Array = enemy.get("skills", [])
	var innate: Dictionary = enemy.get("innate_skills", {})
	var passive_skills: Array = enemy.get("passive_skills", enemy.get("traits", []))
	var hp_percent: float = float(enemy["hp"]) / float(maxi(1, enemy["max_hp"]))
	var behavior_weights: Dictionary = enemy.get("behavior_weights", {})
	if not behavior_weights.is_empty():
		return _choose_weighted_action(enemy, behavior_weights, innate, rng, is_alone)

	if passive_skills.has("tutorial_ramp"):
		if round_index % 2 == 0:
			var ramp_attack := _filter_multi_hit(skills)
			if not ramp_attack.is_empty():
				return ramp_attack[0]
			var fallback_attack := _filter_by_type(skills, "attack")
			if not fallback_attack.is_empty():
				return fallback_attack[0]
			return innate.get("attack_1", "innate_attack_1")
		var ramp_defense := _filter_by_type(skills, "defense")
		if not ramp_defense.is_empty():
			return ramp_defense[0]
		return innate.get("defend", "innate_defend")

	if passive_skills.has("tutorial_evade"):
		if round_index % 2 == 0:
			var heavy_skills := _filter_by_type(skills, "attack")
			if not heavy_skills.is_empty():
				return heavy_skills[0]
			return innate.get("attack_1", "innate_attack_1")
		var evade_skills := _filter_by_type(skills, "dodge")
		if not evade_skills.is_empty():
			return evade_skills[0]
		return innate.get("dodge", "innate_dodge")

	# 0. 只剩自己一个时，不再防御或闪避，只攻击
	if is_alone:
		var attack_skills := _filter_by_type(skills, "attack")
		if not attack_skills.is_empty():
			return attack_skills[round_index % attack_skills.size()]
		return innate.get("attack_1", "innate_attack_1")

	# 1. Taunt: has taunt trait, taunt not active, every 3rd+1 round
	if passive_skills.has("taunt") and int(enemy.get("taunt", 0)) <= 0 and round_index % 3 == 1:
		if skills.has("enemy_taunt"):
			return "enemy_taunt"

	# 2. Charge: when charged up, prefer attack skills
	# 充能状态激活时优先使用攻击技能
	if passive_skills.has("charge") and _has_status(enemy, "charged_up"):
		var attack_skills_charge := _filter_by_type(skills, "attack")
		if not attack_skills_charge.is_empty():
			return attack_skills_charge[round_index % attack_skills_charge.size()]
		return innate.get("attack_1", "innate_attack_1")

	# 3. 响应式规则：根据玩家状态调整策略
	if not player_context.is_empty():
		var player_hp_percent: float = float(player_context.get("hp", 1)) / float(maxi(1, player_context.get("max_hp", 1)))
		var player_block: int = int(player_context.get("block", 0))
		var player_block_power: int = maxi(1, int(player_context.get("block_power", 1)))
		var player_dodge: int = int(player_context.get("dodge_layers", 0))
		# 3a. 玩家 HP < 30%：激进攻击
		if player_hp_percent < 0.30:
			var attack_skills_aggro := _filter_by_type(skills, "attack")
			if not attack_skills_aggro.is_empty():
				return attack_skills_aggro[round_index % attack_skills_aggro.size()]
			return innate.get("attack_1", "innate_attack_1")
		# 3b. 玩家有闪避层数：优先多段攻击破闪避
		if player_dodge > 0:
			var multi_hit_dodge := _filter_multi_hit(skills)
			if not multi_hit_dodge.is_empty():
				return multi_hit_dodge[round_index % multi_hit_dodge.size()]
		# 3c. 玩家格挡高：优先多段攻击破格挡
		if player_block > int(round(float(player_block_power) * 1.5)):
			var multi_hit_block := _filter_multi_hit(skills)
			if not multi_hit_block.is_empty():
				return multi_hit_block[round_index % multi_hit_block.size()]
		# 3d. 自身 HP < 25%：更倾向防守（phase 特性 boss 不防守）
		if hp_percent < 0.25 and not passive_skills.has("phase"):
			var defense_skills_low := _filter_by_type(skills, "defense")
			if not defense_skills_low.is_empty():
				return defense_skills_low[0]
			var dodge_skills_low := _filter_by_type(skills, "dodge")
			if not dodge_skills_low.is_empty():
				return dodge_skills_low[0]
			return innate.get("defend", "innate_defend")

	# 4. Low HP: prefer defense/dodge from special skills（phase 特性 boss 不防守）
	if hp_percent < 0.35 and not passive_skills.has("phase"):
		var defense_skills := _filter_by_type(skills, "defense")
		if not defense_skills.is_empty():
			return defense_skills[0]
		var dodge_skills := _filter_by_type(skills, "dodge")
		if not dodge_skills.is_empty():
			return dodge_skills[0]
		return innate.get("defend", "innate_defend")

	# 5. Tank/guard: defend on even rounds
	if (passive_skills.has("tank") or passive_skills.has("guard")) and round_index % 2 == 0:
		var defense_skills := _filter_by_type(skills, "defense")
		if not defense_skills.is_empty():
			return defense_skills[0]
		return innate.get("defend", "innate_defend")

	# 6. 辅助：奇数回合防守保持存活，偶数回合攻击
	# 辅助特性：奇数回合防守以持续辅助友军
	if passive_skills.has("support"):
		if round_index % 2 == 1:
			var defense_skills_sup := _filter_by_type(skills, "defense")
			if not defense_skills_sup.is_empty():
				return defense_skills_sup[0]
			return innate.get("defend", "innate_defend")

	# 7. Evade: dodge every 3rd round
	if passive_skills.has("evade") and round_index % 3 == 0:
		var dodge_skills := _filter_by_type(skills, "dodge")
		if not dodge_skills.is_empty():
			return dodge_skills[0]
		return innate.get("dodge", "innate_dodge")

	# 8. Fortify: defend on even rounds
	if passive_skills.has("fortify") and round_index % 2 == 0:
		var defense_skills := _filter_by_type(skills, "defense")
		if not defense_skills.is_empty():
			return defense_skills[0]
		return innate.get("defend", "innate_defend")

	# 9. 阶段：低血量时（<30%）优先攻击技能
	# 阶段特性：HP 低于 30% 时更激进
	if passive_skills.has("phase") and hp_percent < 0.30:
		var attack_skills_phase := _filter_by_type(skills, "attack")
		if not attack_skills_phase.is_empty():
			return attack_skills_phase[round_index % attack_skills_phase.size()]

	# 10. Default: prefer special attack skills, cycle through them
	var attack_skills := _filter_by_type(skills, "attack")
	if not attack_skills.is_empty():
		return attack_skills[round_index % attack_skills.size()]

	# 11. No attack skills: cycle through non-taunt special skills
	var non_taunt: Array[String] = []
	for skill_id in skills:
		if skill_id != "enemy_taunt":
			non_taunt.append(skill_id)
	if not non_taunt.is_empty():
		return non_taunt[round_index % non_taunt.size()]

	# 12. Fallback: innate attack
	return innate.get("attack_1", "innate_attack_1")


func _filter_by_type(skills: Array, skill_type: String) -> Array[String]:
	var DataCatalog = preload("res://scripts/core/data_catalog.gd")
	var result: Array[String] = []
	for skill_id in skills:
		var skill_data: Dictionary = DataCatalog.SKILLS.get(skill_id, {})
		if String(skill_data.get("type", "")) == skill_type:
			result.append(skill_id)
	return result


func _choose_weighted_action(enemy: Dictionary, behavior_weights: Dictionary, innate: Dictionary, rng: RandomNumberGenerator, is_alone: bool) -> String:
	var DataCatalog = preload("res://scripts/core/data_catalog.gd")
	var candidates: Array[String] = []
	var total_weight := 0
	for skill_id_value in behavior_weights.keys():
		var skill_id := String(skill_id_value)
		var weight := int(behavior_weights[skill_id_value])
		if weight <= 0 or not _is_available(enemy, skill_id, DataCatalog, is_alone):
			continue
		candidates.append(skill_id)
		total_weight += weight
	if total_weight <= 0:
		return String(innate.get("attack_1", "innate_attack_1"))
	var roll := rng.randi_range(1, total_weight) if rng != null else randi_range(1, total_weight)
	for skill_id in candidates:
		roll -= int(behavior_weights[skill_id])
		if roll <= 0:
			return skill_id
	return candidates.back()


func _is_available(enemy: Dictionary, skill_id: String, data_catalog, is_alone: bool) -> bool:
	if not data_catalog.SKILLS.has(skill_id) and not data_catalog.INNATE_SKILLS.has(skill_id):
		return false
	if bool(data_catalog.SKILLS.get(skill_id, {}).get("requires_living_ally", false)) and is_alone:
		return false
	return int(enemy.get("skill_cooldowns", {}).get(skill_id, 0)) <= 0


# 筛选多段攻击技能（hits > 1），用于响应式 AI 破闪避/破格挡
func _filter_multi_hit(skills: Array) -> Array[String]:
	var DataCatalog = preload("res://scripts/core/data_catalog.gd")
	var result: Array[String] = []
	for skill_id in skills:
		var skill_data: Dictionary = DataCatalog.SKILLS.get(skill_id, {})
		if String(skill_data.get("type", "")) == "attack" and int(skill_data.get("hits", 1)) > 1:
			result.append(skill_id)
	return result


# 检查敌人是否拥有指定 id 的活跃状态效果
func _has_status(enemy: Dictionary, status_id: String) -> bool:
	for status in enemy.get("statuses", []):
		if String(status.get("id", "")) == status_id:
			return true
	return false
