extends "res://scripts/tests/test_base.gd"

const PlaySessionScript = preload("res://scripts/core/play_session.gd")
const UiIntentScript = preload("res://scripts/ui/ui_intent.gd")

# UI 意图名 -> Run/Battle 层公开方法名。
const INTENT_TO_SESSION_METHOD := {
	"attack": "player_attack",
	"defend": "player_defend",
	"dodge": "player_dodge",
	"use_blood_potion": "use_blood_potion_in_battle",
	"end_turn": "end_turn",
	"use_skill": "use_skill",
	"use_charge": "use_charge",
	"use_consumable": "use_consumable",
	"choose_reward": "choose_reward",
	"choose_reward_target": "choose_reward_target",
}

# UI 边界禁止的伤害结算私有实现模式。
const DAMAGE_PATTERNS := [
	"deal_damage(",
	"_execute_action_skill(",
	"_execute_enemy_action_skill(",
	"_execute_action_damage(",
	"_execute_enemy_action_damage(",
	"_action_attack_value(",
	"_enemy_action_attack_value(",
]

# UI 边界禁止的敌人 AI 决策私有实现模式。
const AI_PATTERNS := [
	"_enemy_attack(",
	"_enemy_action(",
	"_choose_enemy_action(",
	"ai_turn_stage =",
]

# UI 边界禁止的 Mod 文件直读模式（Mod 状态必须走内容层端口）。
const MOD_PATTERNS := [
	"mods/",
	"ModLoader",
	"mod_loader",
	"load_mods(",
]


func run() -> void:
	test_ui_sources_do_not_calculate_damage()
	test_ui_sources_do_not_choose_enemy_actions()
	test_ui_sources_do_not_read_mod_files()
	test_main_routes_battle_intents_through_intent_port()
	test_intent_port_has_session_backing()
	test_intent_forwards_calls_to_session_public_api()
	test_intent_unbound_is_noop()


func _ui_source_paths() -> Array[String]:
	var paths: Array[String] = ["res://scripts/main.gd"]
	var dir := DirAccess.open("res://scripts/ui")
	if dir == null:
		return paths
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".gd"):
			paths.append("res://scripts/ui/%s" % file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return paths


func _assert_pattern_absent(patterns: Array, label: String) -> void:
	for path in _ui_source_paths():
		var source := FileAccess.get_file_as_string(path)
		assert_true(source != "", "ui source readable: %s" % path)
		for pattern in patterns:
			assert_true(not source.contains(pattern), "%s: %s must not contain %s" % [label, path, pattern])


func test_ui_sources_do_not_calculate_damage() -> void:
	_assert_pattern_absent(DAMAGE_PATTERNS, "ui must not calculate damage")


func test_ui_sources_do_not_choose_enemy_actions() -> void:
	_assert_pattern_absent(AI_PATTERNS, "ui must not choose enemy actions")


func test_ui_sources_do_not_read_mod_files() -> void:
	_assert_pattern_absent(MOD_PATTERNS, "ui must not read mod files directly")


func test_main_routes_battle_intents_through_intent_port() -> void:
	var main_source := FileAccess.get_file_as_string("res://scripts/main.gd")
	assert_true(main_source != "", "main source readable")
	for direct in [
		'Callable(session, "player_attack")',
		'Callable(session, "player_defend")',
		'Callable(session, "player_dodge")',
		'Callable(session, "use_blood_potion_in_battle")',
		'Callable(session, "end_turn")',
		'Callable(session, "use_skill")',
		'Callable(session, "use_charge")',
		'Callable(session, "use_consumable")',
		"session.choose_reward(",
		"session.choose_reward_target(",
	]:
		assert_true(not main_source.contains(direct), "main must not call %s directly" % direct)
	assert_true(main_source.contains("ui_intent."), "main routes intents through ui_intent")


func test_intent_port_has_session_backing() -> void:
	var intent := UiIntentScript.new()
	var session := PlaySessionScript.new()
	for intent_name in INTENT_TO_SESSION_METHOD:
		var session_method := String(INTENT_TO_SESSION_METHOD[intent_name])
		assert_true(intent.has_method(intent_name), "intent port exposes %s" % intent_name)
		assert_true(session.has_method(session_method), "session backs intent %s with %s" % [intent_name, session_method])
	var intent_methods := intent.get_method_list()
	var session_methods := session.get_method_list()
	for intent_name in INTENT_TO_SESSION_METHOD:
		var session_method := String(INTENT_TO_SESSION_METHOD[intent_name])
		var intent_args := _argument_count(intent_methods, intent_name)
		var session_args := _argument_count(session_methods, session_method)
		assert_true(intent_args >= 0 and session_args >= 0, "%s/%s methods found" % [intent_name, session_method])
		assert_equal(intent_args, session_args, "intent %s argument count matches session %s" % [intent_name, session_method])


func test_intent_forwards_calls_to_session_public_api() -> void:
	var intent := UiIntentScript.new()
	var fake := FakeSession.new()
	intent.bind(fake)
	intent.attack(2)
	intent.defend()
	intent.dodge()
	intent.use_blood_potion()
	intent.end_turn()
	intent.use_skill(0, 1)
	intent.use_charge("charge_a")
	intent.use_consumable("minor_heal")
	intent.choose_reward(3)
	intent.choose_reward_target(0)
	assert_equal(fake.calls.size(), 10, "intent forwards every supported intent")
	assert_equal(fake.calls[0]["name"], "player_attack", "attack forwards to player_attack")
	assert_equal(fake.calls[0]["args"][0], 2, "attack forwards target index")
	assert_equal(fake.calls[5]["name"], "use_skill", "use_skill forwards")
	assert_equal(fake.calls[5]["args"][0], 0, "use_skill forwards slot")
	assert_equal(fake.calls[5]["args"][1], 1, "use_skill forwards target")
	assert_equal(fake.calls[6]["args"][0], "charge_a", "use_charge forwards id")
	assert_equal(fake.calls[7]["args"][0], "minor_heal", "use_consumable forwards id")
	assert_equal(fake.calls[8]["args"][0], 3, "choose_reward forwards index")


func test_intent_unbound_is_noop() -> void:
	var intent := UiIntentScript.new()
	assert_true(not intent.is_bound(), "intent starts unbound")
	intent.attack(0)
	intent.defend()
	intent.use_skill(0, 0)
	intent.choose_reward(0)


func _argument_count(methods: Array, method_name: String) -> int:
	for method in methods:
		if String(method["name"]) == method_name:
			return int(method["args"].size())
	return -1


class FakeSession:
	extends RefCounted

	var calls: Array[Dictionary] = []

	func _record(name: String, args: Array) -> void:
		calls.append({"name": name, "args": args})

	func player_attack(target_index: int) -> void:
		_record("player_attack", [target_index])

	func player_defend() -> void:
		_record("player_defend", [])

	func player_dodge() -> void:
		_record("player_dodge", [])

	func use_blood_potion_in_battle() -> void:
		_record("use_blood_potion_in_battle", [])

	func end_turn() -> void:
		_record("end_turn", [])

	func use_skill(slot_index: int, target_index: int) -> void:
		_record("use_skill", [slot_index, target_index])

	func use_charge(charge_id: String) -> void:
		_record("use_charge", [charge_id])

	func use_consumable(consumable_id: String) -> void:
		_record("use_consumable", [consumable_id])

	func choose_reward(index: int) -> void:
		_record("choose_reward", [index])

	func choose_reward_target(index: int) -> void:
		_record("choose_reward_target", [index])
