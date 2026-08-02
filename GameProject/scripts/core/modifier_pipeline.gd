extends RefCounted
class_name ModifierPipeline

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const StatusService = preload("res://scripts/core/status_service.gd")

const PRIORITY_FLAT   := 100
const PRIORITY_STATUS := 200
const PRIORITY_STATE  := 400
const PRIORITY_CHARGE := 500
const PRIORITY_FINAL  := 700


static func collect_from_session(session, stat_key: String, context: Dictionary = {}, action_source: String = "") -> Array[Dictionary]:
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