extends RefCounted
class_name RoundLifecycleModule

const CombatRules = preload("res://scripts/core/combat_rules.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const EnemyActionRules = preload("res://scripts/core/enemy_action_rules.gd")
const StateBuffService = preload("res://scripts/core/state_buff_service.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const TriggerEvents = preload("res://scripts/core/trigger_events.gd")
const TurnOrderModule = preload("res://scripts/core/battle/lifecycle/turn_order_module.gd")

var enemy_rules: RefCounted
var state_buffs: RefCounted
var turn_order: RefCounted


func _init(rules: RefCounted = null, buffs: RefCounted = null, order_module: RefCounted = null) -> void:
	enemy_rules = rules if rules != null else EnemyActionRules.new()
	state_buffs = buffs if buffs != null else StateBuffService.new()
	turn_order = order_module if order_module != null else TurnOrderModule.new()


# 玩家回合开始：推进回合数、结算冷却与状态 tick、重置格挡与行动标记、
# 抽取状态 Buff，并按行动顺序让敏捷更快的敌人先行动。
func begin_player_turn(session: RefCounted) -> void:
	session.round_index += 1
	session.has_acted = false
	session.perfect_deflect = false
	session.ai_turn_stage = "after_player_pending"
	tick_skill_cooldowns(session)
	session.player_block = 0
	session.pending_state_card = draw_state_buff(session)
	var corruption_damage := CombatRules.resolve_corruption(session.player)
	if corruption_damage > 0:
		session.battle_log.append("腐败结算：受到 %d 点真实伤害。" % corruption_damage)
	if int(session.player["hp"]) <= 0:
		session._on_defeat()
		return
	session.status_service.tick_statuses(session.player)
	process_tick_effects(session, session.player)
	session.status_service.fire_trigger(session.player, TriggerEvents.ON_TURN_START, {"battle_log": session.battle_log, "session": session, "not_attacked_last_turn": not bool(session.attacked_this_turn)})
	for enemy in session.enemies:
		if int(enemy["hp"]) <= 0:
			continue
		CombatRules.tick_enemy_cooldowns(enemy)
		session.status_service.tick_statuses(enemy)
		process_tick_effects(session, enemy)
		session.status_service.fire_trigger(enemy, TriggerEvents.ON_TURN_START, {"battle_log": session.battle_log, "session": session, "round_index": session.round_index})
	for ally in session.allies:
		if int(ally["hp"]) <= 0 or String(ally.get("controlled_by", "")) != "ai":
			continue
		session.status_service.tick_statuses(ally)
		process_tick_effects(session, ally)
		session.status_service.fire_trigger(ally, TriggerEvents.ON_TURN_START, {"battle_log": session.battle_log, "session": session, "round_index": session.round_index})
	session.attacked_this_turn = false
	var action_order: Array[Dictionary] = turn_order.compute_order(session)
	var player_position: int = turn_order.find_player_position(action_order)
	if player_position > 0:
		# 敏捷较高的敌方单位先行动；之后仍保留玩家的一次手动行动。
		session._enemy_turn(true)
		if int(session.player["hp"]) <= 0:
			session._on_defeat()
			return
	var charged_label: String = session._random_ready_charge()
	session.message = "你的回合。状态 Buff：%s" % state_name(String(session.pending_state_card))
	if charged_label != "":
		session.message += " 随机充能：%s。" % charged_label
	var player_hint := String(session.current_encounter.get("player_hint", ""))
	if player_hint != "":
		session.message += " " + player_hint
	session._debug_log("turn_start round=%d energy=%d hp=%d/%d block=%d action_order=%s" % [session.round_index, session.energy, int(session.player.get("hp", 0)), int(session.player.get("max_hp", session.player.get("base_max_hp", 0))), session.player_block, turn_order.format_order(action_order)])


# 回合收尾：触发敌方/我方回合结束事件，之后结算回合结束特性与场景效果。
func end_round(session: RefCounted) -> void:
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


# 扣除玩家技能冷却；冷却缩减影响所有冷却值。
func tick_skill_cooldowns(session: RefCounted) -> void:
	var cd_reduction := int(session.status_service.resolve_stat(session.player, 0.0, StatusService.STAT_COOLDOWN))
	var expired: Array[String] = []
	for skill_id in session.skill_cooldowns.keys():
		var remaining := int(session.skill_cooldowns[skill_id]) - 1 - cd_reduction
		if remaining <= 0:
			expired.append(String(skill_id))
		else:
			session.skill_cooldowns[skill_id] = remaining
	for skill_id in expired:
		session.skill_cooldowns.erase(skill_id)


# 结算目标身上的每回合效果（HP 恢复/流失、能量恢复），以及玩家延迟伤害。
func process_tick_effects(session: RefCounted, target: Dictionary) -> void:
	if not target.has("statuses"):
		return
	for status in target.get("statuses", []):
		for tick in status.get("tick_effects", []):
			var tick_stat := String(tick.get("stat", "hp"))
			var tick_type := String(tick.get("type", "percent"))
			var tick_value := float(tick.get("value", 0.0))
			if tick_stat == "hp":
				if tick_type == "percent":
					var amount := maxi(1, int(round(float(target["max_hp"]) * abs(tick_value))))
					if tick_value > 0.0:
						amount = maxi(1, int(ceil(session.status_service.resolve_stat(target, float(amount), StatusService.STAT_HEAL))))
						target["hp"] = mini(int(target["max_hp"]), int(target["hp"]) + amount)
						session.battle_log.append("%s：每回合恢复 %d 点 HP。" % [String(status.get("name", "")), amount])
					elif tick_value < 0.0:
						target["hp"] = maxi(1, int(target["hp"]) - amount)
						session.battle_log.append("%s：每回合失去 %d 点 HP。" % [String(status.get("name", "")), amount])
				elif tick_type == "flat":
					if tick_value > 0.0:
						var resolved_tick: int = maxi(1, int(ceil(session.status_service.resolve_stat(target, abs(tick_value), StatusService.STAT_HEAL))))
						target["hp"] = mini(int(target["max_hp"]), int(target["hp"]) + resolved_tick)
					elif tick_value < 0.0:
						target["hp"] = maxi(1, int(target["hp"]) + int(tick_value))
			elif tick_stat == "energy" and tick_type == "flat":
				session.energy = mini(DataCatalog.ENERGY_MAX, session.energy + int(tick_value))
	# 延迟伤害结算
	if target == session.player and session.deferred_damage > 0.0:
		var deferred_tick := maxi(1, int(round(session.deferred_damage / 3.0)))
		deferred_tick = mini(deferred_tick, int(session.deferred_damage))
		session.deferred_damage -= float(deferred_tick)
		target["hp"] = maxi(1, int(target["hp"]) - deferred_tick)
		session.battle_log.append("延迟伤害结算：受到 %d 点延迟伤害。" % deferred_tick)


# 抽取本回合状态 Buff；教程战斗使用固定卡序，正式战斗走 StateBuffService 循环。
func draw_state_buff(session: RefCounted) -> String:
	if session.is_tutorial():
		var tutorial_cards := ["critical", "perfect_guard", "read"]
		return String(tutorial_cards[clampi(session.battle_index - 1, 0, tutorial_cards.size() - 1)])
	return String(state_buffs.draw_state_buff(session))


func state_name(card_id: String) -> String:
	return String(state_buffs.state_name(card_id))


# 是否有敌人携带先手特性；开局先手与回合内行动顺序共用该判定。
func has_first_strike(enemies: Array[Dictionary]) -> bool:
	return bool(enemy_rules.has_first_strike(enemies))
