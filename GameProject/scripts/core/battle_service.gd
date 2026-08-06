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
const ModifierPipeline = preload("res://scripts/core/modifier_pipeline.gd")
const SkillActionService = preload("res://scripts/core/skill_action_service.gd")
const CharacterService = preload("res://scripts/core/character_service.gd")
const BattleFlow = preload("res://scripts/core/battle/battle_flow.gd")
const HitResolutionModule = preload("res://scripts/core/battle/hit/hit_resolution_module.gd")
const DodgeResolutionModule = preload("res://scripts/core/battle/hit/dodge_resolution_module.gd")
const DamageResolutionModule = preload("res://scripts/core/battle/hit/damage_resolution_module.gd")
const BattleEffectContext = preload("res://scripts/core/battle/skill/battle_effect_context.gd")
const BattleEffectRuntime = preload("res://scripts/core/battle/skill/battle_effect_runtime.gd")
const BattleStepResult = preload("res://scripts/core/battle/battle_step_result.gd")
const EffectDispatcher = preload("res://scripts/core/battle/skill/effect_dispatcher.gd")
const SkillEffectModule = preload("res://scripts/core/battle/skill/skill_effect_module.gd")
const ModifyArmorEffectModule = preload("res://scripts/core/battle/skill/effects/modify_armor_effect_module.gd")
const ApplyStatusEffectModule = preload("res://scripts/core/battle/skill/effects/apply_status_effect_module.gd")
const GainBlockEffectModule = preload("res://scripts/core/battle/skill/effects/gain_block_effect_module.gd")
const GainDodgeEffectModule = preload("res://scripts/core/battle/skill/effects/gain_dodge_effect_module.gd")
const InterruptEffectModule = preload("res://scripts/core/battle/skill/effects/interrupt_effect_module.gd")
const ClearDebuffsEffectModule = preload("res://scripts/core/battle/skill/effects/clear_debuffs_effect_module.gd")
const HealEffectModule = preload("res://scripts/core/battle/skill/effects/heal_effect_module.gd")

const NON_DAMAGE_EFFECT_TYPES: Array[String] = [
	SkillActionService.ACTION_MODIFY_ARMOR,
	SkillActionService.ACTION_APPLY_STATUS,
	SkillActionService.ACTION_GAIN_BLOCK,
	SkillActionService.ACTION_GAIN_DODGE,
	SkillActionService.ACTION_INTERRUPT,
	SkillActionService.ACTION_CLEAR_DEBUFFS,
	SkillActionService.ACTION_HEAL
]

var character_service := CharacterService.new()
var battle_flow := BattleFlow.new()
var effect_dispatcher: RefCounted
var skill_effect_module: RefCounted
var hit_resolution_module: RefCounted
var dodge_resolution_module: RefCounted
var damage_resolution_module: RefCounted


func _init() -> void:
	effect_dispatcher = EffectDispatcher.new()
	skill_effect_module = SkillEffectModule.new(effect_dispatcher)
	hit_resolution_module = HitResolutionModule.new()
	dodge_resolution_module = DodgeResolutionModule.new()
	damage_resolution_module = DamageResolutionModule.new(dodge_resolution_module)
	battle_flow.register_module(dodge_resolution_module)
	effect_dispatcher.register(SkillActionService.ACTION_MODIFY_ARMOR, ModifyArmorEffectModule.new())
	effect_dispatcher.register(SkillActionService.ACTION_APPLY_STATUS, ApplyStatusEffectModule.new())
	effect_dispatcher.register(SkillActionService.ACTION_GAIN_BLOCK, GainBlockEffectModule.new())
	effect_dispatcher.register(SkillActionService.ACTION_GAIN_DODGE, GainDodgeEffectModule.new())
	effect_dispatcher.register(SkillActionService.ACTION_INTERRUPT, InterruptEffectModule.new())
	effect_dispatcher.register(SkillActionService.ACTION_CLEAR_DEBUFFS, ClearDebuffsEffectModule.new())
	effect_dispatcher.register(SkillActionService.ACTION_HEAL, HealEffectModule.new())


func create_hit_context(
	action_context: Dictionary,
	source_actor: Dictionary,
	target_actor: Dictionary,
	parent_action_id: String = "",
	chain_id: String = ""
) -> RefCounted:
	return hit_resolution_module.call("create_hit_context", action_context, source_actor, target_actor, parent_action_id, chain_id)


func dispatch_battle_timing(timing: String, context: RefCounted) -> RefCounted:
	return battle_flow.dispatch_timing(timing, context)


func player_attack(session: RefCounted, target_index: int) -> void:
	session.last_events.clear()
	if not session._can_act():
		return
	var target: int = session._valid_target(target_index)
	if target < 0:
		return
	session.attacked_this_turn = true
	var skill_id: String = session.player["innate_skills"]["attack_1"]
	execute_skill(session, skill_id, target, session.player)
	session.energy = mini(DataCatalog.ENERGY_MAX, session.energy + int(session.player.get("attack_energy_gain", DataCatalog.ATTACK_ENERGY)))
	session.has_acted = true
	session._consume_state_after_action("attack")
	session._after_player_action()


func player_defend(session: RefCounted) -> void:
	session.last_events.clear()
	if not session._can_act():
		return
	var skill_id: String = session.player["innate_skills"]["defend"]
	execute_skill(session, skill_id, -1, session.player)
	session.energy = mini(DataCatalog.ENERGY_MAX, session.energy + DataCatalog.DEFEND_ENERGY)
	session.has_acted = true
	session._consume_state_after_action("defense")
	session._after_player_action()


func player_dodge(session: RefCounted) -> void:
	session.last_events.clear()
	if not session._can_act():
		return
	var skill_id: String = session.player["innate_skills"]["dodge"]
	execute_skill(session, skill_id, -1, session.player)
	session.energy = mini(DataCatalog.ENERGY_MAX, session.energy + DataCatalog.DODGE_ENERGY)
	session.has_acted = true
	session._consume_state_after_action("dodge")
	session._after_player_action()


func use_blood_potion(session: RefCounted) -> bool:
	session.last_events.clear()
	if not session._can_act():
		return false
	var heal_multiplier: float = session.status_service.resolve_stat(session.player, 1.0, StatusService.STAT_HEAL)
	var result: Dictionary = session.character.use_blood_potion(session.player, heal_multiplier)
	if not bool(result.get("used", false)):
		session.message = "血瓶无法使用。"
		return false
	session.has_acted = true
	session._consume_state_after_action("item")
	session.battle_log.append("血瓶：恢复 %d 点生命，剩余 %d 次。" % [int(result["amount"]), int(result["uses_left"])])
	session.last_events.append({"kind": "heal", "target": "player", "amount": int(result["amount"])})
	session.message = "血瓶恢复 %d 点生命。" % int(result["amount"])
	session._after_player_action()
	return true


func use_skill(session: RefCounted, slot_index: int, target_index: int) -> void:
	session.last_events.clear()
	if session.phase != "battle":
		return
	if slot_index < 0 or slot_index >= 4:
		return
	var skill_id := character_service.skill_id_for_slot(session.player, slot_index)
	if skill_id == "":
		session.message = "该技能槽还没有技能。"
		return
	var skill: Dictionary = _get_skill_data(skill_id)
	if skill.is_empty():
		return
	if not session._can_act():
		return
	var energy_cost := maxi(0, int(skill.get("energy_cost", 0)) + int(session.status_service.resolve_stat(session.player, 0.0, StatusService.STAT_ENERGY_COST)))
	if session.energy < energy_cost:
		session.message = "能量不足，需要 %d 点能量。" % energy_cost
		return
	var cooldown := int(skill.get("cooldown", 0))
	if cooldown > 0 and session.skill_cooldowns.get(skill_id, 0) > 0:
		session.message = "%s 冷却中，剩余 %d 回合。" % [skill["name"], int(session.skill_cooldowns[skill_id])]
		return
	var skill_type := String(skill.get("type", "attack"))
	if skill_type == "heal":
		var allied: Array[Dictionary] = session._allied_units(session.player)
		if target_index < 0 or target_index >= allied.size():
			session.message = "请选择一个有效的治疗目标。"
			return
	execute_skill(session, skill_id, target_index, session.player)
	session.energy -= energy_cost
	if cooldown > 0:
		session.skill_cooldowns[skill_id] = cooldown
	session.has_acted = true
	session._consume_state_after_action(skill_type)
	session._after_player_action()


func execute_skill(session: RefCounted, skill_id: String, target_index: int, actor: Dictionary) -> void:
	var skill: Dictionary = _get_skill_data(skill_id)
	if skill.is_empty():
		return
	var skill_type := String(skill.get("type", "attack"))
	var cost := int(skill.get("energy_cost", 0))
	var is_player_actor: bool = actor.get("side", "") == "player"
	var opposing: Array[Dictionary] = session._opposing_units(actor)
	var allied: Array[Dictionary] = session._allied_units(actor)
	if SkillActionService.has_actions(skill):
		_execute_action_skill(session, skill_id, skill, target_index, actor, is_player_actor)
		return

	if skill_type == "attack":
		if is_player_actor:
			var is_aoe := bool(skill.get("aoe", false))
			var skill_damage_type: String = String(skill.get("damage_type", "physical"))
			var extra_hits := int(session.status_service.resolve_stat(session.player, float(session.player.get("extra_hits", 0)), StatusService.STAT_EXTRA_HITS))
			if is_aoe:
				var base_hits := maxi(1, int(skill.get("hits", 1)) + extra_hits)
				# AOE 攻击：对所有敌人造成伤害
				var aoe_damage: int = session._skill_attack_value(skill_id, ActionSource.ACTIVE_ATTACK)
				var aoe_ctx := ActionContext.create_attack(ActionSource.ACTIVE_ATTACK, 0, skill_id, skill_damage_type, 1)
				aoe_ctx["base_damage"] = aoe_damage
				var aoe_ignore_armor := clampf(float(skill.get("ignore_armor", 0.0)), 0.0, 1.0)
				aoe_ctx["armor_multiplier"] = 1.0 - aoe_ignore_armor
				ActionPipeline.compute(aoe_ctx, session)
				for enemy_idx in range(opposing.size()):
					if int(opposing[enemy_idx]["hp"]) <= 0:
						continue
					if session._alive_enemy_count() <= 0:
						break
					for _hit in range(base_hits):
						if int(opposing[enemy_idx]["hp"]) <= 0:
							break
						var hit_ctx := ActionContext.create_attack(ActionSource.ACTIVE_ATTACK, enemy_idx, skill_id, skill_damage_type, 1)
						hit_ctx["final_damage"] = aoe_ctx["final_damage"]
						hit_ctx["is_critical"] = bool(aoe_ctx.get("is_critical", false))
						deal_damage(session, hit_ctx)
				var repeats: int = session._consume_charge_repeat("attack", skill_id)
				for _i in range(repeats):
					for enemy_idx in range(opposing.size()):
						if int(opposing[enemy_idx]["hp"]) <= 0:
							continue
						for _hit in range(base_hits):
							if int(opposing[enemy_idx]["hp"]) <= 0:
								break
							var hit_ctx := ActionContext.create_attack(ActionSource.ACTIVE_ATTACK, enemy_idx, skill_id, skill_damage_type, 1)
							hit_ctx["final_damage"] = aoe_ctx["final_damage"]
							hit_ctx["is_critical"] = bool(aoe_ctx.get("is_critical", false))
							deal_damage(session, hit_ctx)
			else:
				# 单目标攻击
				var target: int = session._valid_target(target_index)
				if target < 0:
					return
				var base_damage: int = session._skill_attack_value(skill_id, ActionSource.ACTIVE_ATTACK)
				var base_hits := maxi(1, int(skill.get("hits", 1)) + extra_hits)
				if skill_id.begins_with("innate_attack_"):
					base_hits = CombatRules.basic_attack_hit_count(actor, opposing[target], session.status_service)
				var skill_ctx := ActionContext.create_attack(ActionSource.ACTIVE_ATTACK, target, skill_id, skill_damage_type, base_hits)
				skill_ctx["base_damage"] = base_damage
				var skill_ignore_armor := clampf(float(skill.get("ignore_armor", 0.0)), 0.0, 1.0)
				skill_ctx["armor_multiplier"] = 1.0 - skill_ignore_armor
				ActionPipeline.compute(skill_ctx, session)
				var armor_reduce := float(skill.get("armor_reduce", 0.0))
				if armor_reduce > 0.0:
					var old_armor := int(opposing[target].get("armor", 0))
					opposing[target]["armor"] = maxi(0, int(round(float(old_armor) * (1.0 - armor_reduce))))
					session.battle_log.append("%s：破甲 %d%%，%s 护甲 %d → %d。" % [skill["name"], int(armor_reduce * 100), opposing[target]["name"], old_armor, int(opposing[target]["armor"])])
				for _hit in range(base_hits):
					if session._alive_enemy_count() <= 0:
						break
					var hit_ctx := ActionContext.create_attack(ActionSource.ACTIVE_ATTACK, target, skill_id, skill_damage_type, 1)
					hit_ctx["final_damage"] = skill_ctx["final_damage"]
					hit_ctx["is_critical"] = bool(skill_ctx.get("is_critical", false))
					deal_damage(session, hit_ctx)
				var repeats: int = session._consume_charge_repeat("attack", skill_id)
				for _i in range(repeats):
					for _hit in range(base_hits):
						if session._alive_enemy_count() <= 0:
							break
						var hit_ctx := ActionContext.create_attack(ActionSource.ACTIVE_ATTACK, target, skill_id, skill_damage_type, 1)
						hit_ctx["final_damage"] = skill_ctx["final_damage"]
						hit_ctx["is_critical"] = bool(skill_ctx.get("is_critical", false))
						deal_damage(session, hit_ctx)
				if session.pending_state_card == "fallback":
					session._add_player_block(maxi(1, int(round(float(session.player["block_power"]) * 0.5))))
				# 横扫/爆裂猛击：对目标左右相邻敌人造成溅射伤害
				if bool(skill.get("splash", false)):
					var splash_mult := float(skill.get("splash_multiplier", 1.0))
					var splash_damage: int = maxi(1, int(ceil(float(skill_ctx["final_damage"]) * splash_mult)))
					for offset in [-1, 1]:
						var splash_idx: int = target + offset
						if splash_idx >= 0 and splash_idx < opposing.size() and splash_idx != target:
							var splash_enemy: Dictionary = opposing[splash_idx]
							if int(splash_enemy["hp"]) > 0:
								var splash_ctx := ActionContext.create_attack(ActionSource.ACTIVE_ATTACK, splash_idx, skill_id, skill_damage_type, 1)
								splash_ctx["final_damage"] = splash_damage
								splash_ctx["is_critical"] = bool(skill_ctx.get("is_critical", false))
								deal_damage(session, splash_ctx)
								session.battle_log.append("%s：溅射 %s，造成 %d 点伤害。" % [skill["name"], splash_enemy["name"], splash_damage])
				# 挑斩：打断目标本回合行动
				if bool(skill.get("interrupt", false)):
					opposing[target]["interrupted"] = true
					session.battle_log.append("%s：打断 %s 的本回合行动。" % [skill["name"], opposing[target]["name"]])
				# 重砍/真空斩：降低目标攻击力
				var weaken_multiplier := float(skill.get("weaken_multiplier", 0.0))
				if weaken_multiplier > 0.0:
					var weaken_status := {
						"id": skill_id,
						"name": skill["name"],
						"kind": "debuff",
						"stack": "replace",
						"effects": [{"stat": "attack", "type": "multiply", "value": weaken_multiplier}],
						"duration": 2
					}
					session.status_service.add_status(opposing[target], weaken_status)
					session.battle_log.append("%s：%s 攻击力降低 %d%%，持续 2 回合。" % [skill["name"], opposing[target]["name"], int((1.0 - weaken_multiplier) * 100)])

			# 碎裂斩：主目标伤害后，对全体敌人造成追加 AOE 伤害
			var aoe_multiplier := float(skill.get("aoe_multiplier", 0.0))
			if aoe_multiplier > 0.0:
				var aoe_damage: int = maxi(1, int(ceil(float(session._current_attack_value(ActionSource.ACTIVE_ATTACK)) * aoe_multiplier)))
				for enemy_idx in range(opposing.size()):
					if int(opposing[enemy_idx]["hp"]) <= 0:
						continue
					var aoe_ctx := ActionContext.create_attack(ActionSource.ACTIVE_ATTACK, enemy_idx, skill_id, skill_damage_type, 1)
					aoe_ctx["final_damage"] = aoe_damage
					deal_damage(session, aoe_ctx)
				session.battle_log.append("%s：碎裂冲击对所有敌人造成 %d 点伤害。" % [skill["name"], aoe_damage])

			# 爆裂猛击：给自己提供格挡
			var self_block_mult := float(skill.get("self_block_multiplier", 0.0))
			if self_block_mult > 0.0:
				var block_gain := maxi(1, int(round(float(session.player["block_power"]) * self_block_mult)))
				session._add_player_block(block_gain)
				session.battle_log.append("%s：获得 %d 点格挡。" % [skill["name"], block_gain])

			# 反击风暴：设置反击状态
			var counter_mult := float(skill.get("counter_attack_multiplier", 0.0))
			var counter_charges := int(skill.get("counter_charges", 0))
			if counter_mult > 0.0 and counter_charges > 0:
				session.counter_stance_charges += counter_charges
				session.counter_attack_multiplier = maxf(session.counter_attack_multiplier, counter_mult)
				session.battle_log.append("%s：接下来受到攻击时反击 %d 次，倍率 x%.2f。" % [skill["name"], counter_charges, counter_mult])

			session.status_service.fire_trigger(session.player, TriggerEvents.ON_ATTACK_COMPLETE, {
				"battle_log": session.battle_log, "session": session, "skill_id": skill_id, "source": session.player
			})
			# 铁血清算：回复造成伤害的百分比
			var heal_percent := float(skill.get("heal_percent", 0.0))
			if heal_percent > 0.0:
				var heal_amount := maxi(1, int(round(float(session._skill_attack_value(skill_id, ActionSource.ACTIVE_ATTACK)) * heal_percent)))
				session.player["hp"] = mini(int(session.player["max_hp"]), int(session.player["hp"]) + heal_amount)
				session.battle_log.append("%s：回复 %d 点 HP。" % [skill["name"], heal_amount])
			# 铁血清算：清除自身 debuff
			if bool(skill.get("clear_debuffs", false)):
				session.status_service.clear_debuffs(session.player)
				session.battle_log.append("%s：清除所有负面效果。" % skill["name"])
			# 铁血清算：对全体敌人施加 DOT
			var dot_mult := float(skill.get("dot_multiplier", 0.0))
			var dot_duration := int(skill.get("dot_duration", 0))
			if dot_mult > 0.0 and dot_duration > 0:
				var dot_damage := maxi(1, int(round(float(session._current_attack_value(ActionSource.ACTIVE_ATTACK)) * dot_mult)))
				var dot_status := {
					"id": skill_id + "_dot",
					"name": skill["name"] + "（流血）",
					"kind": "debuff",
					"stack": "replace",
					"tick_effects": [{"stat": "hp", "type": "flat", "value": float(-dot_damage)}],
					"duration": dot_duration
				}
				for enemy in opposing:
					if int(enemy["hp"]) <= 0:
						continue
					session.status_service.add_status(enemy, dot_status)
				session.battle_log.append("%s：对所有敌人造成流血效果，每回合 %d 点伤害，持续 %d 回合。" % [skill["name"], dot_damage, dot_duration])
		else:
			if skill_id.begins_with("innate_attack_"):
				enemy_attack(session, actor, target_index, false)
				return
			var player_unit: Dictionary = opposing[0]
			var base_damage: int = CombatRules.skill_attack_value_for_actor(actor, skill_id, session.status_service)
			var hits := maxi(1, int(skill.get("hits", 1)))
			var was_hit := false
			for _hit in range(hits):
				if int(player_unit["hp"]) <= 0:
					break
				var result := deal_damage_to_target(player_unit, base_damage, String(skill.get("damage_type", "physical")), session, actor)
				session._sync_player_combatant(player_unit)
				if bool(result["dodged"]):
					session.battle_log.append("躲避了 %s 的 %s。" % [actor["name"], skill["name"]])
					session.last_events.append({"kind": "dodge_enemy_attack", "target": "player", "source": actor["name"], "amount": 0})
				else:
					was_hit = true
					session.battle_log.append("%s 使用 %s：造成 %d 点伤害。" % [actor["name"], String(skill.get("name", skill_id)), int(result["damage"])])
					session.last_events.append({"kind": "damage", "target": "player", "source": actor["name"], "amount": int(result["damage"])})
			if was_hit:
				CombatRules.apply_rat_on_hit(actor, session.player, session.status_service)
				var armor_reduction := int(skill.get("armor_reduction", 0))
				if armor_reduction > 0:
					CombatRules.apply_armor_reduction(session.player, armor_reduction, session.status_service, String(skill["name"]))
				session._trigger_counter_attack(target_index)

	elif skill_type == "summon":
		if not is_player_actor:
			for _i in range(2):
				session.enemies.append(Combatant.rat_minion(session.floor_index, session.round_index + 1))
			session.battle_log.append("%s 使用 %s：召唤两只小鼠。" % [actor["name"], skill["name"]])

	elif skill_type == "defense" or skill_type == "stance":
		var bonus: float = session._skill_multiplier_bonus(skill_id, "defense") if is_player_actor else 0.0
		var extra_modifiers: Array[Dictionary] = []
		if is_player_actor:
			extra_modifiers = ModifierPipeline.collect_from_session(session, "defense", {"skill_id": skill_id, "skill_multiplier": float(skill.get("multiplier", skill.get("block_multiplier", 1.0))) + bonus})
		var gained: int = CombatRules.skill_defense_value_for_actor(actor, skill_id, session.status_service, bonus, extra_modifiers)
		gained = session._apply_charge_defense_modifiers(gained, skill_id)
		var total_gained := gained
		var repeats: int = session._consume_charge_repeat("defense", skill_id)
		for _i in range(repeats):
			total_gained += gained
		if is_player_actor:
			session._add_player_block(total_gained)
			session.battle_log.append("%s：获得 %d 点格挡值。" % [skill["name"], total_gained])
			session.last_events.append({"kind": "defense", "target": "player", "amount": total_gained})
			if skill_type == "stance":
				session.counter_stance_charges += 1
				session.counter_attack_multiplier = maxf(session.counter_attack_multiplier, float(skill.get("counter_multiplier", 1.0)) + session._skill_multiplier_bonus(skill_id, "attack"))
				session.battle_log.append("%s：准备反击下一次命中自身的敌方攻击，反击倍率 x%.2f。" % [skill["name"], session.counter_attack_multiplier])
		else:
			Combatant.add_block_amount(actor, total_gained)
			session.battle_log.append("%s 使用 %s：获得 %d 点格挡。" % [actor["name"], String(skill.get("name", skill_id)), total_gained])
			session.last_events.append({"kind": "defense", "target": "enemy", "target_index": target_index, "source": actor["name"], "amount": total_gained})
			if skill_id == "enemy_shadow_armor":
				actor["shadow_armor_active"] = true

	elif skill_type == "dodge":
		if is_player_actor:
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
		var gained: int = Combatant.add_block(actor, float(skill.get("block_multiplier", 1.0)))
		session.battle_log.append("%s 使用 %s：嘲讽并防守，获得 %d 点格挡。" % [actor["name"], String(skill.get("name", skill_id)), gained])
		session.last_events.append({"kind": "defense", "target": "enemy", "target_index": target_index, "source": actor["name"], "amount": gained})

	elif skill_type == "heal":
		if target_index < 0 or target_index >= allied.size():
			return
		var heal_target: Dictionary = allied[target_index]
		var bonus: float = session._skill_multiplier_bonus(skill_id, "hp") if is_player_actor else 0.0
		var healed: int = CombatRules.skill_heal_value_for_actor(actor, skill_id, session.status_service, bonus)
		heal_target["hp"] = mini(int(heal_target["max_hp"]), int(heal_target["hp"]) + healed)
		if is_player_actor:
			if target_index == 0:
				session._sync_player_combatant(heal_target)
			session.battle_log.append("%s：恢复 %s %d 点生命。" % [skill["name"], heal_target["name"], healed])
			session.last_events.append({"kind": "heal", "target": "player", "amount": healed})
		else:
			session.battle_log.append("%s 使用 %s：恢复 %d 点生命。" % [actor["name"], String(skill.get("name", skill_id)), healed])
			session.last_events.append({"kind": "heal", "target": "enemy", "target_index": target_index, "source": actor["name"], "amount": healed})

	elif skill_type == "buff":
		var effects: Array[Dictionary] = _build_buff_effects(skill, skill_id, is_player_actor, session)
		var status := {
			"id": skill_id,
			"name": skill["name"],
			"kind": "buff",
			"stack": "replace",
			"effects": effects,
			"duration": int(skill.get("duration", -1))
		}
		# 每回合效果（回血/扣血等）
		var tick_effects: Array = skill.get("tick_effects", [])
		if not tick_effects.is_empty():
			status["tick_effects"] = tick_effects
		# 反伤
		var reflect_mult := float(skill.get("reflect_multiplier", 0.0))
		if reflect_mult > 0.0:
			status["reflect_multiplier"] = reflect_mult
		# 延迟伤害
		var deferred_pct := float(skill.get("deferred_damage_percent", 0.0))
		if deferred_pct > 0.0:
			status["deferred_damage_percent"] = deferred_pct
		session.status_service.add_status(actor, status)
		if is_player_actor:
			_buff_log_message(skill, status, session)
			session.last_events.append({"kind": "buff", "target": "player", "amount": 0})
		else:
			session.battle_log.append("%s 使用 %s。" % [actor["name"], String(skill.get("name", skill_id))])
			session.last_events.append({"kind": "buff", "target": "enemy", "target_index": target_index, "source": actor["name"], "amount": 0})

	elif skill_type == "debuff":
		var debuff_target: Dictionary
		var target: int = -1
		if is_player_actor:
			target = session._valid_target(target_index)
			if target < 0:
				return
			debuff_target = opposing[target]
		else:
			debuff_target = opposing[0]
		var bonus_multiplier: float = session._skill_multiplier_bonus(skill_id, "attack") if is_player_actor else 0.0
		var effects: Array[Dictionary] = []
		var mark_multiplier := float(skill.get("mark_multiplier", 0.0))
		if mark_multiplier > 0.0:
			effects.append({"stat": "damage_taken", "type": "multiply", "value": mark_multiplier + bonus_multiplier})
		var weaken_multiplier := float(skill.get("weaken_multiplier", 0.0))
		if weaken_multiplier > 0.0:
			effects.append({"stat": "attack", "type": "multiply", "value": weaken_multiplier})
		if effects.is_empty():
			effects.append({"stat": "attack", "type": "multiply", "value": float(skill.get("weaken_multiplier", 1.0))})
		var status := {
			"id": skill_id,
			"name": skill["name"],
			"kind": "debuff",
			"stack": "replace",
			"effects": effects,
			"duration": -1
		}
		session.status_service.add_status(debuff_target, status)
		if is_player_actor:
			session.battle_log.append("%s：%s 受到标记，承受伤害提升，攻击力降低。" % [skill["name"], debuff_target["name"]])
			session.last_events.append({"kind": "debuff", "target": "enemy", "target_index": target, "amount": 0})
		else:
			session.battle_log.append("%s 使用 %s：玩家攻击力降低。" % [actor["name"], String(skill.get("name", skill_id))])
			session.last_events.append({"kind": "debuff", "target": "player", "source": actor["name"], "amount": 0})

	elif skill_type == "duel":
		if is_player_actor:
			var target: int = session._valid_target(target_index)
			if target < 0:
				return
			session.duel_target_index = target
			# 给玩家加攻击 buff
			var duel_buff := {
				"id": skill_id,
				"name": skill["name"],
				"kind": "buff",
				"stack": "replace",
				"effects": [{"stat": "attack", "type": "multiply", "value": float(skill.get("attack_multiplier", 2.0))}],
				"duration": -1
			}
			session.status_service.add_status(actor, duel_buff)
			session.battle_log.append("%s：与 %s 进入单挑，伤害提升 x%.2f，免疫其他敌人伤害。" % [skill["name"], opposing[target]["name"], float(skill.get("attack_multiplier", 2.0))])
			session.last_events.append({"kind": "duel", "target": "enemy", "target_index": target, "amount": 0})

	elif skill_type == "deflect":
		if is_player_actor:
			session.perfect_deflect = true
			session.battle_log.append("%s：下一回合免疫所有敌人攻击并反弹伤害。" % skill["name"])
			session.last_events.append({"kind": "deflect", "target": "player", "amount": 0})

	else:
		session.message = "该技能暂未实现。"
		return


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
	# 玩家行动后执行本回合剩余的 AI 单位；敌人先手时，先手段已经在
	# _begin_player_turn() 中执行，这里只会执行玩家之后的单位。
	enemy_turn(session, false)
	if session._opposing_units_alive() > 0 and int(session.player["hp"]) > 0:
		session._begin_player_turn()


func enemy_turn(session: RefCounted, before_player: bool = false) -> void:
	var action_order := CombatRules.action_order(session.player, session.enemies, session.allies, session.status_service, session.round_index)
	var player_position := -1
	for order_index in range(action_order.size()):
		if String(action_order[order_index].get("type", "")) == "player":
			player_position = order_index
			break
	if before_player or player_position == 0:
		session._clear_enemy_blocks()
		session._clear_enemy_taunts()
	for order_index in range(action_order.size()):
		var entry: Dictionary = action_order[order_index]
		var actor_type := String(entry.get("type", ""))
		if actor_type == "player":
			continue
		var is_before_player := player_position >= 0 and order_index < player_position
		if is_before_player != before_player:
			continue
		var actor: Dictionary = entry.get("unit", {})
		var actor_index := int(entry.get("index", -1))
		if int(actor.get("hp", 0)) <= 0:
			continue
		if bool(actor.get("interrupted", false)):
			actor["interrupted"] = false
			session.battle_log.append("%s 被中断，本回合无法行动。" % actor["name"])
			continue
		resolve_enemy_action(session, actor, actor_index)
		if int(session.player.get("hp", 0)) <= 0:
			break
	if before_player:
		session.ai_turn_stage = "after_player_pending"
		return

	for enemy in session.enemies:
		if int(enemy["hp"]) <= 0:
			continue
		session.status_service.fire_trigger(enemy, TriggerEvents.ON_TURN_END, {"battle_log": session.battle_log, "session": session, "round_index": session.round_index})
	for ally in session.allies:
		if int(ally["hp"]) <= 0 or String(ally.get("controlled_by", "")) != "ai":
			continue
		session.status_service.fire_trigger(ally, TriggerEvents.ON_TURN_END, {"battle_log": session.battle_log, "session": session, "round_index": session.round_index})
	if int(session.player["hp"]) <= 0:
		session.ai_turn_stage = "complete"
		session._on_defeat()
		return

	# 回合结束特性结算：corrode 腐蚀玩家护甲，support 治疗友军
	CombatRules.apply_end_round_traits(session.player, session.enemies, session.round_index, session.status_service, session.battle_log)
	CombatRules.apply_arena_effects(session.player, session.enemies, session.round_index, session.status_service, session.allies, session.battle_log, session.scene_skill_sources)
	session.ai_turn_stage = "complete"


func resolve_enemy_action(session: RefCounted, enemy: Dictionary, enemy_index: int) -> void:
	var skill_id: String = session._enemy_choose_skill(enemy)
	execute_skill(session, skill_id, enemy_index, enemy)
	var skill: Dictionary = _get_skill_data(skill_id)
	var cooldown := int(skill.get("cooldown", 0))
	if cooldown > 0:
		enemy["skill_cooldowns"][skill_id] = cooldown


func enemy_defend(enemy: Dictionary, scale: float) -> int:
	return Combatant.add_block(enemy, scale)


func enemy_attack(session: RefCounted, enemy: Dictionary, enemy_index: int, first_strike: bool, allow_swarm: bool = true) -> void:
	# 决斗免疫：非决斗目标的敌人攻击无效
	if session.duel_target_index >= 0 and enemy_index != session.duel_target_index:
		session.battle_log.append("%s 被单挑领域阻挡，无法攻击。" % enemy["name"])
		return
	var segments := enemy_attack_segments(session, enemy, first_strike)
	var player_unit: Dictionary = session._player_combatant()
	var dodge_counted := false
	# 完美偏转：免疫所有伤害并反弹给所有敌人
	if session.perfect_deflect:
		var total_reflect := 0
		for damage in segments:
			total_reflect += damage
		total_reflect = maxi(1, total_reflect)
		session.battle_log.append("力拨千斤：完美偏转 %s 的攻击，反弹 %d 点伤害！" % [enemy["name"], total_reflect])
		for i in range(session.enemies.size()):
			if int(session.enemies[i]["hp"]) <= 0:
				continue
			var reflect_ctx := ActionContext.create_attack(ActionSource.COUNTER_ATTACK, i, "", "physical", 1)
			reflect_ctx["final_damage"] = total_reflect
			deal_damage(session, reflect_ctx)
		return
	var was_hit := false
	for damage in segments:
		var result := deal_damage_to_target(player_unit, damage, "physical", session, enemy)
		session._sync_player_combatant(player_unit)
		if bool(result["dodged"]):
			session.battle_log.append("躲避了 %s 的一段攻击。" % enemy["name"])
			session.last_events.append({"kind": "dodge_enemy_attack", "target": "player", "source": enemy["name"], "amount": 0})
			if not dodge_counted:
				session._check_dodge_streak()
				dodge_counted = true
			session.status_service.fire_trigger(session.player, TriggerEvents.ON_DODGE, {"battle_log": session.battle_log, "session": session, "source": enemy, "target": session.player})
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
		# 延迟伤害追踪
		var deferred_pct := 0.0
		for status in session.player.get("statuses", []):
			deferred_pct = maxf(deferred_pct, float(status.get("deferred_damage_percent", 0.0)))
		if deferred_pct > 0.0:
			session.deferred_damage += float(int(result["damage"])) * deferred_pct
	if was_hit:
		CombatRules.apply_rat_on_hit(enemy, session.player, session.status_service)
		session._trigger_counter_attack(enemy_index)
		session._trigger_reflect_damage(enemy_index)
	if allow_swarm and not first_strike:
		_trigger_swarm_assists(session, enemy, enemy_index)


func _trigger_swarm_assists(session: RefCounted, attacker: Dictionary, attacker_index: int) -> void:
	if not attacker.get("passive_skills", []).has("swarm"):
		return
	for index in range(session.enemies.size()):
		var ally: Dictionary = session.enemies[index]
		if index == attacker_index or int(ally.get("hp", 0)) <= 0 or not ally.get("passive_skills", []).has("swarm"):
			continue
		session.battle_log.append("群袭：%s 协攻。" % ally["name"])
		enemy_attack(session, ally, index, false, false)


func enemy_attack_segments(session: RefCounted, enemy: Dictionary, first_strike: bool) -> Array[int]:
	return session._enemy_attack_segments(enemy, first_strike)


func deal_damage(session: RefCounted, ctx: Dictionary) -> void:
	var source := String(ctx.get("source", ""))
	var target_index := int(ctx.get("target_index", 0))
	var damage := int(ctx.get("final_damage", 0))
	var damage_type := String(ctx.get("damage_type", "physical"))
	var ignore_taunt := not ActionSource.is_interactive(source)
	var raw_source_actor: Variant = ctx.get("source_actor", {})
	var source_actor: Dictionary = raw_source_actor if typeof(raw_source_actor) == TYPE_DICTIONARY and not (raw_source_actor as Dictionary).is_empty() else session.player
	var action_armor_multiplier := float(ctx.get("armor_multiplier", -1.0))

	if not ignore_taunt and String(source_actor.get("side", "player")) == "player":
		var taunt_target: int = session._active_taunt_target()
		if taunt_target >= 0:
			target_index = taunt_target
			ctx["target_index"] = target_index

	var target_pool: Array[Dictionary] = session._opposing_units(source_actor)
	var target: Dictionary = target_pool[target_index]
	var result := deal_damage_to_target(target, damage, damage_type, session, source_actor, action_armor_multiplier)
	var target_side := "enemy" if String(source_actor.get("side", "player")) == "player" else "player"
	if target_side == "player" and target_index == 0:
		session._sync_player_combatant(target)
	if bool(result["dodged"]):
		session.battle_log.append("%s 闪避了这次命中。" % target["name"])
		session.last_events.append({"kind": "dodge_enemy_attack", "target": target_side, "target_index": target_index, "amount": 0})
		session.status_service.fire_trigger(target, TriggerEvents.ON_DODGE, {"battle_log": session.battle_log, "session": session, "source": source_actor})
		return

	var is_critical := bool(ctx.get("is_critical", false))
	var hit_label := "暴击命中" if is_critical else "命中"
	session.battle_log.append("%s %s：护甲减免 %d，格挡吸收 %d，造成 %d 点伤害。" % [hit_label, target["name"],
		int(result["armor_reduced"]),
		int(result["block_absorbed"]),
		int(result["damage"])
	])
	session.last_events.append({"kind": "damage", "target": target_side, "target_index": target_index, "amount": int(result["damage"]), "critical": is_critical})

	if ActionSource.is_interactive(source):
		var hit_context := {
			"battle_log": session.battle_log,
			"session": session,
			"source": source_actor,
			"damage": int(result["damage"]),
			"target": target,
			"is_critical": is_critical,
			"damage_type": damage_type
		}
		if is_critical:
			session.status_service.fire_trigger(source_actor, TriggerEvents.ON_CRITICAL, hit_context)
		session.status_service.fire_trigger(source_actor, TriggerEvents.ON_HIT_DEALT, hit_context)
		session.status_service.fire_trigger(target, TriggerEvents.ON_HIT_RECEIVED, hit_context)
		if int(target["hp"]) <= 0:
			session.status_service.fire_trigger(source_actor, TriggerEvents.ON_KILL, {"battle_log": session.battle_log, "session": session, "source": source_actor, "target": target})
			if session.duel_target_index >= 0 and target_pool == session.enemies and target_index == session.duel_target_index:
				session.duel_target_index = -1
				session.battle_log.append("单挑领域：决斗目标已死亡，单挑结束。")


func deal_damage_to_target(
	target: Dictionary,
	raw_damage: int,
	damage_type: String,
	session: RefCounted,
	attacker: Dictionary = {},
	action_armor_multiplier: float = -1.0
) -> Dictionary:
	var runtime := BattleEffectRuntime.new(session)
	return damage_resolution_module.call("resolve", target, raw_damage, damage_type, runtime, attacker, action_armor_multiplier)


# 回合结束时处理 corrode（腐蚀）和 support（辅助）特性效果，委托给 CombatRules 统一处理
func _apply_end_round_traits(session: RefCounted) -> void:
	CombatRules.apply_end_round_traits(session.player, session.enemies, session.round_index, session.status_service, session.battle_log)
	CombatRules.apply_arena_effects(session.player, session.enemies, session.round_index, session.status_service, session.allies, session.battle_log, session.scene_skill_sources)


func _build_buff_effects(skill: Dictionary, skill_id: String, is_player_actor: bool, session: RefCounted) -> Array[Dictionary]:
	var raw_effects: Array = skill.get("effects", [])
	if raw_effects.is_empty():
		# 兼容旧版 buff（仅 attack_multiplier）
		var bonus: float = session._skill_multiplier_bonus(skill_id, "attack") if is_player_actor else 0.0
		var multiplier: float = float(skill.get("attack_multiplier", 1.0)) + bonus
		return [{"stat": "attack", "type": "multiply", "value": multiplier}]
	# 新版 buff：解析 effects 中的 skill_multiplier_bonus
	var result: Array[Dictionary] = []
	for raw_eff in raw_effects:
		var eff: Dictionary = raw_eff
		var eff_copy := eff.duplicate(true)
		if String(eff.get("stat", "")) == "attack" and String(eff.get("type", "")) == "multiply":
			var bonus: float = session._skill_multiplier_bonus(skill_id, "attack") if is_player_actor else 0.0
			eff_copy["value"] = float(eff["value"]) + bonus
		result.append(eff_copy)
	return result


func _execute_action_skill(session: RefCounted, skill_id: String, skill: Dictionary, target_index: int, actor: Dictionary, is_player_actor: bool) -> void:
	if not is_player_actor:
		_execute_enemy_action_skill(session, skill_id, skill, target_index, actor)
		return
	var attack_repeat_bonus := -1
	var defense_repeat_bonus := -1
	for action in SkillActionService.actions(skill):
		var action_type := String(action.get("type", ""))
		if not _action_conditions_met(session, skill_id, action, target_index, actor, true):
			continue
		var block_repeat_bonus := 0
		if action_type == SkillActionService.ACTION_GAIN_BLOCK and String(action.get("charge_tag", "")) == "defense" and bool(action.get("repeat_with_charge", true)):
			if defense_repeat_bonus < 0:
				defense_repeat_bonus = session._consume_charge_repeat("defense", skill_id)
			block_repeat_bonus = defense_repeat_bonus
		if _is_registered_non_damage_action(action_type):
			_execute_registered_non_damage_effect(session, skill_id, skill, action, target_index, actor, true, block_repeat_bonus)
			continue
		match action_type:
			SkillActionService.ACTION_DAMAGE:
				var damage_repeat_bonus := 0
				if bool(action.get("repeat_with_charge", true)):
					if attack_repeat_bonus < 0:
						attack_repeat_bonus = session._consume_charge_repeat("attack", skill_id)
						damage_repeat_bonus = attack_repeat_bonus
				_execute_action_damage(session, skill_id, skill, action, target_index, damage_repeat_bonus)
			SkillActionService.ACTION_SET_COUNTER_ATTACK:
				_execute_action_set_counter_attack(session, skill_id, action)
			SkillActionService.ACTION_SET_DUEL:
				_execute_action_set_duel(session, skill_id, skill, action, target_index)
			SkillActionService.ACTION_SET_DEFLECT:
				_execute_action_set_deflect(session)
			SkillActionService.ACTION_SUMMON:
				_execute_action_summon(session, skill_id, action, actor, true)
			_:
				_report_unknown_action(session, skill_id, action_type)


func _action_conditions_met(session: RefCounted, skill_id: String, action: Dictionary, target_index: int, actor: Dictionary, is_player_actor: bool) -> bool:
	var raw_conditions: Variant = action.get("conditions", [])
	var conditions: Array = raw_conditions if typeof(raw_conditions) == TYPE_ARRAY else []
	if conditions.is_empty() and action.has("condition"):
		conditions = [action.get("condition", {})]
	if conditions.is_empty():
		return true
	return session.status_service.evaluate_conditions(actor, conditions, _action_condition_context(session, skill_id, action, target_index, actor, is_player_actor))


func _action_condition_context(session: RefCounted, skill_id: String, action: Dictionary, target_index: int, actor: Dictionary, is_player_actor: bool) -> Dictionary:
	return {
		"session": session,
		"source": actor,
		"target": _action_target_dictionary(session, action, target_index, actor, is_player_actor),
		"target_index": target_index,
		"skill_id": skill_id,
		"enemy_count": session._alive_enemy_count(),
		"round_index": session.round_index,
		"state_card": session.pending_state_card
	}


func _action_target_dictionary(session: RefCounted, action: Dictionary, target_index: int, actor: Dictionary, is_player_actor: bool) -> Dictionary:
	var target_mode := String(action.get("target", SkillActionService.TARGET_SELECTED))
	if target_mode == SkillActionService.TARGET_SELF:
		return actor
	if is_player_actor:
		if target_mode == SkillActionService.TARGET_ALLY_SELECTED:
			var allied: Array[Dictionary] = session._allied_units(session.player)
			if target_index >= 0 and target_index < allied.size():
				return allied[target_index]
			return {}
		var enemy_index: int = session._valid_target(target_index)
		if enemy_index >= 0 and enemy_index < session.enemies.size():
			return session.enemies[enemy_index]
		return {}
	var player_side: Array[Dictionary] = session._player_side_units()
	if target_mode == SkillActionService.TARGET_ALL_ENEMIES or target_mode == SkillActionService.TARGET_SELECTED:
		return _enemy_action_target(session, 0) if not player_side.is_empty() else {}
	return {}


func _report_unknown_action(session: RefCounted, skill_id: String, action_type: String) -> void:
	var message := "[ERROR] 未知 action '%s'（技能 %s）。" % [action_type, skill_id]
	push_error(message)
	session.battle_log.append(message)
	session.message = message


func _execute_enemy_action_skill(session: RefCounted, skill_id: String, skill: Dictionary, target_index: int, actor: Dictionary) -> void:
	for action in SkillActionService.actions(skill):
		var action_type := String(action.get("type", ""))
		if not _action_conditions_met(session, skill_id, action, 0, actor, false):
			continue
		if _is_registered_non_damage_action(action_type):
			_execute_registered_non_damage_effect(session, skill_id, skill, action, 0, actor, false)
			continue
		match action_type:
			SkillActionService.ACTION_DAMAGE:
				_execute_enemy_action_damage(session, skill_id, skill, action, actor)
			SkillActionService.ACTION_SUMMON:
				_execute_action_summon(session, skill_id, action, actor, false)
			_:
				_report_unknown_action(session, skill_id, action_type)


func _is_registered_non_damage_action(action_type: String) -> bool:
	return action_type in NON_DAMAGE_EFFECT_TYPES


func _execute_registered_non_damage_effect(
	session: RefCounted,
	skill_id: String,
	skill: Dictionary,
	action: Dictionary,
	target_index: int,
	actor: Dictionary,
	is_player_actor: bool,
	repeat_bonus: int = 0
) -> void:
	var runtime := BattleEffectRuntime.new(session)
	var context := BattleEffectContext.new(runtime, actor, skill, skill_id, action, target_index, is_player_actor, repeat_bonus)
	var result: RefCounted = skill_effect_module.execute_action(action, context, false)
	if String(result.get("kind")) == BattleStepResult.ERROR:
		var message: String = String(result.get("message"))
		if message == "":
			message = "技能效果执行失败。"
		session.battle_log.append(message)
		session.message = message


func _enemy_action_target_indexes(session: RefCounted, action: Dictionary) -> Array[int]:
	var target_mode := String(action.get("target", SkillActionService.TARGET_SELECTED))
	var player_side: Array[Dictionary] = session._player_side_units()
	var result: Array[int] = []
	match target_mode:
		SkillActionService.TARGET_ALL_ENEMIES:
			for index in range(player_side.size()):
				if int(player_side[index].get("hp", 0)) > 0:
					result.append(index)
		SkillActionService.TARGET_ADJACENT:
			for index in range(player_side.size()):
				if int(player_side[index].get("hp", 0)) > 0:
					result.append(index)
		SkillActionService.TARGET_SELF:
			return result
		_:
			if not player_side.is_empty() and int(player_side[0].get("hp", 0)) > 0:
				result.append(0)
	return result


func _enemy_action_target(session: RefCounted, target_index: int) -> Dictionary:
	if target_index == 0:
		return session.player
	var ally_index := target_index - 1
	if ally_index >= 0 and ally_index < session.allies.size():
		return session.allies[ally_index]
	return {}


func _execute_enemy_action_damage(session: RefCounted, skill_id: String, skill: Dictionary, action: Dictionary, actor: Dictionary) -> void:
	var targets := _enemy_action_target_indexes(session, action)
	if targets.is_empty():
		return
	var hits := maxi(1, int(action.get("hits", skill.get("hits", 1))))
	var multiplier := float(action.get("multiplier", skill.get("multiplier", 1.0)))
	var damage_type := String(action.get("damage_type", skill.get("damage_type", "physical")))
	var ignore_armor := clampf(float(action.get("ignore_armor", skill.get("ignore_armor", 0.0))), 0.0, 1.0)
	var base_damage := _enemy_action_attack_value(actor, multiplier, session)
	for target_index in targets:
		for _hit in range(hits):
			if target_index < 0 or target_index >= session._player_side_units().size():
				continue
			var hit_ctx := ActionContext.create_attack(ActionSource.ENEMY_ATTACK, target_index, skill_id, damage_type, 1)
			hit_ctx["final_damage"] = base_damage
			hit_ctx["source_actor"] = actor
			hit_ctx["armor_multiplier"] = 1.0 - ignore_armor
			deal_damage(session, hit_ctx)


func _enemy_action_attack_value(actor: Dictionary, multiplier: float, session: RefCounted) -> int:
	var attack: float = session.status_service.resolve_stat(actor, float(actor.get("attack", 1)), StatusService.STAT_ATTACK)
	var rank_multiplier := 1.0
	if not bool(actor.get("fixed_stats", false)):
		rank_multiplier = CombatRules.RANK_SKILL_MULTIPLIER.get(String(actor.get("rank", "normal")), 1.0)
	return maxi(1, int(ceil(attack * multiplier * rank_multiplier)))


func _execute_action_summon(session: RefCounted, skill_id: String, action: Dictionary, actor: Dictionary, is_player_actor: bool) -> void:
	var count := maxi(1, int(action.get("count", 1)))
	var delay := maxi(0, int(action.get("delay", 1)))
	var raw_unit: Variant = action.get("unit", action.get("unit_id", "rat_minion"))
	var unit_template: Dictionary = {}
	if typeof(raw_unit) == TYPE_DICTIONARY:
		unit_template = (raw_unit as Dictionary).duplicate(true)
	else:
		var unit_id := String(raw_unit)
		if unit_id in ["rat", "rat_minion", "mouse"]:
			unit_template = {"id": "rat_minion", "name": "小鼠", "fixed_stats": true, "hp": 20, "attack": 5, "defense": 0, "block_power": 0, "passive_skills": ["swarm", "", "", ""], "skills": []}
		else:
			unit_template = DataCatalog.monster_unit(unit_id)
	if unit_template.is_empty():
		_report_unknown_action(session, skill_id, "summon:%s" % String(raw_unit))
		return
	for _i in range(count):
		var summoned := Combatant.from_enemy_unit(unit_template, "normal", session.floor_index)
		summoned["available_round"] = session.round_index + delay
		if is_player_actor:
			summoned["side"] = "ally"
			summoned["controlled_by"] = "ai"
			session.allies.append(summoned)
		else:
			session.enemies.append(summoned)
	session.battle_log.append("%s 使用 %s：召唤 %d 个单位。" % [actor.get("name", "角色"), skill_id, count])


func _execute_action_damage(session: RefCounted, skill_id: String, skill: Dictionary, action: Dictionary, target_index: int, repeat_bonus: int) -> void:
	var targets := _action_target_indexes(session, action, target_index)
	if targets.is_empty():
		return
	var extra_hits := int(session.status_service.resolve_stat(session.player, float(session.player.get("extra_hits", 0)), StatusService.STAT_EXTRA_HITS)) if bool(action.get("include_extra_hits", true)) else 0
	var hits := maxi(1, int(action.get("hits", skill.get("hits", 1))) + extra_hits)
	var multiplier: float = float(action.get("multiplier", skill.get("multiplier", 1.0))) + session._skill_multiplier_bonus(skill_id, "attack")
	var damage_type := String(action.get("damage_type", skill.get("damage_type", "physical")))
	var ignore_armor := clampf(float(action.get("ignore_armor", skill.get("ignore_armor", 0.0))), 0.0, 1.0)
	var repeat_count := 1 + repeat_bonus if bool(action.get("repeat_with_charge", true)) else 1
	for _repeat in range(repeat_count):
		for target in targets:
			if session._alive_enemy_count() <= 0:
				return
			if target < 0 or target >= session.enemies.size() or int(session.enemies[target]["hp"]) <= 0:
				continue
			for _hit in range(hits):
				if session._alive_enemy_count() <= 0:
					return
				if target < 0 or target >= session.enemies.size() or int(session.enemies[target]["hp"]) <= 0:
					continue
				var base_damage := _action_attack_value(session, skill_id, multiplier, ActionSource.ACTIVE_ATTACK)
				var hit_ctx := ActionContext.create_attack(ActionSource.ACTIVE_ATTACK, target, skill_id, damage_type, 1)
				hit_ctx["base_damage"] = base_damage
				hit_ctx["armor_multiplier"] = 1.0 - ignore_armor
				ActionPipeline.compute(hit_ctx, session)
				deal_damage(session, hit_ctx)


func _execute_action_set_counter_attack(session: RefCounted, skill_id: String, action: Dictionary) -> void:
	var charges := int(action.get("charges", 0))
	var multiplier: float = float(action.get("multiplier", 1.0))
	var bonus_stat := String(action.get("skill_bonus_stat", ""))
	if bonus_stat != "":
		multiplier += session._skill_multiplier_bonus(skill_id, bonus_stat)
	if charges <= 0:
		return
	session.counter_stance_charges += charges
	session.counter_attack_multiplier = maxf(session.counter_attack_multiplier, multiplier)


func _execute_action_set_duel(session: RefCounted, skill_id: String, skill: Dictionary, action: Dictionary, target_index: int) -> void:
	var target: int = session._valid_target(target_index)
	if target < 0:
		return
	session.duel_target_index = target
	var multiplier: float = float(action.get("multiplier", 1.0))
	var bonus_stat := String(action.get("skill_bonus_stat", ""))
	if bonus_stat != "":
		multiplier += session._skill_multiplier_bonus(skill_id, bonus_stat)
	var duel_buff := {
		"id": skill_id,
		"name": skill["name"],
		"kind": "buff",
		"stack": "replace",
		"effects": [{"stat": "attack", "type": "multiply", "value": multiplier}],
		"duration": int(action.get("duration", -1))
	}
	session.status_service.add_status(session.player, duel_buff)
	session.last_events.append({"kind": "duel", "target": "enemy", "target_index": target, "amount": 0})


func _execute_action_set_deflect(session: RefCounted) -> void:
	session.perfect_deflect = true
	session.last_events.append({"kind": "deflect", "target": "player", "amount": 0})


func _action_attack_value(session: RefCounted, skill_id: String, multiplier: float, action_source: String) -> int:
	var resolved_attack: float = session.status_service.resolve_stat(session.player, float(session.player["attack"]), StatusService.STAT_ATTACK)
	var modifiers: Array = ModifierPipeline.collect_from_session(session, "attack", {"skill_id": skill_id, "skill_multiplier": multiplier}, action_source)
	return maxi(1, int(ceil(ModifierPipeline.resolve(resolved_attack, modifiers))))


func _action_target_indexes(session: RefCounted, action: Dictionary, target_index: int) -> Array[int]:
	var target_mode := String(action.get("target", SkillActionService.TARGET_SELECTED))
	var result: Array[int] = []
	match target_mode:
		SkillActionService.TARGET_ALL_ENEMIES:
			for i in range(session.enemies.size()):
				if int(session.enemies[i]["hp"]) > 0:
					result.append(i)
		SkillActionService.TARGET_ADJACENT:
			var center: int = session._valid_target(target_index)
			if center < 0:
				return result
			for offset in [-1, 1]:
				var idx: int = center + offset
				if idx >= 0 and idx < session.enemies.size() and int(session.enemies[idx]["hp"]) > 0:
					result.append(idx)
		_:
			var selected: int = session._valid_target(target_index)
			if selected >= 0:
				result.append(selected)
	return result


func _buff_log_message(skill: Dictionary, status: Dictionary, session: RefCounted) -> void:
	var parts: Array[String] = []
	for eff in status.get("effects", []):
		var stat := String(eff.get("stat", ""))
		var etype := String(eff.get("type", ""))
		var val := float(eff.get("value", 0.0))
		match stat:
			"attack":
				if etype == "multiply":
					parts.append("攻击力 x%.2f" % val)
			"damage_taken":
				if etype == "multiply":
					if val < 1.0:
						parts.append("受到伤害 -%d%%" % int((1.0 - val) * 100))
					else:
						parts.append("受到伤害 +%d%%" % int((val - 1.0) * 100))
			"armor":
				if etype == "multiply":
					parts.append("护甲 x%.2f" % val)
			"extra_hits":
				if etype == "flat":
					parts.append("普攻额外 %d 段" % int(val))
			"energy_cost":
				if etype == "flat":
					parts.append("技能能量消耗 %d" % int(val))
			"cooldown":
				if etype == "flat":
					parts.append("冷却 -%d 回合" % int(abs(val)))
	var duration := int(status.get("duration", -1))
	var dur_text := "持续 %d 回合" % duration if duration > 0 else "持续整场战斗"
	if not parts.is_empty():
		session.battle_log.append("%s：%s，%s。" % [skill["name"], "，".join(parts), dur_text])
	# tick_effects
	for tick in status.get("tick_effects", []):
		var tick_val := float(tick.get("value", 0.0))
		if tick_val > 0.0:
			session.battle_log.append("%s：每回合恢复 %.0f%% HP。" % [skill["name"], tick_val * 100])
		elif tick_val < 0.0:
			session.battle_log.append("%s：每回合失去 %.0f%% HP。" % [skill["name"], abs(tick_val) * 100])
	# reflect
	var reflect_mult := float(status.get("reflect_multiplier", 0.0))
	if reflect_mult > 0.0:
		session.battle_log.append("%s：受到攻击时反弹 %.0f%% 伤害。" % [skill["name"], reflect_mult * 100])
