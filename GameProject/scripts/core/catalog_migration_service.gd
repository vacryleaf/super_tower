extends RefCounted
class_name CatalogMigrationService

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const DataRepository = preload("res://scripts/core/data_repository.gd")

const RUNTIME_SWITCHABLE_TABLES := ["state_cards", "classes"]

var repository := DataRepository.new()


func table_status(table_name: String) -> String:
	var notes := repository.migration_notes()
	if (notes.get("runtime_switchable_tables", []) as Array).has(table_name):
		return "migrated"
	if (notes.get("partial_tables", []) as Array).has(table_name):
		return "partial"
	if (notes.get("migrated_tables", []) as Array).has(table_name):
		return "migrated"
	return "pending"


func parity_report() -> Dictionary:
	return {
		"state_cards": _compare_table("state_cards", DataCatalog.STATE_CARDS),
		"classes": _compare_table("classes", DataCatalog.CLASSES),
		"skills": _compare_subset_table("skills", DataCatalog.SKILLS),
		"enemy_unit_manifest": _compare_enemy_manifest()
	}


func can_use_external(table_name: String) -> bool:
	if table_status(table_name) != "migrated":
		return false
	var report: Dictionary = parity_report().get(table_name, {})
	return bool(report.get("complete", false))


func resolve_table(table_name: String, runtime_table: Dictionary, prefer_external: bool = false) -> Dictionary:
	if prefer_external and can_use_external(table_name):
		return repository.table(table_name)
	return runtime_table.duplicate(true)


func _compare_table(table_name: String, runtime_table: Dictionary) -> Dictionary:
	var external_table := repository.table(table_name)
	var missing_external: Array[String] = []
	var missing_runtime: Array[String] = []
	var field_mismatches: Array[String] = []
	for entry_id in runtime_table.keys():
		if not external_table.has(entry_id):
			missing_external.append(String(entry_id))
			continue
		_compare_entry(String(entry_id), runtime_table[entry_id], external_table[entry_id], field_mismatches)
	for entry_id in external_table.keys():
		if not runtime_table.has(entry_id):
			missing_runtime.append(String(entry_id))
	return {
		"status": table_status(table_name),
		"complete": missing_external.is_empty() and missing_runtime.is_empty() and field_mismatches.is_empty(),
		"missing_external": missing_external,
		"missing_runtime": missing_runtime,
		"field_mismatches": field_mismatches
	}


func _compare_subset_table(table_name: String, runtime_table: Dictionary) -> Dictionary:
	var external_table := repository.table(table_name)
	var missing_runtime: Array[String] = []
	var field_mismatches: Array[String] = []
	for entry_id in external_table.keys():
		if not runtime_table.has(entry_id):
			missing_runtime.append(String(entry_id))
			continue
		_compare_entry(String(entry_id), external_table[entry_id], runtime_table[entry_id], field_mismatches)
	return {
		"status": table_status(table_name),
		"complete": false,
		"subset_compatible": missing_runtime.is_empty() and field_mismatches.is_empty(),
		"missing_runtime": missing_runtime,
		"field_mismatches": field_mismatches
	}


func _compare_enemy_manifest() -> Dictionary:
	var manifest := repository.table("enemy_unit_manifest")
	var expected := {
		"normal": _unit_ids(DataCatalog.NORMAL_UNITS),
		"elite": _unit_ids(DataCatalog.ELITE_UNITS),
		"boss": _unit_ids(DataCatalog.BOSS_UNITS)
	}
	var mismatches: Array[String] = []
	for rank in expected.keys():
		var external_ids: Array[String] = []
		for unit_id in manifest.get(rank, []):
			external_ids.append(String(unit_id))
		external_ids.sort()
		var runtime_ids: Array[String] = expected[rank]
		if external_ids != runtime_ids:
			mismatches.append(String(rank))
	return {
		"status": table_status("enemy_unit_manifest"),
		"complete": mismatches.is_empty(),
		"rank_mismatches": mismatches
	}


func _unit_ids(units: Array) -> Array[String]:
	var result: Array[String] = []
	for unit in units:
		if typeof(unit) == TYPE_DICTIONARY:
			result.append(String((unit as Dictionary).get("id", "")))
	result.sort()
	return result


func _compare_entry(entry_id: String, expected: Dictionary, actual: Dictionary, mismatches: Array[String]) -> void:
	for field in expected.keys():
		if not actual.has(field) or not _values_equal(expected[field], actual[field]):
			mismatches.append("%s.%s" % [entry_id, String(field)])
	for field in actual.keys():
		if not expected.has(field):
			mismatches.append("%s.%s" % [entry_id, String(field)])


func _values_equal(expected: Variant, actual: Variant) -> bool:
	if typeof(expected) in [TYPE_INT, TYPE_FLOAT] and typeof(actual) in [TYPE_INT, TYPE_FLOAT]:
		return is_equal_approx(float(expected), float(actual))
	if typeof(expected) == TYPE_DICTIONARY and typeof(actual) == TYPE_DICTIONARY:
		var expected_dict: Dictionary = expected
		var actual_dict: Dictionary = actual
		if expected_dict.size() != actual_dict.size():
			return false
		for key in expected_dict.keys():
			if not actual_dict.has(key) or not _values_equal(expected_dict[key], actual_dict[key]):
				return false
		return true
	if typeof(expected) == TYPE_ARRAY and typeof(actual) == TYPE_ARRAY:
		var expected_array: Array = expected
		var actual_array: Array = actual
		if expected_array.size() != actual_array.size():
			return false
		for index in range(expected_array.size()):
			if not _values_equal(expected_array[index], actual_array[index]):
				return false
		return true
	return expected == actual
