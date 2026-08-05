extends RefCounted
class_name ContentValidator

const SchemaRegistry = preload("res://scripts/core/schema_registry.gd")

const TARGETS := ["selected", "all_enemies", "adjacent", "self", "ally_selected"]
const STACK_MODES := ["replace", "stack", "add"]

var registry := SchemaRegistry.new()


func validate_entry(domain: String, entry: Dictionary, context: Dictionary = {}) -> Dictionary:
	var schema_id := registry.schema_id_for_domain(domain)
	var errors: Array[Dictionary] = []
	if schema_id == "":
		errors.append(_error("", "", "不支持的内容领域。", "unsupported_domain"))
		return {"ok": false, "entry": entry.duplicate(true), "errors": errors}
	var normalized := entry.duplicate(true)
	if not normalized.has("id") and context.has("id"):
		normalized["id"] = String(context["id"])
	if domain == "skills" and not normalized.has("kind") and normalized.has("type"):
		normalized["kind"] = normalized["type"]
	var allow_legacy := bool(context.get("allow_legacy", false))
	for required_field in registry.required_fields(schema_id):
		if normalized.has(required_field):
			continue
		if allow_legacy and registry.legacy_optional_fields(schema_id).has(required_field):
			continue
		errors.append(_error(String(required_field), "", "缺少必填字段。", "missing_required_field"))
	_validate_common(normalized, context, errors)
	match domain:
		"skills":
			_validate_skill(normalized, allow_legacy, errors)
		"items":
			_validate_item(normalized, allow_legacy, errors)
		"weapons":
			_validate_weapon(normalized, allow_legacy, errors)
		"monsters":
			_validate_monster(normalized, allow_legacy, errors)
		"statuses", "traits":
			_validate_status_or_trait(domain, normalized, errors)
		"rewards":
			_validate_reward(normalized, errors)
	return {"ok": errors.is_empty(), "entry": normalized, "errors": errors}


func validate_content(domain: String, entries: Array, context: Dictionary = {}) -> Dictionary:
	var normalized: Array[Dictionary] = []
	var errors: Array[Dictionary] = []
	for index in range(entries.size()):
		var entry: Variant = entries[index]
		if typeof(entry) != TYPE_DICTIONARY:
			errors.append(_error("[%d]" % index, "", "内容条目必须是对象。", "invalid_entry_type"))
			continue
		var result := validate_entry(domain, entry, context)
		normalized.append(result["entry"])
		for error in result["errors"]:
			var enriched: Dictionary = error.duplicate(true)
			enriched["path"] = "%s[%d].%s" % [domain, index, String(error.get("path", ""))]
			errors.append(enriched)
	return {"ok": errors.is_empty(), "entries": normalized, "errors": errors}


func _validate_common(entry: Dictionary, context: Dictionary, errors: Array[Dictionary]) -> void:
	var entry_id := String(entry.get("id", ""))
	if entry_id == "":
		return
	if not _is_identifier(entry_id):
		errors.append(_error("id", entry_id, "ID 格式非法。", "invalid_id"))
	var namespace_id := String(context.get("namespace", ""))
	if namespace_id != "" and not entry_id.begins_with(namespace_id + "."):
		errors.append(_error("id", entry_id, "ID 必须位于 Mod 命名空间下。", "invalid_namespace"))
	if entry.has("schema_version") and not _is_integer_number(entry["schema_version"]):
		errors.append(_error("schema_version", entry_id, "schema_version 必须是整数。", "invalid_schema_version"))
	if entry.has("name_key") and (typeof(entry["name_key"]) != TYPE_STRING or String(entry["name_key"]) == ""):
		errors.append(_error("name_key", entry_id, "name_key 必须是非空字符串。", "invalid_name_key"))


func _validate_skill(skill: Dictionary, allow_legacy: bool, errors: Array[Dictionary]) -> void:
	if skill.has("slot") and (not _is_integer_number(skill["slot"]) or int(skill["slot"]) < 0 or int(skill["slot"]) > 4):
		errors.append(_error("slot", String(skill.get("id", "")), "技能槽位必须在 0-4。", "invalid_slot"))
	for field in ["energy_cost", "cooldown"]:
		if skill.has(field) and (not _is_integer_number(skill[field]) or int(skill[field]) < 0):
			errors.append(_error(field, String(skill.get("id", "")), "数值必须是非负整数。", "invalid_skill_value"))
	if not skill.has("actions"):
		if not allow_legacy:
			errors.append(_error("actions", String(skill.get("id", "")), "技能必须声明 actions。", "missing_actions"))
		return
	_validate_skill_actions(skill.get("actions", []), errors)


func _validate_skill_actions(actions: Variant, errors: Array[Dictionary]) -> void:
	if typeof(actions) != TYPE_ARRAY:
		errors.append(_error("actions", "", "actions 必须是数组。", "invalid_actions"))
		return
	for index in range((actions as Array).size()):
		var action: Variant = (actions as Array)[index]
		if typeof(action) != TYPE_DICTIONARY:
			errors.append(_error("actions[%d]" % index, "", "action 必须是对象。", "invalid_action_type"))
			continue
		var action_type := String((action as Dictionary).get("type", ""))
		if not registry.skill_action_types().has(action_type):
			errors.append(_error("actions[%d].type" % index, "", "未知 skill action。", "unknown_action"))
		if action.has("target") and not TARGETS.has(String((action as Dictionary)["target"])):
			errors.append(_error("actions[%d].target" % index, "", "未知 action target。", "unknown_target"))
		if action.has("conditions") and typeof(action["conditions"]) != TYPE_ARRAY:
			errors.append(_error("actions[%d].conditions" % index, "", "conditions 必须是数组。", "invalid_conditions"))
		if action_type == "apply_status" and typeof(action.get("status", null)) == TYPE_DICTIONARY:
			_validate_status_or_trait("statuses", action["status"], errors, "actions[%d].status" % index)


func _validate_item(item: Dictionary, allow_legacy: bool, errors: Array[Dictionary]) -> void:
	if typeof(item.get("kind", "")) != TYPE_STRING or String(item.get("kind", "")) == "":
		errors.append(_error("kind", String(item.get("id", "")), "物品 kind 不能为空。", "invalid_item_kind"))
	if item.has("actions"):
		_validate_skill_actions(item["actions"], errors)
	elif not allow_legacy:
		errors.append(_error("actions", String(item.get("id", "")), "物品必须声明 actions。", "missing_actions"))


func _validate_weapon(weapon: Dictionary, allow_legacy: bool, errors: Array[Dictionary]) -> void:
	if String(weapon.get("slot", "")) == "":
		errors.append(_error("slot", String(weapon.get("id", "")), "武器 slot 不能为空。", "invalid_weapon_slot"))
	for field in ["agility", "attack_damage", "critical_weight"]:
		if weapon.has(field) and typeof(weapon[field]) not in [TYPE_INT, TYPE_FLOAT]:
			errors.append(_error(field, String(weapon.get("id", "")), "武器数值必须是数字。", "invalid_weapon_value"))
	if not allow_legacy and (String(weapon.get("skill_1", "")) == "" or String(weapon.get("skill_2", "")) == ""):
		errors.append(_error("skill_1/skill_2", String(weapon.get("id", "")), "武器必须声明两个技能引用。", "missing_weapon_skill"))


func _validate_monster(monster: Dictionary, allow_legacy: bool, errors: Array[Dictionary]) -> void:
	if not ["normal", "elite", "boss"].has(String(monster.get("rank", ""))):
		errors.append(_error("rank", String(monster.get("id", "")), "怪物 rank 必须是 normal/elite/boss。", "invalid_monster_rank"))
	for field in ["hp", "attack", "defense"]:
		if monster.has(field) and (not _is_integer_number(monster[field]) or int(monster[field]) < 0):
			errors.append(_error(field, String(monster.get("id", "")), "怪物属性必须是非负整数。", "invalid_monster_value"))
	if not allow_legacy and typeof(monster.get("passive_skills", null)) != TYPE_ARRAY:
		errors.append(_error("passive_skills", String(monster.get("id", "")), "怪物必须声明 passive_skills。", "invalid_passive_skills"))


func _validate_status_or_trait(domain: String, value: Variant, errors: Array[Dictionary], path_prefix: String = "") -> void:
	if typeof(value) != TYPE_DICTIONARY:
		errors.append(_error(path_prefix, "", "status/trait 必须是对象。", "invalid_status_type"))
		return
	var status: Dictionary = value
	if String(status.get("id", "")) == "":
		errors.append(_error(path_prefix + ".id", "", "status/trait 缺少 id。", "missing_status_id"))
	if domain == "traits":
		return
	if String(status.get("kind", "")) == "":
		errors.append(_error(path_prefix + ".kind", "", "status 缺少 kind。", "missing_status_kind"))
	if not STACK_MODES.has(String(status.get("stack", ""))):
		errors.append(_error(path_prefix + ".stack", "", "status stack 不受支持。", "invalid_status_stack"))
	if not _is_integer_number(status.get("duration", null)):
		errors.append(_error(path_prefix + ".duration", "", "status duration 必须是整数。", "invalid_status_duration"))
	if status.has("triggers"):
		_validate_triggers(status["triggers"], errors, path_prefix + ".triggers")


func _validate_triggers(triggers: Variant, errors: Array[Dictionary], path_prefix: String) -> void:
	if typeof(triggers) != TYPE_ARRAY:
		errors.append(_error(path_prefix, "", "triggers 必须是数组。", "invalid_triggers"))
		return
	for index in range((triggers as Array).size()):
		var trigger: Variant = (triggers as Array)[index]
		if typeof(trigger) != TYPE_DICTIONARY:
			errors.append(_error("%s[%d]" % [path_prefix, index], "", "trigger 必须是对象。", "invalid_trigger_type"))
			continue
		var trigger_dict: Dictionary = trigger
		if not registry.trigger_event_types().has(String(trigger_dict.get("event", ""))):
			errors.append(_error("%s[%d].event" % [path_prefix, index], "", "未知 trigger event。", "unknown_trigger_event"))
		if typeof(trigger_dict.get("actions", null)) != TYPE_ARRAY:
			errors.append(_error("%s[%d].actions" % [path_prefix, index], "", "trigger actions 必须是数组。", "invalid_trigger_actions"))
			continue
		for action_index in range((trigger_dict["actions"] as Array).size()):
			var action: Variant = (trigger_dict["actions"] as Array)[action_index]
			if typeof(action) != TYPE_DICTIONARY or not registry.trigger_action_types().has(String((action as Dictionary).get("type", ""))):
				errors.append(_error("%s[%d].actions[%d]" % [path_prefix, index, action_index], "", "未知 trigger action。", "unknown_trigger_action"))


func _validate_reward(reward: Dictionary, errors: Array[Dictionary]) -> void:
	if typeof(reward.get("effect", null)) != TYPE_DICTIONARY:
		errors.append(_error("effect", String(reward.get("kind", "")), "奖励 effect 必须是对象。", "invalid_reward_effect"))
	if String(reward.get("source", "")) == "":
		errors.append(_error("source", String(reward.get("kind", "")), "奖励 source 不能为空。", "missing_reward_source"))


func _is_identifier(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[A-Za-z0-9_-]+(?:\\.[A-Za-z0-9_-]+)*$")
	return regex.search(value) != null


func _is_integer_number(value: Variant) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	return is_equal_approx(float(value), round(float(value)))


func _error(path: String, entry_id: String, message: String, code: String) -> Dictionary:
	return {"path": path, "id": entry_id, "message": message, "code": code}
