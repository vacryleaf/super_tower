extends RefCounted
class_name SkillActionService

const ACTION_DAMAGE := "damage"
const ACTION_MODIFY_ARMOR := "modify_armor"
const ACTION_APPLY_STATUS := "apply_status"
const ACTION_GAIN_BLOCK := "gain_block"
const ACTION_GAIN_DODGE := "gain_dodge"
const ACTION_INTERRUPT := "interrupt"
const ACTION_SET_COUNTER_ATTACK := "set_counter_attack"
const ACTION_CLEAR_DEBUFFS := "clear_debuffs"
const ACTION_HEAL := "heal"
const ACTION_SET_DUEL := "set_duel"
const ACTION_SET_DEFLECT := "set_deflect"

const TARGET_SELECTED := "selected"
const TARGET_ALL_ENEMIES := "all_enemies"
const TARGET_ADJACENT := "adjacent"
const TARGET_SELF := "self"
const TARGET_ALLY_SELECTED := "ally_selected"


static func has_actions(skill: Dictionary) -> bool:
	return skill.has("actions") and not _raw_actions(skill).is_empty()


static func actions(skill: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for action in _raw_actions(skill):
		if typeof(action) == TYPE_DICTIONARY:
			result.append((action as Dictionary).duplicate(true))
	return result


static func _raw_actions(skill: Dictionary) -> Array:
	var raw = skill.get("actions", [])
	if typeof(raw) == TYPE_ARRAY:
		return raw
	return []
