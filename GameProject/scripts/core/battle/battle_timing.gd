extends RefCounted
class_name BattleTiming

const BATTLE_PREPARE := "battle_prepare"
const BATTLE_START := "battle_start"
const BATTLE_END := "battle_end"

const ROUND_START_BEFORE := "round_start_before"
const ROUND_START := "round_start"
const ROUND_START_AFTER := "round_start_after"
const ROUND_END_BEFORE := "round_end_before"
const ROUND_END := "round_end"

const ACTION_BEFORE := "action_before"
const ACTION_VALIDATE := "action_validate"
const ACTION_START := "action_start"
const ACTION_EXECUTE := "action_execute"
const ACTION_AFTER := "action_after"
const TURN_END := "turn_end"

const SKILL_BEFORE := "skill_before"
const SKILL_EFFECT_BEFORE := "skill_effect_before"
const SKILL_EFFECT := "skill_effect"
const SKILL_EFFECT_AFTER := "skill_effect_after"
const SKILL_AFTER := "skill_after"

const HIT_BEFORE := "hit_before"
const DODGE_CHECK := "dodge_check"
const DODGE := "dodge"
const HIT_CONFIRMED := "hit_confirmed"
const DAMAGE_BEFORE := "damage_before"
const DAMAGE_APPLY := "damage_apply"
const DAMAGE_AFTER := "damage_after"
const HIT_AFTER := "hit_after"

const ALL: Array[String] = [
	BATTLE_PREPARE,
	BATTLE_START,
	BATTLE_END,
	ROUND_START_BEFORE,
	ROUND_START,
	ROUND_START_AFTER,
	ROUND_END_BEFORE,
	ROUND_END,
	ACTION_BEFORE,
	ACTION_VALIDATE,
	ACTION_START,
	ACTION_EXECUTE,
	ACTION_AFTER,
	TURN_END,
	SKILL_BEFORE,
	SKILL_EFFECT_BEFORE,
	SKILL_EFFECT,
	SKILL_EFFECT_AFTER,
	SKILL_AFTER,
	HIT_BEFORE,
	DODGE_CHECK,
	DODGE,
	HIT_CONFIRMED,
	DAMAGE_BEFORE,
	DAMAGE_APPLY,
	DAMAGE_AFTER,
	HIT_AFTER
]


static func is_known(timing: String) -> bool:
	return timing in ALL
