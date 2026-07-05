extends RefCounted
class_name SaveProfile

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

const SAVE_PATH := "user://savegame.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func read_profile(persistent_snapshot: Callable) -> Dictionary:
	if not has_save():
		return empty_profile()
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return empty_profile()
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK or typeof(json.data) != TYPE_DICTIONARY:
		return empty_profile()
	var data: Dictionary = json.data
	if int(data.get("version", 0)) == 2:
		if not data.has("roster"):
			data["roster"] = {}
		if not data.has("active_run"):
			data["active_run"] = {}
		return data
	if int(data.get("version", 0)) == 1:
		return profile_from_legacy_run(data, persistent_snapshot)
	return empty_profile()


func write_profile(profile: Dictionary) -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(profile))
	return true


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func empty_profile() -> Dictionary:
	return {
		"version": 2,
		"roster": {},
		"active_run": {}
	}


func profile_from_legacy_run(run_data: Dictionary, persistent_snapshot: Callable) -> Dictionary:
	var roster := {}
	var saved_player := _dictionary(run_data.get("player", {}))
	var saved_class := String(run_data.get("class_id", saved_player.get("class_id", "")))
	if saved_class != "" and DataCatalog.CLASSES.has(saved_class) and not saved_player.is_empty():
		roster[saved_class] = persistent_snapshot.call(saved_player)
	return {
		"version": 2,
		"roster": roster,
		"active_run": run_data
	}


func _dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	return {}
