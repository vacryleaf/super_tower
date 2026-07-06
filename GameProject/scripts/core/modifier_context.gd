extends RefCounted
class_name ModifierContext

var session = null
var source: Dictionary = {}
var target: Dictionary = {}
var skill_id := ""
var damage_type := "physical"
var is_critical := false
var action_tag := "attack"

func _init(p_session = null, p_source := {}, p_target := {}, p_skill_id := "", p_damage_type := "physical") -> void:
	session = p_session
	source = p_source
	target = p_target
	skill_id = p_skill_id
	damage_type = p_damage_type