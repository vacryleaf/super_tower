extends RefCounted
class_name DynamicValueResolver


static func resolve(value, subject: Dictionary, context: Dictionary) -> float:
	if typeof(value) != TYPE_STRING or not value.begins_with("dynamic:"):
		return float(value)
	var func_name: String = value.substr(8)
	match func_name:
		"berserker":
			return _resolve_berserker(subject)
		"ko_critical":
			return _resolve_ko_critical(subject, context)
	return float(value)


static func _resolve_berserker(subject: Dictionary) -> float:
	var hp_percent := float(subject["hp"]) / float(subject["max_hp"])
	return 1.0 + clamp((1.0 - hp_percent) / 0.70, 0.0, 1.0)


static func _resolve_ko_critical(_subject: Dictionary, context: Dictionary) -> float:
	if String(context.get("state_card", "")) == "critical":
		return 3.0
	return 1.0
