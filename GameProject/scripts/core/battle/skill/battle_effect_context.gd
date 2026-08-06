extends RefCounted
class_name BattleEffectContext

var runtime: RefCounted
var actor: Dictionary = {}
var skill: Dictionary = {}
var skill_id: String = ""
var action: Dictionary = {}
var target_index: int = -1
var is_player_actor: bool = false
var repeat_bonus: int = 0


func _init(
	initial_runtime: RefCounted,
	initial_actor: Dictionary,
	initial_skill: Dictionary,
	initial_skill_id: String,
	initial_action: Dictionary,
	initial_target_index: int,
	initial_is_player_actor: bool,
	initial_repeat_bonus: int = 0
) -> void:
	runtime = initial_runtime
	actor = initial_actor
	skill = initial_skill
	skill_id = initial_skill_id
	action = initial_action.duplicate(true)
	target_index = initial_target_index
	is_player_actor = initial_is_player_actor
	repeat_bonus = initial_repeat_bonus


func set_action(value: Dictionary) -> void:
	action = value.duplicate(true)


func targets() -> Array[Dictionary]:
	return runtime.call("resolve_targets", action, target_index, actor, is_player_actor)


func target_mode() -> String:
	return String(action.get("target", "selected"))
