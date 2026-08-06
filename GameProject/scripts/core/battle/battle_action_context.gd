extends RefCounted
class_name BattleActionContext

static var _next_context_id: int = 1

var context_id: String = ""
var parent_context_id: String = ""
var chain_id: String = ""
var actor: Dictionary = {}
var intent: Dictionary = {}
var skill: Dictionary = {}
var action: Dictionary = {}
var source: String = ""
var target_selection: Dictionary = {}
var cost: Dictionary = {}
var cancelled: bool = false
var cancel_reason: String = ""


func _init(
	initial_intent: Dictionary = {},
	initial_actor: Dictionary = {},
	parent_id: String = "",
	inherited_chain_id: String = "",
	id: String = ""
) -> void:
	context_id = id if id != "" else _new_context_id()
	parent_context_id = parent_id
	chain_id = inherited_chain_id if inherited_chain_id != "" else context_id
	intent = initial_intent.duplicate(true)
	actor = initial_actor.duplicate(true)
	source = String(intent.get("source", ""))


func set_skill(value: Dictionary) -> void:
	skill = value.duplicate(true)


func set_action(value: Dictionary) -> void:
	action = value.duplicate(true)


func set_target_selection(value: Dictionary) -> void:
	target_selection = value.duplicate(true)


func set_cost(value: Dictionary) -> void:
	cost = value.duplicate(true)


func cancel(reason: String = "") -> void:
	cancelled = true
	cancel_reason = reason


static func _new_context_id() -> String:
	var next_id: int = _next_context_id
	_next_context_id += 1
	return "action-%d" % next_id
