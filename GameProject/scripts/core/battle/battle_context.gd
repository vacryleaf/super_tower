extends RefCounted
class_name BattleContext

static var _next_context_id: int = 1

var context_id: String = ""
var battle_state: Variant = null
var combatants: Dictionary = {}
var current_actor: Dictionary = {}
var action_queue: Array[Dictionary] = []
var round_index: int = 0
var rng: Variant = null
var services: Dictionary = {}
var events: Array[Dictionary] = []
var flow_control: Dictionary = {}


func _init(initial_state: Variant = null, initial_services: Dictionary = {}, id: String = "") -> void:
	battle_state = initial_state
	services = initial_services.duplicate(false)
	context_id = id if id != "" else _new_context_id()


func set_combatants(value: Dictionary) -> void:
	combatants = value.duplicate(true)


func set_current_actor(value: Dictionary) -> void:
	current_actor = value.duplicate(true)


func enqueue_action(intent: Dictionary) -> void:
	action_queue.append(intent.duplicate(true))


func dequeue_action() -> Dictionary:
	if action_queue.is_empty():
		return {}
	var next_action: Dictionary = action_queue[0]
	action_queue.remove_at(0)
	return next_action


func record_event(kind: String, payload: Dictionary = {}) -> void:
	var event: Dictionary = payload.duplicate(true)
	event["kind"] = kind
	events.append(event)


func cancel_current_action(reason: String = "") -> void:
	flow_control["action_cancelled"] = true
	flow_control["cancel_reason"] = reason


func clear_action_cancellation() -> void:
	flow_control.erase("action_cancelled")
	flow_control.erase("cancel_reason")


func is_action_cancelled() -> bool:
	return bool(flow_control.get("action_cancelled", false))


static func _new_context_id() -> String:
	var next_id: int = _next_context_id
	_next_context_id += 1
	return "battle-%d" % next_id
