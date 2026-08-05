extends RefCounted
class_name ModLoader

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

const API_VERSION := 1
const MANIFEST_FILE := "mod.json"
const SUPPORTED_DOMAINS := ["skills", "weapons", "monsters", "items"]
const DOMAIN_SINGULAR := {
	"skills": "skill",
	"weapons": "weapon",
	"monsters": "monster",
	"items": "item"
}

var mods_root := "user://mods"
var _manifests: Dictionary = {}
var _loaded_content: Dictionary = {}
var _registered_content: Dictionary = {}
var _active_mods: Dictionary = {}
var _disabled_mods: Dictionary = {}
var _errors: Array[Dictionary] = []


func _init(root_path: String = "user://mods") -> void:
	mods_root = root_path


func discover_mods() -> Array[Dictionary]:
	_manifests.clear()
	_loaded_content.clear()
	var result: Array[Dictionary] = []
	var directory := DirAccess.open(mods_root)
	if directory == null:
		return result
	directory.list_dir_begin()
	while true:
		var package_name := directory.get_next()
		if package_name == "":
			break
		if not directory.current_is_dir() or package_name in [".", ".."]:
			continue
		var package_path := mods_root.path_join(package_name)
		var manifest_path := package_path.path_join(MANIFEST_FILE)
		var manifest := _read_json_dictionary(manifest_path)
		var mod_id := String(manifest.get("id", package_name))
		var record := {
			"id": mod_id,
			"package_path": package_path,
			"manifest_path": manifest_path,
			"manifest": manifest
		}
		if _manifests.has(mod_id):
			_record_error(mod_id, manifest_path, "id", "重复的 Mod ID。", "duplicate_mod_id")
			continue
		_manifests[mod_id] = record
		result.append(record)
	directory.list_dir_end()
	return result


func validate_manifest(manifest: Dictionary, package_path: String = "") -> Dictionary:
	var normalized := manifest.duplicate(true)
	var errors: Array[Dictionary] = []
	var mod_id := String(normalized.get("id", ""))
	var manifest_path := package_path.path_join(MANIFEST_FILE) if package_path != "" else MANIFEST_FILE
	if not _is_valid_identifier(mod_id, true):
		errors.append(_make_error(mod_id, manifest_path, "id", "Mod ID 必须由字母、数字、下划线、短横线和点组成。", "invalid_mod_id"))
	if int(normalized.get("schema_version", 0)) != 1:
		errors.append(_make_error(mod_id, manifest_path, "schema_version", "只支持 manifest schema_version=1。", "unsupported_schema_version"))
	if not _is_semver(String(normalized.get("version", ""))):
		errors.append(_make_error(mod_id, manifest_path, "version", "version 必须是可比较的 x.y.z 格式。", "invalid_version"))
	if int(normalized.get("api_version", 0)) != API_VERSION:
		errors.append(_make_error(mod_id, manifest_path, "api_version", "Mod API 版本不兼容。", "incompatible_api_version"))
	if typeof(normalized.get("name_key", "")) != TYPE_STRING or String(normalized.get("name_key", "")) == "":
		errors.append(_make_error(mod_id, manifest_path, "name_key", "缺少 name_key。", "missing_name_key"))
	if typeof(normalized.get("dependencies", [])) != TYPE_ARRAY:
		errors.append(_make_error(mod_id, manifest_path, "dependencies", "dependencies 必须是数组。", "invalid_dependencies"))
	else:
		for index in range((normalized.get("dependencies", []) as Array).size()):
			var dependency: Variant = (normalized.get("dependencies", []) as Array)[index]
			if _normalize_dependency(dependency).is_empty():
				errors.append(_make_error(mod_id, manifest_path, "dependencies[%d]" % index, "依赖必须包含 id 和可选 version。", "invalid_dependency"))
	if typeof(normalized.get("content", null)) != TYPE_DICTIONARY:
		errors.append(_make_error(mod_id, manifest_path, "content", "缺少 content 对象。", "missing_content"))
	else:
		var content: Dictionary = normalized["content"]
		for domain in content.keys():
			var domain_id := String(domain)
			if not SUPPORTED_DOMAINS.has(domain_id):
				errors.append(_make_error(mod_id, manifest_path, "content.%s" % domain_id, "未知内容领域。", "unsupported_domain"))
				continue
			if typeof(content[domain]) != TYPE_ARRAY:
				errors.append(_make_error(mod_id, manifest_path, "content.%s" % domain_id, "领域文件列表必须是数组。", "invalid_content_paths"))
				continue
			for index in range((content[domain] as Array).size()):
				var relative_path := String((content[domain] as Array)[index])
				if not _is_safe_content_path(relative_path):
					errors.append(_make_error(mod_id, manifest_path, "content.%s[%d]" % [domain_id, index], "内容路径必须是包内相对 JSON 路径。", "invalid_content_path"))
	return {"ok": errors.is_empty(), "manifest": normalized, "errors": errors}


func load_content(mod_id: String) -> Dictionary:
	if _manifests.is_empty():
		discover_mods()
	var visiting: Dictionary = {}
	return _load_content_recursive(mod_id, visiting)


func register_content(mod_id: String) -> bool:
	if _manifests.is_empty():
		discover_mods()
	var payload := load_content(mod_id)
	if payload.is_empty():
		return false
	var order: Array[String] = []
	if not _collect_dependency_order(mod_id, order, {}):
		return false
	for dependency_id in order:
		if _active_mods.has(dependency_id):
			continue
		var dependency_payload: Dictionary = _loaded_content.get(dependency_id, {})
		if dependency_payload.is_empty() or not _register_payload(dependency_id, dependency_payload):
			return false
	return true


func disable_mod(mod_id: String) -> bool:
	if not _active_mods.has(mod_id):
		return false
	var dependents: Array[String] = []
	for active_id in _active_mods.keys():
		if active_id == mod_id:
			continue
		for dependency in _dependencies(_active_mods[active_id]):
			if String(dependency.get("id", "")) == mod_id:
				dependents.append(String(active_id))
	for dependent_id in dependents:
		disable_mod(dependent_id)
	for domain in SUPPORTED_DOMAINS:
		var table: Dictionary = _registered_content.get(domain, {})
		for content_id in table.keys():
			if String(table[content_id].get("mod_id", "")) == mod_id:
				table.erase(content_id)
	_active_mods.erase(mod_id)
	_disabled_mods[mod_id] = true
	return true


func content_errors() -> Array[Dictionary]:
	return _errors.duplicate(true)


func active_mod_ids() -> Array[String]:
	var result: Array[String] = []
	for mod_id in _active_mods.keys():
		result.append(String(mod_id))
	result.sort()
	return result


func content_table(domain: String) -> Dictionary:
	var result: Dictionary = {}
	var table: Dictionary = _registered_content.get(domain, {})
	for content_id in table.keys():
		result[String(content_id)] = table[content_id].get("data", {}).duplicate(true)
	return result


func _load_content_recursive(mod_id: String, visiting: Dictionary) -> Dictionary:
	if _loaded_content.has(mod_id):
		return _loaded_content[mod_id]
	if visiting.has(mod_id):
		_record_error(mod_id, "", "dependencies", "发现循环依赖。", "dependency_cycle")
		return {}
	if not _manifests.has(mod_id):
		_record_error(mod_id, "", "id", "找不到依赖的 Mod。", "missing_dependency")
		return {}
	visiting[mod_id] = true
	var record: Dictionary = _manifests[mod_id]
	var validation := validate_manifest(record.get("manifest", {}), String(record.get("package_path", "")))
	if not bool(validation.get("ok", false)):
		_record_errors(validation.get("errors", []))
		visiting.erase(mod_id)
		return {}
	var manifest: Dictionary = validation["manifest"]
	for dependency in _dependencies(manifest):
		var dependency_id := String(dependency.get("id", ""))
		if not _manifests.has(dependency_id):
			_record_error(mod_id, String(record.get("manifest_path", "")), "dependencies", "缺少依赖 %s。" % dependency_id, "missing_dependency")
			visiting.erase(mod_id)
			return {}
		var dependency_manifest: Dictionary = _manifests[dependency_id].get("manifest", {})
		if not _version_satisfies(String(dependency_manifest.get("version", "")), String(dependency.get("version", "*"))):
			_record_error(mod_id, String(record.get("manifest_path", "")), "dependencies", "依赖 %s 版本不满足。" % dependency_id, "dependency_version_mismatch")
			visiting.erase(mod_id)
			return {}
		if _load_content_recursive(dependency_id, visiting).is_empty():
			visiting.erase(mod_id)
			return {}
	var content := _read_content_files(mod_id, String(record.get("package_path", "")), manifest)
	if content.is_empty() and _has_content_paths(manifest):
		visiting.erase(mod_id)
		return {}
	var payload := {"manifest": manifest, "content": content}
	_loaded_content[mod_id] = payload
	visiting.erase(mod_id)
	return payload


func _read_content_files(mod_id: String, package_path: String, manifest: Dictionary) -> Dictionary:
	var content_result: Dictionary = {}
	var content: Dictionary = manifest.get("content", {})
	for domain in SUPPORTED_DOMAINS:
		var entries: Array[Dictionary] = []
		for relative_path in content.get(domain, []):
			var path := package_path.path_join(String(relative_path))
			var entry := _read_json_dictionary(path)
			if entry.is_empty():
				_record_error(mod_id, path, "", "内容文件不是有效 JSON 对象。", "invalid_content_file")
				return {}
			var entry_id := String(entry.get("id", ""))
			var expected_prefix := "%s.%s." % [mod_id, DOMAIN_SINGULAR[domain]]
			if not entry_id.begins_with(expected_prefix):
				_record_error(mod_id, path, "id", "内容 ID 必须以 %s 开头。" % expected_prefix, "invalid_content_id")
				return {}
			entries.append(entry)
		content_result[domain] = entries
	return content_result


func _register_payload(mod_id: String, payload: Dictionary) -> bool:
	var content: Dictionary = payload.get("content", {})
	for domain in SUPPORTED_DOMAINS:
		for entry in content.get(domain, []):
			var content_id := String(entry.get("id", ""))
			if _content_conflicts(domain, content_id):
				_record_error(mod_id, "", "content.%s" % domain, "内容 ID %s 与已有内容冲突。" % content_id, "content_id_conflict")
				return false
	for domain in SUPPORTED_DOMAINS:
		var table: Dictionary = _registered_content.get(domain, {})
		for entry in content.get(domain, []):
			var content_id := String(entry.get("id", ""))
			table[content_id] = {"mod_id": mod_id, "data": entry.duplicate(true)}
		_registered_content[domain] = table
	_active_mods[mod_id] = payload["manifest"].duplicate(true)
	return true


func _content_conflicts(domain: String, content_id: String) -> bool:
	if _registered_content.get(domain, {}).has(content_id):
		return true
	match domain:
		"skills":
			return DataCatalog.SKILLS.has(content_id) or DataCatalog.INNATE_SKILLS.has(content_id)
		"weapons":
			return DataCatalog.WEAPON_PROFILES.has(content_id) or DataCatalog.WEAPON_ITEM_PROFILES.has(content_id)
		"monsters":
			return not DataCatalog.monster_unit(content_id).is_empty()
		"items":
			return DataCatalog.CONSUMABLES.has(content_id) or DataCatalog.EQUIPMENT.has(content_id)
	return false


func _collect_dependency_order(mod_id: String, order: Array[String], visiting: Dictionary) -> bool:
	if visiting.has(mod_id):
		return false
	visiting[mod_id] = true
	var manifest: Dictionary = _loaded_content.get(mod_id, {}).get("manifest", {})
	for dependency in _dependencies(manifest):
		var dependency_id := String(dependency.get("id", ""))
		if not _collect_dependency_order(dependency_id, order, visiting):
			return false
	if not order.has(mod_id):
		order.append(mod_id)
	return true


func _dependencies(manifest: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw_dependency in manifest.get("dependencies", []):
		var dependency := _normalize_dependency(raw_dependency)
		if not dependency.is_empty():
			result.append(dependency)
	return result


func _normalize_dependency(raw_dependency: Variant) -> Dictionary:
	if typeof(raw_dependency) == TYPE_STRING:
		return {"id": String(raw_dependency), "version": "*"}
	if typeof(raw_dependency) != TYPE_DICTIONARY:
		return {}
	var dependency: Dictionary = raw_dependency
	var mod_id := String(dependency.get("id", ""))
	if mod_id == "":
		return {}
	return {"id": mod_id, "version": String(dependency.get("version", "*"))}


func _has_content_paths(manifest: Dictionary) -> bool:
	for domain in SUPPORTED_DOMAINS:
		if not (manifest.get("content", {}).get(domain, []) as Array).is_empty():
			return true
	return false


func _is_safe_content_path(path: String) -> bool:
	if path == "" or path.get_extension().to_lower() != "json":
		return false
	if path.begins_with("/") or path.begins_with("\\") or path.contains(":") or path.contains("\\"):
		return false
	for segment in path.split("/"):
		if segment == ".." or segment == "" or segment == ".":
			return false
	return true


func _is_valid_identifier(value: String, allow_dots: bool) -> bool:
	if value == "":
		return false
	var regex := RegEx.new()
	regex.compile("^[A-Za-z0-9_-]+(?:\\.[A-Za-z0-9_-]+)*$")
	return regex.search(value) != null if allow_dots else value.find(".") < 0 and regex.search(value) != null


func _is_semver(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[0-9]+\\.[0-9]+\\.[0-9]+$")
	return regex.search(value) != null


func _version_satisfies(version: String, requirement: String) -> bool:
	if requirement == "" or requirement == "*":
		return true
	var actual := _version_tuple(version)
	if actual.is_empty():
		return false
	for expression in requirement.replace(",", " ").split(" "):
		if expression == "":
			continue
		var operator := "="
		var expected_text := expression
		for candidate in [">=", "<=", ">", "<", "=", "^", "~"]:
			if expression.begins_with(candidate):
				operator = candidate
				expected_text = expression.substr(candidate.length())
				break
		var expected := _version_tuple(expected_text)
		if expected.is_empty() or not _compare_version(actual, expected, operator):
			return false
	return true


func _compare_version(actual: Array[int], expected: Array[int], operator: String) -> bool:
	var comparison := 0
	for index in range(3):
		if actual[index] != expected[index]:
			comparison = 1 if actual[index] > expected[index] else -1
			break
	match operator:
		">=": return comparison >= 0
		"<=": return comparison <= 0
		">": return comparison > 0
		"<": return comparison < 0
		"^": return comparison >= 0 and actual[0] == expected[0]
		"~": return comparison >= 0 and actual[0] == expected[0] and actual[1] == expected[1]
	return comparison == 0


func _version_tuple(value: String) -> Array[int]:
	if not _is_semver(value):
		return []
	var result: Array[int] = []
	for part in value.split("."):
		result.append(int(part))
	return result


func _read_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return (json.data as Dictionary).duplicate(true)


func _record_errors(errors: Array) -> void:
	for error in errors:
		if typeof(error) == TYPE_DICTIONARY:
			_errors.append((error as Dictionary).duplicate(true))


func _record_error(mod_id: String, file_path: String, field: String, message: String, code: String) -> void:
	_errors.append(_make_error(mod_id, file_path, field, message, code))


func _make_error(mod_id: String, file_path: String, field: String, message: String, code: String) -> Dictionary:
	return {"mod_id": mod_id, "file": file_path, "field": field, "message": message, "code": code}
