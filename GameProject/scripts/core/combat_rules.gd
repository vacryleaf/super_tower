extends RefCounted
class_name CombatRules

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const ModifierPipeline = preload("res://scripts/core/modifier_pipeline.gd")

const RANK_SKILL_MULTIPLIER := {
	"normal": 1.0,
	"elite": 1.20,
	"boss": 1.45
}

# 回合结束特性效果常量（集中管理，combat_engine 和 battle_service 共用）
const CURSE_INTERVAL := 3
const CURSE_DAMAGE := 1
const CORRODE_DEFENSE_MULTIPLIER := 0.85
const CORRODE_DURATION := 2
const SUPPORT_HEAL_RATIO := 0.10
const SUPPORT_INTERVAL := 2
const SPLIT_HP_THRESHOLD := 0.5
const SUMMON_INTERVAL := 4
const SUMMON_MINION_SCALE := 0.4
const SCENE_PASSIVE_SKILLS := ["toxic_mist", "shadow_domain", "blood_moon"]


static func apply_corruption(target: Dictionary, source_attack: int, status_service) -> void:
	status_service.add_status(target, {
		"id": "rat_corruption",
		"name": "腐败",
		"kind": "debuff",
		"stack": "replace",
		"corruption_damage": maxi(1, int(ceil(float(source_attack) * 0.20))),
		"duration": 3
	})


static func resolve_corruption(target: Dictionary) -> int:
	if not target.has("statuses"):
		return 0
	var statuses: Array = target["statuses"]
	for index in range(statuses.size() - 1, -1, -1):
		var status: Dictionary = statuses[index]
		if String(status.get("id", "")) != "rat_corruption":
			continue
		var damage := int(status.get("corruption_damage", 0))
		target["hp"] = maxi(0, int(target["hp"]) - damage)
		var remaining := int(status.get("duration", 0)) - 1
		if remaining <= 0:
			statuses.remove_at(index)
		else:
			statuses[index]["duration"] = remaining
		return damage
	return 0


static func apply_armor_reduction(target: Dictionary, amount: int, status_service, source_name: String) -> void:
	if amount <= 0:
		return
	status_service.add_status(target, {
		"id": "rat_armor_reduction_%s" % source_name,
		"name": source_name,
		"kind": "debuff",
		"stack": "stack",
		"effects": [{"stat": StatusService.STAT_ARMOR, "type": "flat", "value": -amount}],
		"duration": -1
	})


static func armor_multiplier_against(attacker: Dictionary) -> float:
	return 0.80 if attacker.get("passive_skills", []).has("break_armor") else 1.0


static func ally_guard_damage_multiplier(target: Dictionary, allies: Array[Dictionary]) -> float:
	for ally in allies:
		if ally == target or int(ally.get("hp", 0)) <= 0:
			continue
		if ally.get("passive_skills", []).has("guard"):
			return 0.80
	return 1.0


static func tick_enemy_cooldowns(enemy: Dictionary) -> void:
	var cooldowns: Dictionary = enemy.get("skill_cooldowns", {})
	var expired: Array[String] = []
	for skill_id in cooldowns.keys():
		var remaining := int(cooldowns[skill_id]) - 1
		if remaining <= 0:
			expired.append(String(skill_id))
		else:
			cooldowns[skill_id] = remaining
	for skill_id in expired:
		cooldowns.erase(skill_id)


static func build_enemies(encounter: Dictionary, tower_floor: int, include_statuses: bool = true) -> Array[Dictionary]:
	var enemies: Array[Dictionary] = []
	for unit in encounter.get("units", []):
		var enemy := Combatant.from_enemy_unit(unit, String(encounter.get("type", "normal")), tower_floor)
		if include_statuses and not enemy.has("statuses"):
			enemy["statuses"] = []
		enemies.append(enemy)
	return enemies


static func alive_count(enemies: Array[Dictionary]) -> int:
	var count := 0
	for enemy in enemies:
		if int(enemy.get("hp", 0)) > 0:
			count += 1
	return count


static func active_taunt_target(enemies: Array[Dictionary]) -> int:
	for i in range(enemies.size()):
		if int(enemies[i].get("hp", 0)) > 0 and int(enemies[i].get("taunt", 0)) > 0:
			return i
	return -1


static func is_hidden_unit(enemy: Dictionary) -> bool:
	return enemy.get("passive_skills", []).has("hidden")


static func has_visible_alive_enemy(enemies: Array[Dictionary]) -> bool:
	for enemy in enemies:
		if int(enemy.get("hp", 0)) > 0 and not is_hidden_unit(enemy):
			return true
	return false


static func valid_target(enemies: Array[Dictionary], target_index: int) -> int:
	var taunt_target := active_taunt_target(enemies)
	if taunt_target >= 0:
		return taunt_target
	if enemies.is_empty():
		return -1
	var has_frontline := has_active_frontline(enemies)
	var has_visible := has_visible_alive_enemy(enemies)
	if target_index >= 0 and target_index < enemies.size() and int(enemies[target_index].get("hp", 0)) > 0:
		if (not has_visible or not is_hidden_unit(enemies[target_index])) and not is_backline_protected_by_frontline(enemies[target_index], has_frontline):
			return target_index
	for i in range(enemies.size()):
		if int(enemies[i].get("hp", 0)) > 0:
			if has_visible and is_hidden_unit(enemies[i]):
				continue
			if not is_backline_protected_by_frontline(enemies[i], has_frontline):
				return i
	if has_visible:
		for i in range(enemies.size()):
			if int(enemies[i].get("hp", 0)) > 0 and not is_hidden_unit(enemies[i]):
				return i
	return -1


# 检查目标是否为 backline 且有存活的前排保护，用于有效目标验证
static func is_backline_protected(enemies: Array[Dictionary], target: Dictionary) -> bool:
	return is_backline_protected_by_frontline(target, has_active_frontline(enemies))


static func is_backline_protected_by_frontline(target: Dictionary, has_frontline: bool) -> bool:
	if not target.get("passive_skills", []).has("backline"):
		return false
	return has_frontline


static func clear_enemy_taunts(enemies: Array[Dictionary]) -> void:
	for enemy in enemies:
		Combatant.clear_taunt(enemy)


static func clear_enemy_blocks(enemies: Array[Dictionary]) -> void:
	for enemy in enemies:
		Combatant.clear_block(enemy)


static func current_attack_value(session: RefCounted, action_source: String = "") -> int:
	var resolved_attack: float = session.status_service.resolve_stat(session.player, float(session.player["attack"]), StatusService.STAT_ATTACK)
	var modifiers: Array = ModifierPipeline.collect_from_session(session, "attack", {
		"state_card": session.pending_state_card,
		"focus_combo_multiplier": session.focus_combo_multiplier
	}, action_source)
	return maxi(1, int(round(ModifierPipeline.resolve(resolved_attack, modifiers))))


static func defense_value(session: RefCounted) -> int:
	var resolved_defense: float = session.status_service.resolve_stat(session.player, float(session.player["block_power"]), StatusService.STAT_DEFENSE)
	var modifiers: Array = ModifierPipeline.collect_from_session(session, "defense", {})
	return maxi(1, int(round(ModifierPipeline.resolve(resolved_defense, modifiers))))


static func _get_skill(skill_id: String) -> Dictionary:
	if DataCatalog.SKILLS.has(skill_id):
		return DataCatalog.SKILLS[skill_id]
	if DataCatalog.INNATE_SKILLS.has(skill_id):
		return DataCatalog.INNATE_SKILLS[skill_id]
	return {}


static func skill_attack_value(session: RefCounted, skill_id: String, action_source: String = "") -> int:
	var skill: Dictionary = _get_skill(skill_id)
	var multiplier: float = float(skill.get("multiplier", 1.0)) + session._skill_multiplier_bonus(skill_id, "attack")
	var resolved_attack: float = session.status_service.resolve_stat(session.player, float(session.player["attack"]), StatusService.STAT_ATTACK)
	var modifiers: Array = ModifierPipeline.collect_from_session(session, "attack", {"skill_id": skill_id, "skill_multiplier": multiplier}, action_source)
	return maxi(1, int(round(ModifierPipeline.resolve(resolved_attack, modifiers))))


static func skill_defense_value(session: RefCounted, skill_id: String) -> int:
	var skill: Dictionary = _get_skill(skill_id)
	var multiplier: float = float(skill.get("multiplier", skill.get("block_multiplier", 1.0))) + session._skill_multiplier_bonus(skill_id, "defense")
	var resolved_defense: float = session.status_service.resolve_stat(session.player, float(session.player["block_power"]), StatusService.STAT_DEFENSE)
	var modifiers: Array = ModifierPipeline.collect_from_session(session, "defense", {"skill_id": skill_id, "skill_multiplier": multiplier})
	return maxi(1, int(round(ModifierPipeline.resolve(resolved_defense, modifiers))))


static func skill_dodge_block_value(session: RefCounted, skill_id: String) -> int:
	var skill: Dictionary = _get_skill(skill_id)
	var multiplier: float = float(skill.get("block_multiplier", 0.0)) + session._skill_multiplier_bonus(skill_id, "defense")
	if multiplier <= 0.0:
		return 0
	return maxi(1, int(round(float(session.player["block_power"]) * multiplier)))


static func skill_heal_value(session: RefCounted, skill_id: String) -> int:
	var skill: Dictionary = _get_skill(skill_id)
	var multiplier: float = float(skill.get("heal_multiplier", 0.0)) + session._skill_multiplier_bonus(skill_id, "hp")
	var base_heal := maxi(1, int(round(float(session.player["max_hp"]) * multiplier)))
	# 解析 heal stat 效果（如场地效果的 heal 修正）
	var resolved_heal: float = session.status_service.resolve_stat(session.player, float(base_heal), StatusService.STAT_HEAL)
	return maxi(1, int(round(resolved_heal)))


static func skill_attack_value_for_actor(actor: Dictionary, skill_id: String, status_service = null, multiplier_bonus: float = 0.0, modifiers: Array[Dictionary] = []) -> int:
	var skill: Dictionary = _get_skill(skill_id)
	var multiplier: float = float(skill.get("multiplier", 1.0)) + multiplier_bonus
	var base_attack: float = float(actor["attack"])
	if status_service != null:
		base_attack = status_service.resolve_stat(actor, base_attack, StatusService.STAT_ATTACK)
	var rank_mult: float = _rank_skill_multiplier(actor) if skill.get("class", "") == "enemy" else 1.0
	var result := maxi(1, int(ceil(base_attack * multiplier * rank_mult)))
	if not modifiers.is_empty():
		result = maxi(1, int(ceil(ModifierPipeline.resolve(float(result), modifiers))))
	return result


static func skill_defense_value_for_actor(actor: Dictionary, skill_id: String, status_service = null, multiplier_bonus: float = 0.0, modifiers: Array[Dictionary] = []) -> int:
	var skill: Dictionary = _get_skill(skill_id)
	var multiplier: float = float(skill.get("multiplier", skill.get("block_multiplier", 1.0))) + multiplier_bonus
	var base_defense: float = float(actor.get("block_power", actor.get("defense", 1)))
	if status_service != null:
		base_defense = status_service.resolve_stat(actor, base_defense, StatusService.STAT_DEFENSE)
	var rank_mult: float = _rank_skill_multiplier(actor) if skill.get("class", "") == "enemy" else 1.0
	var result := maxi(1, int(round(base_defense * multiplier * rank_mult)))
	if not modifiers.is_empty():
		result = maxi(1, int(round(ModifierPipeline.resolve(float(result), modifiers))))
	return result


static func skill_heal_value_for_actor(actor: Dictionary, skill_id: String, status_service = null, multiplier_bonus: float = 0.0, modifiers: Array[Dictionary] = []) -> int:
	var skill: Dictionary = _get_skill(skill_id)
	var multiplier: float = float(skill.get("heal_multiplier", 0.0)) + multiplier_bonus
	var max_hp: float = float(actor["max_hp"])
	if status_service != null:
		max_hp = status_service.resolve_stat(actor, max_hp, StatusService.STAT_MAX_HP)
	var base_heal := maxi(1, int(round(max_hp * multiplier)))
	# 解析 heal stat 效果（如场地效果的 heal 修正）
	if status_service != null:
		var resolved_heal: float = status_service.resolve_stat(actor, float(base_heal), StatusService.STAT_HEAL)
		base_heal = maxi(1, int(round(resolved_heal)))
	var result := base_heal
	if not modifiers.is_empty():
		result = maxi(1, int(round(ModifierPipeline.resolve(float(result), modifiers))))
	return result


static func _rank_skill_multiplier(actor: Dictionary) -> float:
	if bool(actor.get("fixed_stats", false)):
		return 1.0
	return RANK_SKILL_MULTIPLIER.get(String(actor.get("rank", "normal")), 1.0)


static func enemy_attack_segments(session: RefCounted, enemy: Dictionary, first_strike: bool) -> Array[int]:
	var segments: Array[int] = session.enemy_rules.attack_segments(enemy, session.round_index, first_strike)
	var base_attack := float(enemy["attack"])
	var resolved_attack: float = session.status_service.resolve_stat(enemy, base_attack, StatusService.STAT_ATTACK)
	var status_ratio := resolved_attack / maxf(1.0, base_attack)
	var total_multiplier: float = session.enemy_attack_multiplier * status_ratio
	if abs(total_multiplier - 1.0) < 0.001:
		return segments
	var result: Array[int] = []
	for damage in segments:
		result.append(maxi(1, int(round(float(damage) * total_multiplier))))
	return result


# 检查敌方队伍中是否有存活的前排单位（tank/guard），用于 backline 特性判断
static func has_active_frontline(enemies: Array[Dictionary]) -> bool:
	for e in enemies:
		if int(e.get("hp", 0)) > 0 and (e.get("passive_skills", []).has("tank") or e.get("passive_skills", []).has("guard")):
			return true
	return false


# 找到除自身外血量百分比最低的友军，用于 support 特性治疗目标选择
static func find_lowest_hp_ally(enemies: Array[Dictionary], self_enemy: Dictionary) -> Dictionary:
	var lowest: Dictionary = {}
	var lowest_hp_ratio := 1.0
	for e in enemies:
		if e == self_enemy or int(e.get("hp", 0)) <= 0:
			continue
		var ratio := float(e["hp"]) / float(e["max_hp"])
		if ratio < lowest_hp_ratio:
			lowest_hp_ratio = ratio
			lowest = e
	return lowest


# 检查并执行裂变：受到伤害后，HP 低于阈值的 split 特性敌人分裂为两个半血单位
static func check_split_after_damage(enemies: Array[Dictionary], target: Dictionary, round_index: int, log: Array[String]) -> void:
	if target.is_empty():
		return
	if int(target.get("hp", 0)) <= 0:
		return
	if not target.get("passive_skills", []).has("split"):
		return
	if target.get("split_triggered", false):
		return
	if float(target["hp"]) / float(maxi(1, int(target.get("max_hp", target["hp"])))) >= SPLIT_HP_THRESHOLD:
		return
	target["split_triggered"] = true
	var split_hp := maxi(1, int(ceil(float(target["hp"]) / 2.0)))
	target["hp"] = split_hp
	var clone: Dictionary = target.duplicate(true)
	clone["hp"] = split_hp
	clone["available_round"] = round_index + 1
	enemies.append(clone)
	log.append("split:%s" % String(target.get("name", "敌人")))


static func check_split(enemies: Array[Dictionary], round_index: int, log: Array[String]) -> void:
	for enemy in enemies:
		check_split_after_damage(enemies, enemy, round_index, log)
		if int(enemy.get("hp", 0)) > 0 and enemy.get("split_triggered", false):
			break


# 检查并执行召唤：由主动技能或外部条件触发后召唤弱化分身
static func check_summon(enemies: Array[Dictionary], round_index: int, log: Array[String]) -> void:
	for enemy in enemies:
		if int(enemy.get("hp", 0)) <= 0:
			continue
		if not _has_status(enemy, "summon_ready"):
			continue
		# 移除召唤准备标记
		var statuses: Array = enemy.get("statuses", [])
		for i in range(statuses.size() - 1, -1, -1):
			if String(statuses[i].get("id", "")) == "summon_ready":
				statuses.remove_at(i)
		# 创建弱化克隆体
		var clone: Dictionary = enemy.duplicate(true)
		clone["hp"] = maxi(1, int(float(clone["hp"]) * SUMMON_MINION_SCALE))
		clone["max_hp"] = maxi(1, int(float(clone["max_hp"]) * SUMMON_MINION_SCALE))
		clone["attack"] = maxi(1, int(float(clone["attack"]) * SUMMON_MINION_SCALE))
		clone["defense"] = maxi(0, int(round(float(clone["defense"]) * SUMMON_MINION_SCALE)))
		clone["armor"] = maxi(0, int(round(float(clone.get("armor", 0)) * SUMMON_MINION_SCALE)))
		clone["block_power"] = maxi(1, int(round(float(clone.get("block_power", 1)) * SUMMON_MINION_SCALE)))
		# 移除克隆体的召唤特性防止无限链
		var clone_passive_skills: Array = clone.get("passive_skills", [])
		clone_passive_skills.erase("summon")
		clone["passive_skills"] = clone_passive_skills
		# 清除克隆体上的召唤相关状态
		var clone_statuses: Array = clone.get("statuses", [])
		for i in range(clone_statuses.size() - 1, -1, -1):
			var sid := String(clone_statuses[i].get("id", ""))
			if sid == "summon_ready" or sid == "trait_summon":
				clone_statuses.remove_at(i)
		clone["name"] = "%s 的仆从" % String(enemy.get("name", "敌人"))
		clone["available_round"] = round_index + 1
		enemies.append(clone)
		log.append("summon:%s:%s" % [String(enemy.get("name", "敌人")), String(clone.get("name", "仆从"))])
		break


static func collect_scene_skill_sources(units: Array[Dictionary]) -> Array[Dictionary]:
	var sources: Array[Dictionary] = []
	for unit in units:
		if int(unit.get("hp", 0)) <= 0:
			continue
		var passive_skills: Array = unit.get("passive_skills", [])
		for skill_id in passive_skills:
			var resolved_id := String(skill_id)
			if resolved_id == "" or not SCENE_PASSIVE_SKILLS.has(resolved_id):
				continue
			sources.append({
				"source": unit,
				"skill_id": resolved_id
			})
	return sources


# 检查敌人是否拥有指定 id 的状态效果
static func _has_status(enemy: Dictionary, status_id: String) -> bool:
	for status in enemy.get("statuses", []):
		if String(status.get("id", "")) == status_id:
			return true
	return false


# 回合结束时处理 corrode（腐蚀）和 support（辅助）特性效果
static func apply_end_round_traits(player: Dictionary, enemies: Array[Dictionary], round_index: int, status_service, log: Array[String] = []) -> void:
	for enemy in enemies:
		if int(enemy.get("hp", 0)) <= 0:
			continue
		var passive_skills: Array = enemy.get("passive_skills", [])
		# 腐蚀：每回合给玩家施加护甲降低 debuff
		if passive_skills.has("corrode") and status_service != null:
			status_service.add_status(player, {
				"id": "corrode_debuff", "name": "腐蚀", "kind": "debuff", "stack": "replace",
				"effects": [{"stat": "defense", "type": "multiply", "value": CORRODE_DEFENSE_MULTIPLIER}],
				"duration": CORRODE_DURATION
			})
		# 辅助：每 N 回合治疗血量最低的友军
		if passive_skills.has("support") and round_index % SUPPORT_INTERVAL == 0:
			var lowest_ally: Dictionary = find_lowest_hp_ally(enemies, enemy)
			if not lowest_ally.is_empty():
				var heal := maxi(1, int(round(float(lowest_ally["max_hp"]) * SUPPORT_HEAL_RATIO)))
				lowest_ally["hp"] = mini(int(lowest_ally["max_hp"]), int(lowest_ally["hp"]) + heal)
				if not log.is_empty():
					log.append("support_heal:%s:%d" % [lowest_ally["name"], heal])


# 检查并应用场地效果：boss 存活时对全场施加效果
static func apply_arena_effects(player: Dictionary, enemies: Array[Dictionary], round_index: int, status_service, allies: Array[Dictionary] = [], log: Array[String] = [], scene_skill_sources: Array[Dictionary] = []) -> void:
	if status_service == null:
		return
	var active_sources: Array[Dictionary] = scene_skill_sources
	if active_sources.is_empty():
		active_sources = collect_scene_skill_sources(enemies + allies)
	var has_toxic_mist := false
	var has_shadow_domain := false
	var has_blood_moon := false
	var toxic_sources: Array[Dictionary] = []
	for entry in active_sources:
		var source: Dictionary = entry.get("source", {})
		if source.is_empty() or int(source.get("hp", 0)) <= 0:
			continue
		var skill_id := String(entry.get("skill_id", ""))
		if skill_id == "toxic_mist":
			has_toxic_mist = true
			toxic_sources.append(source)
		if skill_id == "shadow_domain":
			has_shadow_domain = true
		if skill_id == "blood_moon":
			has_blood_moon = true
	# 毒雾：每 3 回合对玩家和友军造成基于持有者攻击力的伤害
	if has_toxic_mist and round_index % 3 == 0:
		var source_attack := 0.0
		for source in toxic_sources:
			source_attack = maxf(source_attack, float(status_service.resolve_stat(source, float(source.get("attack", 0)), StatusService.STAT_ATTACK)))
		var dot_damage := maxi(1, int(ceil(source_attack * 0.30)))
		var targets: Array[Dictionary] = [player]
		for ally in allies:
			if int(ally.get("hp", 0)) > 0:
				targets.append(ally)
		for target in targets:
			var result := Combatant.apply_damage(target, dot_damage, "physical")
			if not log.is_empty():
				if bool(result["dodged"]):
					log.append("毒雾：%s 闪避了伤害。" % String(target.get("name", "")))
				else:
					log.append("毒雾：%s 受到 %d 点伤害。" % [String(target.get("name", "")), int(result["damage"])])
	# 暗影领域：暗影伤害 +20%，治疗 -50%
	if has_shadow_domain:
		var shadow_status := {"id": "shadow_domain_effect", "name": "暗影领域", "kind": "debuff", "stack": "replace",
			"effects": [
				{"stat": "resist_shadow", "type": "multiply", "value": 0.80},
				{"stat": "heal", "type": "multiply", "value": 0.50}
			],
			"duration": 1}
		status_service.add_status(player, shadow_status)
	# 血月：所有攻击 +1，所有治疗 +1
	if has_blood_moon:
		var blood_status := {"id": "blood_moon_effect", "name": "血月", "kind": "buff", "stack": "replace",
			"effects": [
				{"stat": "attack", "type": "flat", "value": 0.5},
				{"stat": "heal", "type": "flat", "value": 1.0}
			],
			"duration": 1}
		status_service.add_status(player, blood_status)
		for enemy in enemies:
			if int(enemy.get("hp", 0)) > 0:
				status_service.add_status(enemy, blood_status)


static func shadow_armor_reflect_damage(result: Dictionary) -> int:
	if bool(result.get("dodged", false)):
		return 0
	if int(result.get("block_absorbed", 0)) <= 0:
		return 0
	var damage_before_block := int(result.get("damage_before_block", result.get("damage", 0)))
	if damage_before_block <= 0:
		return 0
	var reflect_per_hit := maxi(1, int(ceil(float(damage_before_block) * 0.5)))
	var reflect_count := 1
	if int(result.get("block_broken", 0)) > 0 and int(result.get("damage", 0)) > 0:
		reflect_count += 1
	return reflect_per_hit * reflect_count
