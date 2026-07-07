extends RefCounted
class_name ActionSource

const ACTIVE_ATTACK := "active_attack"
const COUNTER_ATTACK := "counter_attack"
const TRIGGER_EFFECT := "trigger_effect"
const DOT := "dot"
const ENEMY_ATTACK := "enemy_attack"
const DIRECT := "direct"

const NON_INTERACTIVE: Array[String] = [TRIGGER_EFFECT, DOT, DIRECT]


static func is_interactive(source: String) -> bool:
	return not source in NON_INTERACTIVE
