extends RefCounted
class_name AppSettings

const SETTINGS_PATH := "user://settings.json"
const DEFAULT_RESOLUTION := Vector2i(1280, 720)

var data: Dictionary = {}


func load_settings() -> Dictionary:
	if not data.is_empty():
		return data
	if not FileAccess.file_exists(SETTINGS_PATH):
		data = _default_settings()
		return data
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		data = _default_settings()
		return data
	var json := JSON.new()
	if json.parse(file.get_as_text()) != OK or typeof(json.data) != TYPE_DICTIONARY:
		data = _default_settings()
		return data
	data = (json.data as Dictionary).duplicate(true)
	_ensure_defaults()
	return data


func current_resolution() -> Vector2i:
	var loaded := load_settings()
	return Vector2i(int(loaded.get("resolution_width", DEFAULT_RESOLUTION.x)), int(loaded.get("resolution_height", DEFAULT_RESOLUTION.y)))


func set_resolution(resolution: Vector2i) -> void:
	load_settings()
	data["resolution_width"] = resolution.x
	data["resolution_height"] = resolution.y
	_save()


func apply_resolution() -> void:
	var resolution := current_resolution()
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(resolution)
	DisplayServer.window_set_position(Vector2i(40, 40))


func _default_settings() -> Dictionary:
	return {
		"version": 1,
		"resolution_width": DEFAULT_RESOLUTION.x,
		"resolution_height": DEFAULT_RESOLUTION.y
	}


func _ensure_defaults() -> void:
	if not data.has("version"):
		data["version"] = 1
	if not data.has("resolution_width"):
		data["resolution_width"] = DEFAULT_RESOLUTION.x
	if not data.has("resolution_height"):
		data["resolution_height"] = DEFAULT_RESOLUTION.y


func _save() -> void:
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(data))
