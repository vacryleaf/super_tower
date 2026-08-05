extends RefCounted
class_name SchemaRegistry

const SkillActionService = preload("res://scripts/core/skill_action_service.gd")
const TriggerEvents = preload("res://scripts/core/trigger_events.gd")

const BUILTIN_SCHEMAS := {
	"skill.v1": {
		"domain": "skills",
		"required": ["schema_version", "id", "name_key", "slot", "kind", "energy_cost", "cooldown", "actions"],
		"legacy_optional": ["schema_version", "name_key", "actions"]
	},
	"weapon.v1": {
		"domain": "weapons",
		"required": ["schema_version", "id", "slot", "agility", "attack_damage", "critical_weight", "skill_1", "skill_2"],
		"legacy_optional": ["schema_version"]
	},
	"item.v1": {
		"domain": "items",
		"required": ["schema_version", "id", "name_key", "kind", "actions"],
		"legacy_optional": ["schema_version", "name_key", "actions"]
	},
	"monster.v1": {
		"domain": "monsters",
		"required": ["schema_version", "id", "rank", "hp", "attack", "defense", "passive_skills", "skills"],
		"legacy_optional": ["schema_version"]
	},
	"status.v1": {
		"domain": "statuses",
		"required": ["schema_version", "id", "kind", "stack", "duration"],
		"legacy_optional": ["schema_version"]
	},
	"trait.v1": {
		"domain": "traits",
		"required": ["schema_version", "id"],
		"legacy_optional": ["schema_version"]
	},
	"reward.v1": {
		"domain": "rewards",
		"required": ["schema_version", "kind", "source", "target_type", "effect"],
		"legacy_optional": []
	},
	"mod_manifest.v1": {
		"domain": "mod_manifest",
		"required": ["schema_version", "id", "version", "api_version", "name_key", "dependencies", "content"],
		"legacy_optional": []
	}
}


var _schemas: Dictionary = {}


func _init() -> void:
	_schemas = BUILTIN_SCHEMAS.duplicate(true)


func register_schema(schema_id: String, definition: Dictionary) -> bool:
	if schema_id == "" or _schemas.has(schema_id) or definition.is_empty():
		return false
	_schemas[schema_id] = definition.duplicate(true)
	return true


func has_schema(schema_id: String) -> bool:
	return _schemas.has(schema_id)


func schema(schema_id: String) -> Dictionary:
	return (_schemas.get(schema_id, {}) as Dictionary).duplicate(true)


func schema_id_for_domain(domain: String) -> String:
	for schema_id in _schemas.keys():
		if String(_schemas[schema_id].get("domain", "")) == domain:
			return String(schema_id)
	return ""


func required_fields(schema_id: String) -> Array:
	return (_schemas.get(schema_id, {}).get("required", []) as Array).duplicate()


func legacy_optional_fields(schema_id: String) -> Array:
	return (_schemas.get(schema_id, {}).get("legacy_optional", []) as Array).duplicate()


func skill_action_types() -> Array[String]:
	return [
		SkillActionService.ACTION_DAMAGE,
		SkillActionService.ACTION_MODIFY_ARMOR,
		SkillActionService.ACTION_APPLY_STATUS,
		SkillActionService.ACTION_GAIN_BLOCK,
		SkillActionService.ACTION_GAIN_DODGE,
		SkillActionService.ACTION_INTERRUPT,
		SkillActionService.ACTION_SET_COUNTER_ATTACK,
		SkillActionService.ACTION_CLEAR_DEBUFFS,
		SkillActionService.ACTION_HEAL,
		SkillActionService.ACTION_SET_DUEL,
		SkillActionService.ACTION_SET_DEFLECT,
		SkillActionService.ACTION_SUMMON
	]


func trigger_event_types() -> Array[String]:
	return [
		TriggerEvents.ON_TURN_START,
		TriggerEvents.ON_TURN_END,
		TriggerEvents.ON_HIT_DEALT,
		TriggerEvents.ON_HIT_RECEIVED,
		TriggerEvents.ON_DODGE,
		TriggerEvents.ON_KILL,
		TriggerEvents.ON_CRITICAL,
		TriggerEvents.ON_BLOCK_GAIN,
		TriggerEvents.ON_HEAL_RECEIVED,
		TriggerEvents.ON_BATTLE_START,
		TriggerEvents.ON_ATTACK_COMPLETE
	]


func trigger_action_types() -> Array[String]:
	return [
		TriggerEvents.ACTION_DOT,
		TriggerEvents.ACTION_HOT,
		TriggerEvents.ACTION_REFLECT,
		TriggerEvents.ACTION_LIFESTEAL,
		TriggerEvents.ACTION_GAIN_BLOCK,
		TriggerEvents.ACTION_GAIN_DODGE,
		TriggerEvents.ACTION_HEAL,
		TriggerEvents.ACTION_APPLY_STATUS,
		TriggerEvents.ACTION_REMOVE_STATUS,
		TriggerEvents.ACTION_EXTRA_DAMAGE,
		TriggerEvents.ACTION_COUNTER_ALL,
		TriggerEvents.ACTION_INCREMENT_COUNTER,
		TriggerEvents.ACTION_RESET_COUNTER
	]
