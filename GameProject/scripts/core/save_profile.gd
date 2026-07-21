extends RefCounted
class_name SaveProfile

const DataCatalog = preload("res://scripts/core/data_catalog.gd")

const SAVE_PATH := "user://savegame.json"
const SAVE_VERSION := 3
const SLOT_COUNT := 3
const SLOT_PROFILE_VERSION := 2

var active_slot := 1


func set_slot(slot_index: int) -> void:
	active_slot = _clamp_slot(slot_index)


func current_slot() -> int:
	return active_slot


func has_save(slot_index: int = -1) -> bool:
	var root := _load_root()
	if slot_index >= 1:
		return _slot_profile(root.get("slots", {}), slot_index).size() > 0
	var slots: Dictionary = root.get("slots", {})
	for i in range(1, SLOT_COUNT + 1):
		if _slot_profile(slots, i).size() > 0:
			return true
	return false


func read_profile(persistent_snapshot: Callable) -> Dictionary:
	return read_slot_profile(active_slot, persistent_snapshot)


func read_slot_profile(slot_index: int, persistent_snapshot: Callable) -> Dictionary:
	var root := _load_root()
	var slot_profile: Dictionary = _slot_profile(root.get("slots", {}), slot_index)
	if slot_profile.is_empty():
		return empty_profile(slot_index)
	return _normalize_slot_profile(slot_profile, persistent_snapshot)


func list_slot_profiles(persistent_snapshot: Callable) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var root := _load_root()
	var slots: Dictionary = root.get("slots", {})
	for i in range(1, SLOT_COUNT + 1):
		var profile := _slot_profile(slots, i)
		result.append(_slot_summary(i, profile, persistent_snapshot))
	return result


func write_profile(profile: Dictionary) -> bool:
	return write_slot_profile(active_slot, profile)


func write_slot_profile(slot_index: int, profile: Dictionary) -> bool:
	var root := _load_root()
	var slots: Dictionary = root.get("slots", {})
	slots[str(_clamp_slot(slot_index))] = _normalize_slot_profile(profile, Callable())
	root["version"] = SAVE_VERSION
	root["slots"] = slots
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(root))
	return true


func delete_save(slot_index: int = -1) -> void:
	if slot_index < 1:
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		return
	var root := _load_root()
	var slots: Dictionary = root.get("slots", {})
	slots.erase(str(_clamp_slot(slot_index)))
	root["version"] = SAVE_VERSION
	root["slots"] = slots
	if slots.is_empty():
		if FileAccess.file_exists(SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(root))


func empty_profile(slot_index: int = 1) -> Dictionary:
	return {
		"version": SLOT_PROFILE_VERSION,
		"slot_index": _clamp_slot(slot_index),
		"roster": {},
		"active_run": {},
		"tower_coins": 0,
		"bestiary": {}
	}


func profile_from_legacy_run(run_data: Dictionary, persistent_snapshot: Callable) -> Dictionary:
	var saved_player := _dictionary(run_data.get("player", {}))
	var saved_class := String(run_data.get("class_id", saved_player.get("class_id", "")))
	var slot_profile := empty_profile(1)
	if saved_class != "" and DataCatalog.CLASSES.has(saved_class) and not saved_player.is_empty():
		slot_profile["roster"][saved_class] = persistent_snapshot.call(saved_player) if persistent_snapshot.is_valid() else saved_player
	slot_profile["active_run"] = run_data
	return slot_profile


func _load_root() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {"version": SAVE_VERSION, "slots": {}}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return {"version": SAVE_VERSION, "slots": {}}
	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {"version": SAVE_VERSION, "slots": {}}
	var root: Dictionary = json.data
	if int(root.get("version", 0)) == 2 and not root.has("slots"):
		return {
			"version": SAVE_VERSION,
			"slots": {
				"1": _normalize_slot_profile(root, Callable())
			}
		}
	if not root.has("slots"):
		root["slots"] = {}
	return root


func _normalize_slot_profile(profile: Dictionary, persistent_snapshot: Callable) -> Dictionary:
	if profile.is_empty():
		return {}
	var normalized := profile.duplicate(true)
	if int(normalized.get("version", 0)) < SLOT_PROFILE_VERSION:
		normalized["version"] = SLOT_PROFILE_VERSION
	if not normalized.has("roster"):
		normalized["roster"] = {}
	if not normalized.has("active_run"):
		normalized["active_run"] = {}
	if not normalized.has("tower_coins"):
		normalized["tower_coins"] = 0
	if not normalized.has("bestiary"):
		normalized["bestiary"] = {}
	if normalized.has("active_run") and typeof(normalized["active_run"]) == TYPE_DICTIONARY:
		var active_run: Dictionary = normalized["active_run"]
		if not active_run.is_empty() and not active_run.has("player") and persistent_snapshot.is_valid():
			var player := _dictionary(active_run.get("player", {}))
			if not player.is_empty():
				active_run["player"] = persistent_snapshot.call(player)
	normalized["slot_index"] = _clamp_slot(int(normalized.get("slot_index", 1)))
	return normalized


func _slot_summary(slot_index: int, profile: Dictionary, persistent_snapshot: Callable) -> Dictionary:
	var slot_profile := _normalize_slot_profile(profile, persistent_snapshot)
	var roster: Dictionary = slot_profile.get("roster", {})
	var active_run: Dictionary = slot_profile.get("active_run", {})
	var summary := {
		"slot_index": _clamp_slot(slot_index),
		"occupied": not roster.is_empty() or not active_run.is_empty(),
		"has_active_run": not active_run.is_empty(),
		"class_id": "",
		"class_name": "",
		"headline": "空槽",
		"detail": "还没有记录。",
		"tower_coins": int(slot_profile.get("tower_coins", 0)),
		"highest_floor": 0
	}
	if active_run.is_empty():
		if roster.is_empty():
			return summary
		var class_ids: Array = roster.keys()
		class_ids.sort()
		var first_class := String(class_ids[0]) if not class_ids.is_empty() else ""
		var class_data: Dictionary = DataCatalog.CLASSES.get(first_class, {})
		summary["class_id"] = first_class
		summary["class_name"] = String(class_data.get("name", first_class))
		summary["highest_floor"] = _highest_floor(roster)
		summary["headline"] = "营地：%s" % summary["class_name"]
		summary["detail"] = "最高第 %d 层，塔币 %d" % [int(summary["highest_floor"]), int(summary["tower_coins"])]
		return summary
	var class_id := String(active_run.get("class_id", ""))
	var class_data: Dictionary = DataCatalog.CLASSES.get(class_id, {})
	summary["class_id"] = class_id
	summary["class_name"] = String(class_data.get("name", class_id))
	summary["headline"] = "进行中：%s" % summary["class_name"]
	summary["detail"] = "第 %d 层 第 %d 场" % [int(active_run.get("floor_index", 1)), int(active_run.get("battle_index", 1))]
	summary["highest_floor"] = maxf(float(_highest_floor(roster)), float(int(active_run.get("floor_index", 1))))
	return summary


func _highest_floor(roster: Dictionary) -> int:
	var highest := 0
	for class_player in roster.values():
		if typeof(class_player) != TYPE_DICTIONARY:
			continue
		highest = maxi(highest, int((class_player as Dictionary).get("highest_floor", 0)))
	return highest


func _slot_profile(slots: Dictionary, slot_index: int) -> Dictionary:
	var slot_value: Variant = slots.get(str(_clamp_slot(slot_index)), {})
	if typeof(slot_value) == TYPE_DICTIONARY:
		return (slot_value as Dictionary)
	return {}


func _clamp_slot(slot_index: int) -> int:
	return mini(SLOT_COUNT, maxi(1, slot_index))


func _dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	return {}
