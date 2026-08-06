extends RefCounted
class_name BattleHitContext

static var _next_context_id: int = 1

var context_id: String = ""
var parent_action_id: String = ""
var chain_id: String = ""
var source_actor: Dictionary = {}
var target_actor: Dictionary = {}
var source: String = ""
var skill_id: String = ""
var damage_type: String = "physical"
var base_damage: int = 0
var modified_damage: int = 0
var is_critical: bool = false
var armor_multiplier: float = 1.0
var is_dodged: bool = false
var armor_reduced: int = 0
var block_absorbed: int = 0
var final_damage: int = 0
var killed: bool = false


func _init(
	initial_source_actor: Dictionary = {},
	initial_target_actor: Dictionary = {},
	initial_source: String = "",
	parent_id: String = "",
	inherited_chain_id: String = "",
	id: String = ""
) -> void:
	context_id = id if id != "" else _new_context_id()
	parent_action_id = parent_id
	chain_id = inherited_chain_id if inherited_chain_id != "" else context_id
	source_actor = initial_source_actor.duplicate(true)
	target_actor = initial_target_actor.duplicate(true)
	source = initial_source


func mark_dodged() -> void:
	is_dodged = true
	final_damage = 0


func apply_damage_result(
	value: int,
	armor_value: int = 0,
	block_value: int = 0,
	target_killed: bool = false
) -> void:
	final_damage = maxi(0, value)
	armor_reduced = maxi(0, armor_value)
	block_absorbed = maxi(0, block_value)
	killed = target_killed


static func _new_context_id() -> String:
	var next_id: int = _next_context_id
	_next_context_id += 1
	return "hit-%d" % next_id
