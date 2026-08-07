extends RefCounted
class_name RunContext

## Run 层状态容器：持有高塔/教程/奖励/玩家成长状态，可独立于 PlaySession
## 生成快照（capture）与从快照恢复（apply_data，含旧存档迁移）。

const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const RewardService = preload("res://scripts/core/reward_service.gd")

var class_id := ""
var floor_index := 1
var battle_index := 1
var tower_bonus := 0
var floor_encounter_count := 0
var floor_group_id := ""
var encountered_groups_by_floor: Array = []
var tutorial_active := false
var phase := "battle"
var message := ""
var player: Dictionary = {}
var reward_options: Array[Dictionary] = []
var pending_reward: Dictionary = {}
var reward_targets: Array[Dictionary] = []

# 旧存档（无 encountered_groups_by_floor）迁移时填充的组数；0 表示未迁移。
var legacy_restored_count := 0


func capture() -> Dictionary:
	return {
		"class_id": class_id,
		"floor_index": floor_index,
		"battle_index": battle_index,
		"tower_bonus": tower_bonus,
		"floor_encounter_count": floor_encounter_count,
		"floor_group_id": floor_group_id,
		"encountered_groups_by_floor": _deep_copy_nested_array(encountered_groups_by_floor),
		"tutorial_active": tutorial_active,
		"phase": phase,
		"message": message,
		"player": player.duplicate(true),
		"reward_options": _copy_rewards(reward_options),
		"pending_reward": pending_reward.duplicate(true),
		"reward_targets": _copy_rewards(reward_targets)
	}


func capture_from_session(session: RefCounted) -> void:
	class_id = String(session.class_id)
	floor_index = int(session.floor_index)
	battle_index = int(session.battle_index)
	tower_bonus = int(session.tower_bonus)
	floor_encounter_count = int(session.floor_encounter_count)
	floor_group_id = String(session.floor_group_id)
	encountered_groups_by_floor = _deep_copy_nested_array(session.encountered_groups_by_floor)
	tutorial_active = bool(session.tutorial_active)
	phase = String(session.phase)
	message = String(session.message)
	player = (session.player as Dictionary).duplicate(true)
	reward_options = _copy_rewards(session.reward_options)
	pending_reward = (session.pending_reward as Dictionary).duplicate(true)
	reward_targets = _copy_rewards(session.reward_targets)


func apply_data(data: Dictionary) -> void:
	legacy_restored_count = 0
	var saved_player := _dictionary(data.get("player", {}))
	class_id = DataCatalog.normalize_class_id(String(data.get("class_id", saved_player.get("class_id", ""))))
	player = saved_player
	player["class_id"] = class_id
	floor_index = int(data.get("floor_index", 1))
	battle_index = int(data.get("battle_index", 1))
	tower_bonus = int(data.get("tower_bonus", 0))
	floor_encounter_count = int(data.get("floor_encounter_count", 0))
	floor_group_id = String(data.get("floor_group_id", ""))
	encountered_groups_by_floor = _array_array(data.get("encountered_groups_by_floor", []))
	tutorial_active = bool(data.get("tutorial_active", floor_index == 1 and not bool(saved_player.get("tutorial_completed", false))))
	phase = String(data.get("phase", "battle"))
	message = String(data.get("message", "继续游戏。"))
	_restore_legacy_group_history(floor_encounter_count)
	# 与旧实现一致：楼层组数始终以 encountered_groups_by_floor 为准。
	floor_encounter_count = current_floor_group_count()
	reward_options = RewardService.normalize_rewards(_dictionary_array(data.get("reward_options", [])))
	var pending := _dictionary(data.get("pending_reward", {}))
	pending_reward = {} if pending.is_empty() else RewardService.normalize_reward(pending)
	reward_targets = _dictionary_array(data.get("reward_targets", []))


func current_floor_group_count() -> int:
	if floor_index <= 0 or encountered_groups_by_floor.size() < floor_index:
		return 0
	return (encountered_groups_by_floor[floor_index - 1] as Array).size()


func _restore_legacy_group_history(legacy_count: int) -> void:
	if legacy_count <= 0 or floor_group_id == "" or floor_index <= 0:
		return
	_ensure_encountered_groups_by_floor()
	var current_floor_groups: Array = encountered_groups_by_floor[floor_index - 1]
	if not current_floor_groups.is_empty():
		return
	var remaining_count := legacy_count
	while remaining_count > 0:
		current_floor_groups.append(floor_group_id)
		remaining_count -= 1
	encountered_groups_by_floor[floor_index - 1] = current_floor_groups
	floor_encounter_count = current_floor_groups.size()
	legacy_restored_count = current_floor_groups.size()


func _ensure_encountered_groups_by_floor() -> void:
	while encountered_groups_by_floor.size() < floor_index:
		encountered_groups_by_floor.append([])


func _copy_rewards(source: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(source) != TYPE_ARRAY:
		return result
	for item in source:
		if typeof(item) == TYPE_DICTIONARY:
			result.append((item as Dictionary).duplicate(true))
	return result


func _deep_copy_nested_array(source: Variant) -> Array:
	var result: Array = []
	if typeof(source) != TYPE_ARRAY:
		return result
	for item in source:
		if typeof(item) == TYPE_ARRAY:
			result.append((item as Array).duplicate(true))
		else:
			result.append(item)
	return result


func _dictionary(value: Variant) -> Dictionary:
	if typeof(value) == TYPE_DICTIONARY:
		return (value as Dictionary).duplicate(true)
	return {}


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for item in value:
		if typeof(item) == TYPE_DICTIONARY:
			result.append((item as Dictionary).duplicate(true))
	return result


func _array_array(value: Variant) -> Array:
	var result: Array = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for row_value in value:
		if typeof(row_value) != TYPE_ARRAY:
			result.append([])
			continue
		var row: Array = []
		for group_id in row_value:
			var normalized_id := String(group_id)
			if normalized_id != "":
				row.append(normalized_id)
		result.append(row)
	return result
