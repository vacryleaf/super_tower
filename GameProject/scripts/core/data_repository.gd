extends RefCounted
class_name DataRepository

const DEFAULT_PATH := "res://data/catalog_v1.json"

var path := DEFAULT_PATH
var data: Dictionary = {}


func _init(source_path: String = DEFAULT_PATH) -> void:
	path = source_path


func load_data() -> Dictionary:
	if not data.is_empty():
		return data
	if not FileAccess.file_exists(path):
		data = {}
		return data
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		data = {}
		return data
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK or typeof(json.data) != TYPE_DICTIONARY:
		data = {}
		return data
	data = json.data
	return data


func table(table_name: String) -> Dictionary:
	var loaded := load_data()
	var tables: Dictionary = loaded.get("tables", {})
	var table_data: Variant = tables.get(table_name, {})
	if typeof(table_data) == TYPE_DICTIONARY:
		return (table_data as Dictionary).duplicate(true)
	return {}


func version() -> int:
	return int(load_data().get("version", 0))


func available_tables() -> Array[String]:
	var loaded := load_data()
	var tables: Dictionary = loaded.get("tables", {})
	var result: Array[String] = []
	for key in tables.keys():
		result.append(String(key))
	return result
