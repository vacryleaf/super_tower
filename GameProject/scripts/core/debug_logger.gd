extends RefCounted
class_name DebugLogger

var enabled := true
var log_path := ""


func configure(session_tag: String, debug_enabled: bool) -> void:
	enabled = debug_enabled
	if not enabled:
		return
	var debug_dir := ProjectSettings.globalize_path("res://debug")
	DirAccess.make_dir_recursive_absolute(debug_dir)
	var stamp := Time.get_datetime_string_from_system().replace(":", "-").replace(" ", "_")
	if session_tag != "":
		stamp += "_" + session_tag
	log_path = "%s/runtime_%s.log" % [debug_dir, stamp]
	_write_line("=== debug session start ===")


func log(message: String) -> void:
	if not enabled:
		return
	var line := "[%s] %s" % [Time.get_datetime_string_from_system(), message]
	print(line)
	_write_line(line)


func _write_line(line: String) -> void:
	if log_path == "":
		return
	var file := FileAccess.open(log_path, FileAccess.WRITE_READ)
	if file == null:
		file = FileAccess.open(log_path, FileAccess.WRITE)
		if file == null:
			return
	file.seek_end()
	file.store_line(line)
	file.flush()
