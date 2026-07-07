extends RefCounted
class_name ModifierPipeline

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const DynamicValueResolver = preload("res://scripts/core/dynamic_value_resolver.gd")

const PRIORITY_FLAT   := 100
const PRIORITY_STATUS := 200
const PRIORITY_SET    := 300
const PRIORITY_STATE  := 400
const PRIORITY_CHARGE := 500
const PRIORITY_FINAL  := 700


static func collect_from_session(session, stat_key: String, context: Dictionary = {}) -> Array[Dictionary]:
	var modifiers: Array[Dictionary] = []
	var player: Dictionary = session.player
	var skill_id: String = context.get("skill_id", "")
	var is_skill := skill_id != ""

	match stat_key:
		"attack":
			var state_mult := _state_card_multiplier(session, "attack")
			if state_mult != 1.0:
				modifiers.append({
					"source": "state_card",
					"stat": "attack",
					"type": "multiply",
					"value": state_mult,
					"priority": PRIORITY_STATE
				})

			if session.battle_attack_multiplier != 1.0:
				modifiers.append({
					"source": "battle",
					"stat": "attack",
					"type": "multiply",
					"value": session.battle_attack_multiplier,
					"priority": PRIORITY_STATE
				})

			_collect_set_modifiers(modifiers, player, "attack", context, is_skill, session)

			if is_skill:
				var skill_multiplier := float(context.get("skill_multiplier", 1.0))
				if skill_multiplier != 1.0:
					modifiers.append({
						"source": "skill:%s" % skill_id,
						"stat": "attack",
						"type": "multiply",
						"value": skill_multiplier,
						"priority": PRIORITY_STATUS
					})

		"defense":
			var state_mult := _state_card_multiplier(session, "defense")
			if state_mult != 1.0:
				modifiers.append({
					"source": "state_card",
					"stat": "defense",
					"type": "multiply",
					"value": state_mult,
					"priority": PRIORITY_STATE
				})

			_collect_set_modifiers(modifiers, player, "defense", context, is_skill, session)

			if is_skill:
				var skill_multiplier := float(context.get("skill_multiplier", 1.0))
				if skill_multiplier != 1.0:
					modifiers.append({
						"source": "skill:%s" % skill_id,
						"stat": "defense",
						"type": "multiply",
						"value": skill_multiplier,
						"priority": PRIORITY_STATUS
					})

	return modifiers


static func _collect_set_modifiers(modifiers: Array, player: Dictionary, stat_key: String, context: Dictionary, is_skill: bool, session = null) -> void:
	var set_effects: Dictionary = player.get("active_set_effects", {})
	for set_mod in set_effects.get("modifiers", []):
		if String(set_mod.get("stat", "")) != stat_key:
			continue
		var raw_value = set_mod["value"]
		if typeof(raw_value) == TYPE_STRING and raw_value == "dynamic:focus_combo":
			continue
		var ctx_with_counters := context.duplicate()
		ctx_with_counters["meticulous_stacks"] = session.meticulous_stacks if session else 0
		ctx_with_counters["seek_bloom_stacks"] = session.seek_bloom_stacks if session else 0
		ctx_with_counters["state_card"] = session.pending_state_card if session else ""
		ctx_with_counters["focus_combo_multiplier"] = session.focus_combo_multiplier if session else 1.0
		var resolved_value = DynamicValueResolver.resolve(raw_value, player, ctx_with_counters)
		if typeof(resolved_value) == TYPE_FLOAT and abs(resolved_value - 1.0) < 0.0001:
			continue
		modifiers.append({
			"source": String(set_mod.get("source", "set")),
			"stat": stat_key,
			"type": String(set_mod.get("type", "multiply")),
			"value": resolved_value,
			"priority": int(set_mod.get("priority", PRIORITY_SET))
		})


static func resolve(base: float, modifiers: Array[Dictionary]) -> float:
	var sorted := modifiers.duplicate()
	sorted.sort_custom(func(a, b): return a["priority"] < b["priority"])
	var flat_sum := 0.0
	var percent_product := 1.0
	var multiply_product := 1.0
	for mod in sorted:
		match mod["type"]:
			"flat":
				flat_sum += mod["value"]
			"percent":
				percent_product *= 1.0 + mod["value"]
			"multiply":
				multiply_product *= mod["value"]
	return (base + flat_sum) * percent_product * multiply_product


static func _state_card_multiplier(session, tag: String) -> float:
	if session.pending_state_card == "":
		return 1.0
	var card: Dictionary = DataCatalog.STATE_CARDS[session.pending_state_card]
	if card["tag"] == "numeric" or card["tag"] == tag:
		if session.pending_state_card == "fallback" and tag == "attack":
			return 1.0
		return float(card["multiplier"])
	return 1.0