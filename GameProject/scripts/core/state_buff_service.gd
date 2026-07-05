extends RefCounted
class_name StateBuffService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

const DRAW_CYCLE := [
	"steady", "good", "steady", "great",
	"steady", "critical", "steady", "read",
	"good", "perfect_guard", "steady", "fallback"
]


func draw_state_buff(session: Variant) -> String:
	var card_id: String = DRAW_CYCLE[session.state_draw_cursor % DRAW_CYCLE.size()]
	session.state_draw_cursor += 1
	return card_id


func modified_value(session: Variant, base: int, tag: String) -> int:
	var multiplier := 1.0
	if session.pending_state_card != "":
		var card: Dictionary = DataCatalog.STATE_CARDS[session.pending_state_card]
		if card["tag"] == "numeric" or card["tag"] == tag:
			multiplier = float(card["multiplier"])
		if session.pending_state_card == "fallback" and tag == "attack":
			multiplier = 1.0
	return maxi(1, int(round(float(base) * multiplier)))


func consume_state_after_action(session: Variant, action_tag: String) -> void:
	if session.pending_state_card == "":
		return
	var card: Dictionary = DataCatalog.STATE_CARDS[session.pending_state_card]
	var card_tag := String(card.get("tag", ""))
	if card_tag == "attack" and action_tag == "attack":
		session.pending_state_card = ""
	elif card_tag == "defense" and (action_tag == "defense" or action_tag == "stance"):
		session.pending_state_card = ""
	elif card_tag == "dodge" and action_tag == "dodge":
		session.pending_state_card = ""
	elif session.pending_state_card == "fallback" and action_tag == "attack":
		session.pending_state_card = ""


func state_name(card_id: String) -> String:
	return DataCatalog.STATE_CARDS[card_id]["name"]
