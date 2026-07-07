extends RefCounted
class_name BattleState

var player: Dictionary = {}
var class_id := ""
var floor_index := 1
var battle_index := 1
var phase := "menu"
var message := ""
var enemies: Array[Dictionary] = []
var current_encounter: Dictionary = {}
var action_points := 1
var max_action_points := 1
var player_block := 0
var dodge_layers := 0
var round_index := 0
var pending_state_card := ""
var state_draw_cursor := 0
var battle_attack_multiplier := 1.0
var enemy_attack_multiplier := 1.0
var focus_target_index := -1
var focus_combo_multiplier := 1.0
var counter_stance_charges := 0
var counter_attack_multiplier := 1.0
var dodge_streak := 0
var meticulous_stacks := 0
var seek_bloom_stacks := 0
var ranger_hit_count := 0
var attacked_this_turn := false
var reward_options: Array[Dictionary] = []
var pending_reward: Dictionary = {}
var reward_targets: Array[Dictionary] = []
var battle_log: Array[String] = []
var last_events: Array[Dictionary] = []
var charge_used: Dictionary = {}
var charge_ready: Dictionary = {}
var pending_charge_effects: Dictionary = {}


func reset() -> void:
	player = {}
	class_id = ""
	floor_index = 1
	battle_index = 1
	phase = "menu"
	message = "已返回塔下营地。"
	enemies.clear()
	current_encounter = {}
	action_points = 1
	max_action_points = 1
	player_block = 0
	dodge_layers = 0
	round_index = 0
	pending_state_card = ""
	state_draw_cursor = 0
	battle_attack_multiplier = 1.0
	enemy_attack_multiplier = 1.0
	focus_target_index = -1
	focus_combo_multiplier = 1.0
	counter_stance_charges = 0
	counter_attack_multiplier = 1.0
	dodge_streak = 0
	meticulous_stacks = 0
	seek_bloom_stacks = 0
	ranger_hit_count = 0
	attacked_this_turn = false
	reward_options.clear()
	pending_reward = {}
	reward_targets.clear()
	battle_log.clear()
	last_events.clear()
	charge_used = {}
	charge_ready = {}
	pending_charge_effects = {}