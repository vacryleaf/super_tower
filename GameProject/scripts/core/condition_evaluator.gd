extends RefCounted
class_name ConditionEvaluator

const OP_EQ := "eq"
const OP_NE := "ne"
const OP_GT := "gt"
const OP_GTE := "gte"
const OP_LT := "lt"
const OP_LTE := "lte"


func evaluate(subject: Dictionary, condition: Dictionary, context: Dictionary) -> bool:
	if condition.is_empty():
		return true
	for key in condition.keys():
		var value = condition[key]
		match key:
			"hp_ratio":
				if typeof(subject.get("hp")) != TYPE_INT or typeof(subject.get("max_hp")) != TYPE_INT:
					return false
				var ratio := float(subject["hp"]) / maxf(1.0, float(subject["max_hp"]))
				if not _compare(ratio, value):
					return false
			"has_block":
				if (int(subject.get("block", 0)) > 0) != bool(value):
					return false
			"has_status":
				if not _has_status(subject, String(value)):
					return false
			"target_has_status":
				var ctx_target: Dictionary = context.get("target", {})
				if not _has_status(ctx_target, String(value)):
					return false
			"is_critical":
				if bool(context.get("is_critical", false)) != bool(value):
					return false
			"state_card":
				if String(context.get("state_card", "")) != String(value):
					return false
			"damage_type":
				if String(context.get("damage_type", "")) != String(value):
					return false
			"enemy_count":
				if not _compare(float(context.get("enemy_count", 0)), value):
					return false
			"round_index":
				if not _compare(float(context.get("round_index", 0)), value):
					return false
			"and":
				var sub_conditions: Array = value
				for sub in sub_conditions:
					if not evaluate(subject, sub, context):
						return false
			"or":
				var sub_conditions_or: Array = value
				for sub in sub_conditions_or:
					if evaluate(subject, sub, context):
						return true
				return false
			"not":
				if evaluate(subject, value, context):
					return false
	return true


func _compare(actual: float, constraint) -> bool:
	if typeof(constraint) == TYPE_FLOAT or typeof(constraint) == TYPE_INT:
		return abs(actual - float(constraint)) < 0.0001
	if typeof(constraint) != TYPE_DICTIONARY:
		return false
	var constraint_dict: Dictionary = constraint
	for op in constraint_dict.keys():
		var target := float(constraint_dict[op])
		match op:
			OP_EQ:  return abs(actual - target) < 0.0001
			OP_NE:  return abs(actual - target) >= 0.0001
			OP_GT:  return actual > target
			OP_GTE: return actual >= target
			"mod": return int(actual) % maxi(1, int(target)) == 0
			OP_LT:  return actual < target
			OP_LTE: return actual <= target
	return false


func _has_status(subject: Dictionary, status_id: String) -> bool:
	if not subject.has("statuses"):
		return false
	for status in subject["statuses"]:
		if String(status.get("id", "")) == status_id:
			return true
	return false