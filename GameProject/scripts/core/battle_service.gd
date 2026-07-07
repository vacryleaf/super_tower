extends RefCounted
class_name BattleService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const DamageType = preload("res://scripts/core/damage_type.gd")
const TriggerEvents = preload("res://scripts/core/trigger_events.gd")
const ActionSource = preload("res://scripts/core/action_source.gd")
const ActionContext = preload("res://scripts/core/action_context.gd")
const ActionPipeline = preload("res://scripts/core/action_pipeline.gd")
const CombatRules = preload("res://scripts/core/combat_rules.gd")


func player_attack(session: RefCounted, target_index: int) -> void:
	session.last_events.clear()
	if not session._can_act(1):
		return
	var target: int = session._valid_target(target_index)
	if target < 0:
		return
	session.attacked_this_turn = true
	var skill_id: String = session.player["innate_skills"]["attack"]
	execute_skill(session, skill_id, target, session.player, true)


func player_defend(session: RefCounted) -> void:
	session.last_events.clear()
	if not session._can_act(1):
		return
	var skill_id: String = session.player["innate_skills"]["defend"]
	execute_skill(session, skill_id, -1, session.player, true)


func player_dodge(session: RefCounted) -> void:
	session.last_events.clear()
	if not session._can_act(1):
		return
	var skill_id: String = session.player["innate_skills"]["dodge"]
	execute_skill(session, skill_id, -1, session.player, true)


func use_skill(session: RefCounted, slot_index: int, target_index: int) -> void:
	session.last_events.clear()
	if session.phase != "battle":
		return
	if slot_index < 0 or slot_index >= session.player["equipped_skills"].size():
		session.message = "该技能槽还没有技能。"
		return
	var skill_id: String = session.player["equipped_skills"][slot_index]
	var skill: Dictionary = _get_skill_data(skill_id)
	if skill.is_empty():
		return
	var cost := int(skill.get("cost", 1))
	if not session._can_act(cost):
		return
	execute_skill(session, skill_id, target_index, session.player, true)


func execute_skill(session: RefCounted, skill_id: String, target_index: int, actor: Dictionary, is_player: bool) -> void:
	var skill: Dictionary = _get_skill_data(skill_id)
	if skill.is_empty():
		return
	var skill_type := String(skill.get("type", "attack"))
	var cost := int(skill.get("cost", 1))

	if skill_type == "attack":
		if is_player:
			var target: int = session._valid_target(target_index)
			if target < 0:
				return
			var base_damage: int = session._skill_attack_value(skill_id, ActionSource.ACTIVE_ATTACK)
			var skill_ctx := ActionContext.create_attack(ActionSource.ACTIVE_ATTACK, target, skill_id, String(skill.get("damage_type", "physical")), maxi(1, int(skill.get("hits", 1))))
			skill_ctx["base_damage"] = base_damage
			ActionPipeline.compute(skill_ctx, session)
			var armor_reduce := float(skill.get("armor_reduce", 0.0))
			if armor_reduce > 0.0:
				var old_armor := int(session.enemies[target].get("armor", 0))
				session.enemies[target]["armor"] = maxi(0, int(round(float(old_armor) * (1.0 - armor_reduce))))
				session.battle_log.append("%s：破甲 %d%%，%s 护甲 %d → %d。" % [skill["name"], int(armor_reduce * 100), session.enemies[target]["name"], old_armor, int(session.enemies[target]["armor"])])
			var skill_damage_type: String = String(skill.get("damage_type", "physical"))
			var hits := maxi(1, int(skill.get("hits", 1)) + int(session.player.get("extra_hits", 0)))
			for _hit in range(hits):
				if session._alive_enemy_count() <= 0:
					break
				var hit_ctx := ActionContext.create_attack(ActionSource.ACTIVE_ATTACK, target, skill_id, skill_damage_type, 1)
				hit_ctx["final_damage"] = skill_ctx["final_damage"]
				session.deal_damage(hit_ctx)
			var repeats: int = session._consume_charge_repeat("attack", skill_id)
			for _i in range(repeats):
				for _hit in range(hits):
					if session._alive_enemy_count() <= 0:
						break
					var hit_ctx := ActionContext.create_attack(ActionSource.ACTIVE_ATTACK, target, skill_id, skill_damage_type, 1)
					hit_ctx["final_damage"] = skill_ctx["final_damage"]
					session.deal_damage(hit_ctx)
			if session.pending_state_card == "fallback":
				session._add_player_block(maxi(1, int(round(float(session.player["block_power"]) * 0.5))))
			session.status_service.fire_trigger(session.player, TriggerEvents.ON_ATTACK_COMPLETE, {
				"battle_log": session.battle_log, "session": session, "skill_id": skill_id
			})
		else:
			if skill_id == "innate_attack":
				enemy_attack(session, actor, target_index, false)
				return
			var player_unit: Dictionary = session._player_combatant()
			var base_damage: int = CombatRules.skill_attack_value_for_actor(actor, skill_id)
			var hits := maxi(1, int(skill.get("hits", 1)))
			var was_hit := false
			for _hit in range(hits):
				if int(session.player["hp"]) <= 0:
					break
				var result := Combatant.apply_damage(player_unit, base_damage, String(skill.get("damage_type", "physical")))
				session._sync_player_combatant(player_unit)
				if bool(result["dodged"]):
					session.battle_log.append("躲避了 %s 的 %s。" % [actor["name"], skill["name"]])
					session.last_events.append({"kind": "dodge_enemy_attack", "target": "player", "source": actor["name"], "amount": 0})
				else:
					was_hit = true
					session.battle_log.append("%s 使用 %s：造成 %d 点伤害。" % [actor["name"], String(skill.get("name", skill_id)), int(result["damage"])])
					session.last_events.append({"kind": "damage", "target": "player", "source": actor["name"], "amount": int(result["damage"])})
			if was_hit:
				session._trigger_counter_attack(target_index)

	elif skill_type == "defense" or skill_type == "stance":
		if is_player:
			var gained: int = session._skill_defense_value(skill_id)
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
		else:
			var gained: int = CombatRules.skill_defense_value_for_actor(actor, skill_id)
			Combatant.add_block(actor, gained)
			session.battle_log.append("%s 使用 %s：获得 %d 点格挡。" % [actor["name"], String(skill.get("name", skill_id)), gained])
			session.last_events.append({"kind": "defense", "target": "enemy", "target_index": target_index, "source": actor["name"], "amount": gained})

	elif skill_type == "dodge":
		if is_player:
			var gained := int(skill.get("dodge_layers", 1))
			if session.pending_state_card == "read":
				gained *= 2
			session._add_player_dodge(gained)
			var block_gained: int = session._skill_dodge_block_value(skill_id)
			if block_gained > 0:
				session._add_player_block(block_gained)
			session.battle_log.append("%s：获得 %d 层躲避。" % [skill["name"], gained])
			session.last_events.append({"kind": "dodge", "target": "player", "amount": gained})
		else:
			var layers := maxi(1, int(skill.get("dodge_layers", 1)))
			Combatant.add_dodge(actor, layers)
			session.battle_log.append("%s 使用 %s：获得 %d 层闪避。" % [actor["name"], String(skill.get("name", skill_id)), layers])
			session.last_events.append({"kind": "dodge", "target": "enemy", "target_index": target_index, "source": actor["name"], "amount": layers})

	elif skill_type == "taunt":
		actor["taunt"] = int(skill.get("taunt_duration", 1))
		var gained: int = Combatant.add_block(actor, 1.0)
		session.battle_log.append("%s 使用 %s：嘲讽并防守，获得 %d 点格挡。" % [actor["name"], String(skill.get("name", skill_id)), gained])
		session.last_events.append({"kind": "defense", "target": "enemy", "target_index": target_index, "source": actor["name"], "amount": gained})

	elif skill_type == "heal":
		if is_player:
			var healed: int = session._skill_heal_value(skill_id)
			actor["hp"] = mini(int(actor["max_hp"]), int(actor["hp"]) + healed)
			session.battle_log.append("%s：恢复 %d 点生命。" % [skill["name"], healed])
			session.last_events.append({"kind": "heal", "target": "player", "amount": healed})
		else:
			var healed: int = CombatRules.skill_heal_value_for_actor(actor, skill_id)
			actor["hp"] = mini(int(actor["max_hp"]), int(actor["hp"]) + healed)
			session.battle_log.append("%s 使用 %s：恢复 %d 点生命。" % [actor["name"], String(skill.get("name", skill_id)), healed])
			session.last_events.append({"kind": "heal", "target": "enemy", "target_index": target_index, "source": actor["name"], "amount": healed})

	elif skill_type == "buff":
		if is_player:
			var bonus_multiplier: float = session._skill_multiplier_bonus(skill_id, "attack")
			var multiplier: float = float(skill.get("attack_multiplier", 1.0)) + bonus_multiplier
			var status := {
				"id": skill_id,
				"name": skill["name"],
				"kind": "buff",
				"stack": "replace",
				"effects": [{"stat": "attack", "type": "percent", "value": multiplier - 1.0}],
				"duration": -1
			}
			session.status_service.add_status(session.player, status)
			session.battle_log.append("%s：攻击力提升 x%.2f，持续整场战斗。" % [skill["name"], multiplier])
			session.last_events.append({"kind": "buff", "target": "player", "amount": 0})
		else:
			var attack_mult := float(skill.get("attack_multiplier", 1.0))
			var status := {
				"id": skill_id,
				"name": skill["name"],
				"kind": "buff",
				"stack": "replace",
				"effects": [{"stat": "attack", "type": "multiply", "value": attack_mult}],
				"duration": -1
			}
			session.status_service.add_status(actor, status)
			session.battle_log.append("%s 使用 %s：攻击力提升 x%.2f。" % [actor["name"], String(skill.get("name", skill_id)), attack_mult])
			session.last_events.append({"kind": "buff", "target": "enemy", "target_index": target_index, "source": actor["name"], "amount": 0})

	elif skill_type == "debuff":
		if is_player:
			var target: int = session._valid_target(target_index)
			if target < 0:
				return
			var bonus_multiplier: float = session._skill_multiplier_bonus(skill_id, "attack")
			var effects: Array[Dictionary] = []
			var mark_multiplier := float(skill.get("mark_multiplier", 0.0))
			if mark_multiplier > 0.0:
				effects.append({"stat": "damage_taken", "type": "percent", "value": mark_multiplier - 1.0 + bonus_multiplier})
			var weaken_multiplier := float(skill.get("weaken_multiplier", 0.0))
			if weaken_multiplier > 0.0:
				effects.append({"stat": "attack", "type": "percent", "value": -(1.0 - weaken_multiplier)})
			var status := {
				"id": skill_id,
				"name": skill["name"],
				"kind": "debuff",
				"stack": "replace",
				"effects": effects,
				"duration": -1
			}
			session.status_service.add_status(session.enemies[target], status)
			session.battle_log.append("%s：%s 受到标记，承受伤害提升，攻击力降低。" % [skill["name"], session.enemies[target]["name"]])
			session.last_events.append({"kind": "debuff", "target": "enemy", "target_index": target, "amount": 0})
		else:
			var weaken_mult := float(skill.get("weaken_multiplier", 1.0))
			var status := {
				"id": skill_id,
				"name": skill["name"],
				"kind": "debuff",
				"stack": "replace",
				"effects": [{"stat": "attack", "type": "multiply", "value": weaken_mult}],
				"duration": -1
			}
			session.status_service.add_status(session.player, status)
			session.battle_log.append("%s 使用 %s：玩家攻击力降低。" % [actor["name"], String(skill.get("name", skill_id))])
			session.last_events.append({"kind": "debuff", "target": "player", "source": actor["name"], "amount": 0})

	else:
		session.message = "该技能暂未实现。"
		return

	if is_player:
		session.action_points -= cost
		session._consume_state_after_action(skill_type)
		session._after_player_action()


func _get_skill_data(skill_id: String) -> Dictionary:
	if DataCatalog.SKILLS.has(skill_id):
		return DataCatalog.SKILLS[skill_id]
	if DataCatalog.INNATE_SKILLS.has(skill_id):
		return DataCatalog.INNATE_SKILLS[skill_id]
	return {}


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
	var skill_id: String = session._enemy_choose_skill(enemy)
	execute_skill(session, skill_id, enemy_index, enemy, false)


func enemy_defend(enemy: Dictionary, scale: float) -> int:
	return Combatant.add_block(enemy, scale)


func enemy_attack(session: RefCounted, enemy: Dictionary, enemy_index: int, first_strike: bool) -> void:
	var segments := enemy_attack_segments(session, enemy, first_strike)
	var player_unit: Dictionary = session._player_combatant()
	var was_hit := false
	for damage in segments:
		var result := Combatant.apply_damage(player_unit, damage, "physical")
		session._sync_player_combatant(player_unit)
		if bool(result["dodged"]):
			session.battle_log.append("躲避了 %s 的一段攻击。" % enemy["name"])
			session.last_events.append({"kind": "dodge_enemy_attack", "target": "player", "source": enemy["name"], "amount": 0})
			session._check_dodge_streak()
			session.status_service.fire_trigger(session.player, TriggerEvents.ON_DODGE, {"battle_log": session.battle_log, "session": session, "source": enemy, "target": session.player})
			if session._has_set_modifier("dynamic:ranger_return") and int(enemy["hp"]) > 0:
				var counter_skill_id: String = session.player["innate_skills"]["attack"]
				var counter_skill: Dictionary = _get_skill_data(counter_skill_id)
				var counter_multiplier: float = float(counter_skill.get("multiplier", 1.0))
				var counter_hits: int = maxi(1, int(counter_skill.get("hits", 1)))
				var counter_attack: int = session._current_attack_value(ActionSource.COUNTER_ATTACK)
				counter_attack = maxi(1, int(round(float(counter_attack) * session._resolve_focus_combo(enemy_index))))
				var counter_hit_damage := maxi(1, int(round(float(counter_attack) * counter_multiplier)))
				var saved_hit_count: int = session.ranger_hit_count
				for _hit in range(counter_hits):
					if int(enemy["hp"]) <= 0:
						break
					var counter_ctx := ActionContext.create_attack(ActionSource.COUNTER_ATTACK, enemy_index, "", "physical", 1)
					counter_ctx["final_damage"] = counter_hit_damage
					session.deal_damage(counter_ctx)
				session.ranger_hit_count = saved_hit_count
				session.battle_log.append("折返：反击 %s，造成 %d 段伤害。" % [enemy["name"], counter_hits])
			continue
		was_hit = true
		session.battle_log.append("%s 攻击：护甲减免 %d，格挡吸收 %d，造成 %d 点伤害。" % [
			enemy["name"],
			int(result["armor_reduced"]),
			int(result["block_absorbed"]),
			int(result["damage"])
		])
		session.last_events.append({"kind": "damage", "target": "player", "source": enemy["name"], "amount": int(result["damage"])})
		session.status_service.fire_trigger(enemy, TriggerEvents.ON_HIT_DEALT, {"battle_log": session.battle_log, "session": session, "source": enemy, "damage": int(result["damage"]), "target": session.player})
		session.status_service.fire_trigger(session.player, TriggerEvents.ON_HIT_RECEIVED, {"battle_log": session.battle_log, "session": session, "source": enemy, "damage": int(result["damage"]), "target": session.player})
	if was_hit:
		session._trigger_counter_attack(enemy_index)


func enemy_attack_segments(session: RefCounted, enemy: Dictionary, first_strike: bool) -> Array[int]:
	return session._enemy_attack_segments(enemy, first_strike)
