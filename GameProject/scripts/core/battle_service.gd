extends RefCounted
class_name BattleService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const Combatant = preload("res://scripts/core/combatant.gd")


func player_attack(session: RefCounted, target_index: int) -> void:
	session.last_events.clear()
	if not session._can_act(1):
		return
	var target: int = session._valid_target(target_index)
	if target < 0:
		return
	var damage: int = session._modified_value(session._current_attack_value(), "attack")
	damage = session._apply_charge_attack_modifiers(damage)
	session._apply_damage_to_enemy(target, damage)
	var repeats: int = session._consume_charge_repeat("attack")
	for _i in range(repeats):
		if session._alive_enemy_count() <= 0:
			break
		session._apply_damage_to_enemy(target, damage)
	if session.pending_state_card == "fallback":
		session._add_player_block(maxi(1, int(round(float(session.player["block_power"]) * 0.5))))
	session.action_points -= 1
	session._consume_state_after_action("attack")
	session._after_player_action()


func player_defend(session: RefCounted) -> void:
	session.last_events.clear()
	if not session._can_act(1):
		return
	var gained: int = session._modified_value(int(session.player["block_power"]), "defense")
	gained = session._apply_charge_defense_modifiers(gained)
	var total_gained := gained
	var repeats: int = session._consume_charge_repeat("defense")
	for _i in range(repeats):
		total_gained += gained
	session._add_player_block(total_gained)
	session.action_points -= 1
	session.battle_log.append("防御：获得 %d 点格挡值。" % total_gained)
	session.last_events.append({"kind": "defense", "target": "player", "amount": total_gained})
	session._consume_state_after_action("defense")
	session._after_player_action()


func player_dodge(session: RefCounted) -> void:
	session.last_events.clear()
	if not session._can_act(1):
		return
	var gained := 1
	if session.pending_state_card == "read":
		gained = 2
	session._add_player_dodge(gained)
	session.action_points -= 1
	session.battle_log.append("躲避：获得 %d 层躲避。" % gained)
	session.last_events.append({"kind": "dodge", "target": "player", "amount": gained})
	session._consume_state_after_action("dodge")
	session._after_player_action()


func use_skill(session: RefCounted, slot_index: int, target_index: int) -> void:
	session.last_events.clear()
	if session.phase != "battle":
		return
	if slot_index < 0 or slot_index >= session.player["equipped_skills"].size():
		session.message = "该技能槽还没有技能。"
		return
	var skill_id: String = session.player["equipped_skills"][slot_index]
	var skill: Dictionary = DataCatalog.SKILLS[skill_id]
	var cost := int(skill.get("cost", 1))
	if not session._can_act(cost):
		return
	var skill_type := String(skill.get("type", "attack"))
	if skill_type == "attack":
		var target: int = session._valid_target(target_index)
		if target < 0:
			return
		var damage: int = session._modified_value(session._skill_attack_value(skill_id), "attack")
		damage = session._apply_charge_attack_modifiers(damage, skill_id)
		var hits := maxi(1, int(skill.get("hits", 1)))
		for _hit in range(hits):
			if session._alive_enemy_count() <= 0:
				break
			session._apply_damage_to_enemy(target, damage)
		var repeats: int = session._consume_charge_repeat("attack", skill_id)
		for _i in range(repeats):
			for _hit in range(hits):
				if session._alive_enemy_count() <= 0:
					break
				session._apply_damage_to_enemy(target, damage)
		if session.pending_state_card == "fallback":
			session._add_player_block(maxi(1, int(round(float(session.player["block_power"]) * 0.5))))
	elif skill_type == "defense" or skill_type == "stance":
		var gained: int = session._modified_value(session._skill_defense_value(skill_id), "defense")
		gained = session._apply_charge_defense_modifiers(gained, skill_id)
		var total_gained := gained
		var repeats: int = session._consume_charge_repeat("defense", skill_id)
		for _i in range(repeats):
			total_gained += gained
		session._add_player_block(total_gained)
		session.battle_log.append("%s：获得 %d 点格挡值。" % [skill["name"], total_gained])
		session.last_events.append({"kind": "defense", "target": "player", "amount": total_gained})
		if skill_type == "stance":
			session.counter_stance_charges += 1
			session.counter_attack_multiplier = maxf(session.counter_attack_multiplier, float(skill.get("counter_multiplier", 1.0)) + session._skill_multiplier_bonus(skill_id, "attack"))
			session.battle_log.append("%s：准备反击下一次命中自身的敌方攻击，反击倍率 x%.2f。" % [skill["name"], session.counter_attack_multiplier])
	elif skill_type == "dodge":
		var gained := int(skill.get("dodge_layers", 1))
		if session.pending_state_card == "read":
			gained *= 2
		session._add_player_dodge(gained)
		var block_gained: int = session._skill_dodge_block_value(skill_id)
		if block_gained > 0:
			session._add_player_block(block_gained)
		session.battle_log.append("%s：获得 %d 层躲避。" % [skill["name"], gained])
		session.last_events.append({"kind": "dodge", "target": "player", "amount": gained})
	elif skill_type == "heal":
		var healed: int = session._skill_heal_value(skill_id)
		session.player["hp"] = mini(int(session.player["max_hp"]), int(session.player["hp"]) + healed)
		session.battle_log.append("%s：恢复 %d 点生命。" % [skill["name"], healed])
		session.last_events.append({"kind": "heal", "target": "player", "amount": healed})
	elif skill_type == "buff":
		var multiplier: float = float(skill.get("attack_multiplier", 1.0)) + float(session._skill_multiplier_bonus(skill_id, "attack"))
		session.battle_attack_multiplier *= multiplier
		session.battle_log.append("%s：本场战斗攻击倍率 x%.2f。" % [skill["name"], multiplier])
		session.last_events.append({"kind": "buff", "target": "player", "amount": 0})
	elif skill_type == "debuff":
		var target: int = session._valid_target(target_index)
		if target < 0:
			return
		var multiplier: float = float(skill.get("mark_multiplier", 1.0)) + float(session._skill_multiplier_bonus(skill_id, "attack"))
		session.enemies[target]["mark_multiplier"] = maxf(float(session.enemies[target].get("mark_multiplier", 1.0)), multiplier)
		session.battle_log.append("%s：%s 受到标记，承受伤害 x%.2f。" % [skill["name"], session.enemies[target]["name"], multiplier])
		session.last_events.append({"kind": "debuff", "target": "enemy", "target_index": target, "amount": 0})
	else:
		session.message = "该技能暂未实现。"
		return
	session.action_points -= cost
	session._consume_state_after_action(skill_type)
	session._after_player_action()


func end_turn(session: RefCounted) -> void:
	session.last_events.clear()
	if session.phase != "battle":
		return
	enemy_turn(session)
	if session._alive_enemy_count() > 0 and int(session.player["hp"]) > 0:
		session._begin_player_turn()


func enemy_turn(session: RefCounted) -> void:
	session._clear_enemy_blocks()
	session._clear_enemy_taunts()
	var actions := 0
	for i in range(session.enemies.size()):
		var enemy: Dictionary = session.enemies[i]
		if int(enemy["hp"]) <= 0:
			continue
		if actions >= 2:
			enemy_defend(enemy, 0.5)
			continue
		resolve_enemy_action(session, enemy, i)
		actions += 1
	if int(session.player["hp"]) <= 0:
		session._on_defeat()


func resolve_enemy_action(session: RefCounted, enemy: Dictionary, enemy_index: int) -> void:
	var intent: String = session._enemy_intent(enemy)
	match intent:
		"taunt":
			enemy["taunt"] = 1
			var gained := enemy_defend(enemy, 1.0)
			session.battle_log.append("%s 嘲讽并防守。" % enemy["name"])
			session.last_events.append({"kind": "defense", "target": "enemy", "target_index": enemy_index, "source": enemy["name"], "amount": gained})
		"defend":
			var gained := enemy_defend(enemy, 1.0)
			session.battle_log.append("%s 进入防守，获得 %d 点格挡。" % [enemy["name"], gained])
			session.last_events.append({"kind": "defense", "target": "enemy", "target_index": enemy_index, "source": enemy["name"], "amount": gained})
		"dodge":
			Combatant.add_dodge(enemy, 1)
			session.battle_log.append("%s 准备闪避下一次命中。" % enemy["name"])
			session.last_events.append({"kind": "dodge", "target": "enemy", "target_index": enemy_index, "source": enemy["name"], "amount": 1})
		_:
			enemy_attack(session, enemy, enemy_index, false)


func enemy_defend(enemy: Dictionary, scale: float) -> int:
	return Combatant.add_block(enemy, scale)


func enemy_attack(session: RefCounted, enemy: Dictionary, enemy_index: int, first_strike: bool) -> void:
	var segments := enemy_attack_segments(session, enemy, first_strike)
	var player_unit: Dictionary = session._player_combatant()
	var was_hit := false
	for damage in segments:
		var result := Combatant.apply_damage(player_unit, damage)
		session._sync_player_combatant(player_unit)
		if bool(result["dodged"]):
			session.battle_log.append("躲避了 %s 的一段攻击。" % enemy["name"])
			session.last_events.append({"kind": "dodge_enemy_attack", "target": "player", "source": enemy["name"], "amount": 0})
			continue
		was_hit = true
		session.battle_log.append("%s 攻击：护甲减免 %d，格挡吸收 %d，造成 %d 点伤害。" % [
			enemy["name"],
			int(result["armor_reduced"]),
			int(result["block_absorbed"]),
			int(result["damage"])
		])
		session.last_events.append({"kind": "damage", "target": "player", "source": enemy["name"], "amount": int(result["damage"])})
	if was_hit:
		session._trigger_counter_attack(enemy_index)


func enemy_attack_segments(session: RefCounted, enemy: Dictionary, first_strike: bool) -> Array[int]:
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
	if traits.has("summon") and session.round_index % 4 == 0:
		segments.append(maxi(1, int(round(float(enemy["attack"]) * 0.50))))
	return segments
