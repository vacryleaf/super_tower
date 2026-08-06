extends RefCounted
class_name BattleStepResult

const CONTINUE := "continue"
const SKIP := "skip"
const CANCEL_ACTION := "cancel_action"
const END_BATTLE := "end_battle"
const ERROR := "error"

var kind: String = CONTINUE
var message: String = ""
var error_code: String = ""
var data: Dictionary = {}


func _init(
	initial_kind: String = CONTINUE,
	initial_message: String = "",
	initial_error_code: String = "",
	initial_data: Dictionary = {}
) -> void:
	kind = initial_kind
	message = initial_message
	error_code = initial_error_code
	data = initial_data.duplicate(true)


func is_terminal() -> bool:
	return kind == CANCEL_ACTION or kind == END_BATTLE or kind == ERROR
