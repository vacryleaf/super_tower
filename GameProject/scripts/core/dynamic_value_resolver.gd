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
		"focus_combo":
			return _resolve_focus_combo(context)
		"meticulous":
			return _resolve_meticulous(context)
		"seek_bloom":
			return _resolve_seek_bloom(context)
		"hunt":
			return _resolve_hunt(context)
		"ranger_return":
			return 1.0
	return float(value)


static func _resolve_berserker(subject: Dictionary) -> float:
	var hp_percent := float(subject["hp"]) / float(subject["max_hp"])
	return 1.0 + clamp((1.0 - hp_percent) / 0.70, 0.0, 1.0)


static func _resolve_ko_critical(_subject: Dictionary, context: Dictionary) -> float:
	if String(context.get("state_card", "")) == "critical":
		return 3.0
	return 1.0


static func _resolve_focus_combo(context: Dictionary) -> float:
	return float(context.get("focus_combo_multiplier", 1.0))


static func _resolve_meticulous(context: Dictionary) -> float:
	var stacks := int(context.get("meticulous_stacks", 0))
	return 1.0 + stacks * 0.10


static func _resolve_seek_bloom(context: Dictionary) -> float:
	var stacks := int(context.get("seek_bloom_stacks", 0))
	return 1.0 + stacks * 0.30


static func _resolve_hunt(context: Dictionary) -> float:
	var meticulous := int(context.get("meticulous_stacks", 0))
	var seek_bloom := int(context.get("seek_bloom_stacks", 0))
	var bonus := 1.0
	if meticulous >= 5:
		bonus *= 1.50
	if seek_bloom >= 3:
		bonus *= 1.90
	return bonus