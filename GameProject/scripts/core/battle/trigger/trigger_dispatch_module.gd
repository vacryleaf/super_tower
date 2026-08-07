extends RefCounted
class_name TriggerDispatchModule

const ActionContext = preload("res://scripts/core/action_context.gd")
const ActionSource = preload("res://scripts/core/action_source.gd")
const BattleActionContext = preload("res://scripts/core/battle/battle_action_context.gd")
const BattleActionQueue = preload("res://scripts/core/battle/trigger/battle_action_queue.gd")
const TriggerEvents = preload("res://scripts/core/trigger_events.gd")

var action_queue: RefCounted
var _dispatching: bool = false
var _active_chain_id: String = ""


func _init(initial_queue: RefCounted = null) -> void:
	action_queue = initial_queue if initial_queue != null else BattleActionQueue.new()


# 执行单个触发动作；TriggerService 只负责事件与条件筛选，效果统一在此执行。
# 伤害类动作（dot/reflect/extra_damage/counter_all）先进入嵌套行动队列，
# 再通过 session.deal_damage() 走统一命中与伤害流程，避免直接修改 HP 或绕过流程。
func dispatch(target: Dictionary, action: Dictionary, context: Dictionary, status_service: RefCounted = null) -> void:
	var action_type := String(action.get("type", ""))
	match action_type:
		TriggerEvents.ACTION_DOT:
			_submit_dot(target, action, context)
		TriggerEvents.ACTION_HOT:
			_apply_heal(target, action, context, "%s 恢复 %d 点生命。")
		TriggerEvents.ACTION_REFLECT:
			_submit_reflect(target, action, context)
		TriggerEvents.ACTION_LIFESTEAL:
			_apply_heal(target, action, context, "%s 吸取 %d 点生命。")
		TriggerEvents.ACTION_GAIN_BLOCK:
			_apply_gain_block(target, action, context)
		TriggerEvents.ACTION_GAIN_DODGE:
			_apply_gain_dodge(target, action, context)
		TriggerEvents.ACTION_HEAL:
			_apply_heal(target, action, context, "%s 恢复 %d 点生命。")
		TriggerEvents.ACTION_APPLY_STATUS:
			_apply_status(target, action, context, status_service)
		TriggerEvents.ACTION_REMOVE_STATUS:
			_apply_remove_status(target, action, context, status_service)
		TriggerEvents.ACTION_EXTRA_DAMAGE:
			_submit_extra_damage(target, action, context)
		TriggerEvents.ACTION_COUNTER_ALL:
			_submit_counter_all(target, action, context)
		TriggerEvents.ACTION_INCREMENT_COUNTER:
			_increment_counter(target, action, context, status_service)
		TriggerEvents.ACTION_RESET_COUNTER:
			_reset_counter(action, context)


# 将伤害动作提交到嵌套行动队列；队列深度由父链 ID 继承，超限直接丢弃。
func _submit_nested_damage(
	session: RefCounted,
	source: String,
	target_index: int,
	value: int,
	damage_type: String,
	source_actor: Dictionary
) -> void:
	if value <= 0 or session == null:
		return
	var nested: RefCounted = BattleActionContext.new({}, source_actor, "", _active_chain_id)
	nested.source = source
	nested.action = {
		"type": "trigger_damage",
		"value": value,
		"damage_type": damage_type,
		"target_index": target_index
	}
	if not action_queue.enqueue_nested_action(nested, _active_chain_id):
		return
	_drain(session)


# 消费队列中的嵌套行动；同一批次内的嵌套伤害通过 deal_damage 进入统一命中流程。
func _drain(session: RefCounted) -> void:
	if _dispatching:
		return
	_dispatching = true
	while not action_queue.is_empty():
		var nested: RefCounted = action_queue.dequeue_nested_action()
		_active_chain_id = String(nested.get("chain_id"))
		var nested_action: Dictionary = nested.get("action")
		var value := int(nested_action.get("value", 0))
		if value <= 0:
			continue
		var source := String(nested.get("source"))
		if source == "":
			source = ActionSource.TRIGGER_EFFECT
		var damage_type := String(nested_action.get("damage_type", "physical"))
		var target_index := int(nested_action.get("target_index", 0))
		var source_actor: Dictionary = nested.get("actor")
		var damage_ctx := ActionContext.create_trigger(source, target_index, value, damage_type)
		if not source_actor.is_empty():
			damage_ctx["source_actor"] = source_actor
		session.deal_damage(damage_ctx)
	_dispatching = false
	_active_chain_id = ""


func _submit_dot(target: Dictionary, action: Dictionary, context: Dictionary) -> void:
	var dot_value := _resolve_action_value(action, context, target)
	if dot_value <= 0:
		return
	var session = context.get("session")
	if session == null:
		return
	# 持续伤害作用于宿主自身：以对立侧首个存活单位作为来源，重新经过统一命中流程。
	var opposing: Array[Dictionary] = session._opposing_units(target)
	if opposing.is_empty():
		return
	var source_actor: Dictionary = opposing[0]
	var target_pool: Array[Dictionary] = session._opposing_units(source_actor)
	var target_index := _index_of(target_pool, target)
	if target_index < 0:
		return
	_submit_nested_damage(session, ActionSource.DOT, target_index, dot_value, "physical", source_actor)


func _submit_reflect(target: Dictionary, action: Dictionary, context: Dictionary) -> void:
	var reflect_value := _resolve_action_value(action, context, target)
	if reflect_value <= 0:
		return
	var source: Dictionary = context.get("source", {})
	if source.is_empty():
		return
	var session = context.get("session")
	if session == null:
		return
	var opposing: Array[Dictionary] = session._opposing_units(target)
	var target_index := _index_of(opposing, source)
	if target_index < 0:
		return
	_submit_nested_damage(session, ActionSource.TRIGGER_EFFECT, target_index, reflect_value, "physical", target)


func _submit_extra_damage(target: Dictionary, action: Dictionary, context: Dictionary) -> void:
	var extra_value := _resolve_action_value(action, context, target)
	if extra_value <= 0:
		return
	var session = context.get("session")
	if session == null:
		return
	var damage_type := String(action.get("damage_type", "physical"))
	var enemy_idx: int = session.find_enemy_index(target)
	if enemy_idx >= 0:
		_submit_nested_damage(session, ActionSource.TRIGGER_EFFECT, enemy_idx, extra_value, damage_type, session.player)
		return
	var opposing: Array[Dictionary] = session._opposing_units(target)
	for i in range(opposing.size()):
		var unit: Dictionary = opposing[i]
		if int(unit.get("hp", 0)) <= 0:
			continue
		_submit_nested_damage(session, ActionSource.TRIGGER_EFFECT, i, extra_value, damage_type, session.player)


func _submit_counter_all(target: Dictionary, action: Dictionary, context: Dictionary) -> void:
	var session = context.get("session")
	if session == null:
		return
	var threshold := int(action.get("threshold", 2))
	if int(session.dodge_streak) < threshold:
		return
	session.dodge_streak = 0
	var dmg_value := _resolve_action_value(action, context, target)
	if dmg_value <= 0:
		return
	var opposing: Array[Dictionary] = session._opposing_units(target)
	for i in range(opposing.size()):
		var unit: Dictionary = opposing[i]
		if int(unit.get("hp", 0)) <= 0:
			continue
		_submit_nested_damage(session, ActionSource.TRIGGER_EFFECT, i, dmg_value, "physical", session.player)


func _apply_heal(target: Dictionary, action: Dictionary, context: Dictionary, log_template: String) -> void:
	var heal_value := _resolve_action_value(action, context, target)
	if heal_value <= 0:
		return
	var battle_log: Array = context.get("battle_log", [])
	target["hp"] = mini(int(target.get("max_hp", target.get("hp", 1))), int(target.get("hp", 0)) + heal_value)
	battle_log.append(log_template % [String(target.get("name", "")), heal_value])


func _apply_gain_block(target: Dictionary, action: Dictionary, context: Dictionary) -> void:
	var block_value := _resolve_action_value(action, context, target)
	if block_value <= 0:
		return
	var battle_log: Array = context.get("battle_log", [])
	target["block"] = int(target.get("block", 0)) + block_value
	battle_log.append("%s 获得 %d 点格挡。" % [String(target.get("name", "")), block_value])


func _apply_gain_dodge(target: Dictionary, action: Dictionary, context: Dictionary) -> void:
	var dodge_value := maxi(1, int(action.get("value", 1)))
	var battle_log: Array = context.get("battle_log", [])
	target["dodge_layers"] = int(target.get("dodge_layers", 0)) + dodge_value
	battle_log.append("%s 获得 %d 层躲避。" % [String(target.get("name", "")), dodge_value])


func _apply_status(target: Dictionary, action: Dictionary, context: Dictionary, status_service: RefCounted) -> void:
	var status_to_apply: Dictionary = action.get("status", {})
	if status_to_apply.is_empty() or status_service == null:
		return
	var apply_target := target
	if String(action.get("apply_to", "")) == "context_target":
		var ctx_target: Dictionary = context.get("target", {})
		if not ctx_target.is_empty():
			apply_target = ctx_target
		else:
			var battle_log: Array = context.get("battle_log", [])
			battle_log.append("[WARN] apply_to=context_target 但 context 缺少 target，状态将施加到自身")
	status_service.add_status(apply_target, status_to_apply)


func _apply_remove_status(target: Dictionary, action: Dictionary, context: Dictionary, status_service: RefCounted) -> void:
	var remove_id := String(action.get("status_id", ""))
	if remove_id != "" and status_service != null:
		status_service.remove_status(target, remove_id)


func _increment_counter(target: Dictionary, action: Dictionary, context: Dictionary, status_service: RefCounted) -> void:
	var counter_name := String(action.get("counter", ""))
	var max_val := int(action.get("max", 999))
	var threshold := int(action.get("threshold", 0))
	var threshold_actions: Array = action.get("threshold_actions", [])
	var session = context.get("session")
	if counter_name == "" or session == null:
		return
	var current := int(session.get_counter(counter_name))
	var new_val := mini(current + 1, max_val)
	session.set_counter(counter_name, new_val)
	if threshold > 0 and new_val >= threshold and not threshold_actions.is_empty():
		while int(session.get_counter(counter_name)) >= threshold:
			session.set_counter(counter_name, int(session.get_counter(counter_name)) - threshold)
			for ta in threshold_actions:
				dispatch(target, ta, context, status_service)


func _reset_counter(action: Dictionary, context: Dictionary) -> void:
	var counter_name := String(action.get("counter", ""))
	var session = context.get("session")
	if counter_name != "" and session != null:
		session.set_counter(counter_name, 0)


func _resolve_action_value(action: Dictionary, context: Dictionary, target: Dictionary = {}) -> int:
	if action.has("value"):
		return maxi(0, int(action.get("value", 0)))
	var base_value := 0
	var self_stat := String(action.get("self_stat", ""))
	var self_ratio := float(action.get("self_ratio", 0.0))
	if self_stat != "" and self_ratio > 0.0 and not target.is_empty():
		base_value = maxi(1, int(round(float(target.get(self_stat, 0)) * self_ratio)))
	else:
		var source_stat := String(action.get("source_stat", ""))
		var source_ratio := float(action.get("source_ratio", 0.0))
		var source: Dictionary = context.get("source", {})
		if source_stat != "" and source_ratio > 0.0 and not source.is_empty():
			base_value = maxi(1, int(round(float(source.get(source_stat, 0)) * source_ratio)))
		else:
			var target_stat := String(action.get("target_stat", ""))
			var target_ratio := float(action.get("target_ratio", 0.0))
			var ctx_target: Dictionary = context.get("target", {})
			if target_stat != "" and target_ratio > 0.0 and not ctx_target.is_empty():
				base_value = maxi(1, int(round(float(ctx_target.get(target_stat, 0)) * target_ratio)))
	var counter_name := String(action.get("counter", ""))
	if counter_name != "" and base_value > 0:
		var session = context.get("session")
		if session != null:
			var counter_value := int(session.get_counter(counter_name))
			base_value = maxi(1, int(round(float(base_value) * float(counter_value))))
	return base_value


func _index_of(units: Array[Dictionary], unit: Dictionary) -> int:
	for i in range(units.size()):
		if units[i] == unit:
			return i
	return -1
