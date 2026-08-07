extends RefCounted
class_name BattleResult

const OUTCOME_VICTORY := "victory"
const OUTCOME_DEFEAT := "defeat"

var outcome := ""
var reason := ""
var round_index := 0
var floor_index := 0
var battle_index := 0
var is_tutorial := false
var player_hp := 0
var player_max_hp := 0
var enemies_alive := 0
var data: Dictionary = {}


func _init(
	initial_outcome: String = "",
	initial_reason: String = "",
	initial_round: int = 0,
	initial_floor: int = 0,
	initial_battle: int = 0,
	initial_tutorial: bool = false,
	initial_player_hp: int = 0,
	initial_player_max_hp: int = 0,
	initial_enemies_alive: int = 0,
	initial_data: Dictionary = {}
) -> void:
	outcome = initial_outcome
	reason = initial_reason
	round_index = initial_round
	floor_index = initial_floor
	battle_index = initial_battle
	is_tutorial = initial_tutorial
	player_hp = initial_player_hp
	player_max_hp = initial_player_max_hp
	enemies_alive = initial_enemies_alive
	data = initial_data.duplicate(true)


func is_victory() -> bool:
	return outcome == OUTCOME_VICTORY


func is_defeat() -> bool:
	return outcome == OUTCOME_DEFEAT


# 输出不持有战斗状态引用的深拷贝快照，供日志、测试和 Run 层消费。
func to_dictionary() -> Dictionary:
	var snapshot: Dictionary = {
		"outcome": outcome,
		"reason": reason,
		"round_index": round_index,
		"floor_index": floor_index,
		"battle_index": battle_index,
		"is_tutorial": is_tutorial,
		"player_hp": player_hp,
		"player_max_hp": player_max_hp,
		"enemies_alive": enemies_alive,
	}
	snapshot["data"] = data.duplicate(true)
	return snapshot
