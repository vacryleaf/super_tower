extends RefCounted
class_name RunStateSnapshot

## Run/Battle 状态快照的纯数据载体：负责 run_data/battle_data 的持有，
## 以及磁盘格式（扁平字典 + version）的合并与拆分。迁移逻辑不在本文件。

# 与磁盘 active_run 的 version 保持一致，禁止改格式时递增。
const SNAPSHOT_VERSION := 4

# Run 层字段：高塔/教程/奖励/玩家成长状态，由 RunContext 负责迁移与默认值。
const RUN_FIELDS: Array = [
	"class_id", "floor_index", "battle_index", "tower_bonus",
	"floor_encounter_count", "floor_group_id", "encountered_groups_by_floor",
	"tutorial_active", "phase", "message", "player",
	"reward_options", "pending_reward", "reward_targets"
]

# Battle 层字段：当前战斗状态，由 RunStateSerializer 负责迁移与默认值。
const BATTLE_FIELDS: Array = [
	"current_encounter", "enemies", "allies", "energy", "has_acted",
	"skill_cooldowns", "player_block", "dodge_layers", "round_index",
	"ai_turn_stage", "pending_state_card", "state_draw_cursor",
	"battle_attack_multiplier", "enemy_attack_multiplier",
	"counter_stance_charges", "counter_attack_multiplier", "dodge_streak",
	"counters", "charge_used", "charge_ready", "charge_uses_left",
	"pending_charge_effects", "deferred_damage", "duel_target_index",
	"perfect_deflect"
]

var run_data: Dictionary = {}
var battle_data: Dictionary = {}


func to_dict() -> Dictionary:
	var result: Dictionary = {}
	for field in RUN_FIELDS:
		if run_data.has(field):
			result[field] = _deep_copy(run_data[field])
	for field in BATTLE_FIELDS:
		if battle_data.has(field):
			result[field] = _deep_copy(battle_data[field])
	result["version"] = SNAPSHOT_VERSION
	return result


static func from_dict(data: Dictionary) -> RefCounted:
	var snapshot: Variant = load("res://scripts/core/run_state_snapshot.gd").new()
	if int(data.get("version", 0)) < 1:
		return snapshot
	for field in RUN_FIELDS:
		if data.has(field):
			snapshot.run_data[field] = _deep_copy(data[field])
	for field in BATTLE_FIELDS:
		if data.has(field):
			snapshot.battle_data[field] = _deep_copy(data[field])
	return snapshot


static func _deep_copy(value: Variant) -> Variant:
	match typeof(value):
		TYPE_DICTIONARY:
			return (value as Dictionary).duplicate(true)
		TYPE_ARRAY:
			var copy: Array = []
			for item in value:
				copy.append(_deep_copy(item))
			return copy
		_:
			return value
