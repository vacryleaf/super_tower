extends "res://scripts/tests/test_base.gd"

const TriggerEvents = preload("res://scripts/core/trigger_events.gd")
const TestHelpers = preload("res://scripts/tests/test_helpers.gd")


func run() -> void:
	test_tutorial_battle_starts_round()
	test_formal_battle_starts_round()
	test_skill_cooldown_ticks()
	test_status_expiry_and_tick()
	test_first_strike_detection()
	test_action_order_before_player()
	test_dead_units_skipped()
	test_end_round_fires_turn_end_and_completes()


func _session() -> RefCounted:
	var session := PlaySession.new()
	session.delete_save()
	session.start_new_game("warrior")
	return session


# 切到正式战斗：教程完成标记 + 非教程模式后重新开始当前战斗。
func _formal_session() -> RefCounted:
	var session := _session()
	session.player["tutorial_completed"] = true
	session.tutorial_active = false
	session.floor_index = 2
	session.battle_index = 1
	session.floor_group_id = ""
	session._start_current_battle()
	return session


func test_tutorial_battle_starts_round() -> void:
	var session := _session()
	assert_equal(int(session.round_index), 1, "tutorial first round should be 1")
	assert_true(not bool(session.has_acted), "tutorial round should reset has_acted")
	assert_equal(int(session.player_block), 0, "tutorial round should reset player block")
	assert_true(String(session.pending_state_card) != "", "tutorial round should draw a state buff card")
	assert_equal(String(session.ai_turn_stage), "after_player_pending", "tutorial round should be in player turn stage")
	session.delete_save()


func test_formal_battle_starts_round() -> void:
	var session := _formal_session()
	assert_equal(int(session.round_index), 1, "formal battle first round should be 1")
	assert_true(not bool(session.has_acted), "formal battle round should reset has_acted")
	assert_equal(int(session.player_block), 0, "formal battle round should reset player block")
	assert_true(String(session.pending_state_card) != "", "formal battle round should draw a state buff card")
	assert_equal(String(session.ai_turn_stage), "after_player_pending", "formal battle round should be in player turn stage")
	session.delete_save()


func test_skill_cooldown_ticks() -> void:
	var session := _session()
	session.skill_cooldowns = {"skill_x": 1, "skill_y": 3}
	session.round_lifecycle.begin_player_turn(session)
	assert_true(not session.skill_cooldowns.has("skill_x"), "expired cooldown should be removed")
	assert_equal(int(session.skill_cooldowns["skill_y"]), 2, "active cooldown should tick down by one")
	session.delete_save()


func test_status_expiry_and_tick() -> void:
	var session := _session()
	var enemy: Dictionary = session.enemies[0]
	session.status_service.add_status(enemy, {
		"id": "temp_buff", "name": "临时增益", "kind": "buff",
		"stack": "replace", "duration": 1
	})
	session.status_service.add_status(enemy, {
		"id": "long_buff", "name": "长时增益", "kind": "buff",
		"stack": "replace", "duration": 3
	})
	session.player["hp"] = int(session.player["max_hp"]) - 10
	session.status_service.add_status(session.player, {
		"id": "regen_tick", "name": "再生", "kind": "buff", "stack": "replace",
		"duration": 3, "tick_effects": [{"stat": "hp", "type": "flat", "value": 4}]
	})
	var hp_before := int(session.player["hp"])
	session.round_lifecycle.begin_player_turn(session)
	var remaining: Array = enemy["statuses"]
	assert_equal(remaining.size(), 1, "expired status should be removed after one round")
	assert_equal(String(remaining[0]["id"]), "long_buff", "long status should remain")
	assert_equal(int(remaining[0]["duration"]), 2, "long status duration should tick down")
	assert_true(int(session.player["hp"]) > hp_before, "player tick effect should heal hp")
	session.delete_save()


func test_first_strike_detection() -> void:
	var session := _session()
	var first_strike_enemy := TestHelpers.test_enemy("先手敌人", 100, 10, ["first_strike"])
	var normal_enemy := TestHelpers.test_enemy("普通敌人", 100, 10, [])
	assert_true(session.round_lifecycle.has_first_strike([first_strike_enemy] as Array[Dictionary]), "first strike trait should be detected")
	assert_true(not session.round_lifecycle.has_first_strike([normal_enemy] as Array[Dictionary]), "normal enemy should not have first strike")
	session.delete_save()


func test_action_order_before_player() -> void:
	var session := _session()
	session.player["hp"] = 100
	session.player["max_hp"] = 100
	session.player["agility"] = 5
	var fast_enemy := TestHelpers.test_enemy("高速敌人", 100, 1, [])
	fast_enemy["agility"] = 20
	session.enemies = [fast_enemy] as Array[Dictionary]
	session.round_index = 0
	session.battle_log.clear()
	var order: Array[Dictionary] = session.turn_order.compute_order(session)
	assert_equal(String(order[0]["type"]), "enemy", "faster enemy should lead the action order")
	assert_equal(String(order[1]["type"]), "player", "player should follow the faster enemy")
	assert_equal(String(order[0]["unit"]["name"]), "高速敌人", "leading enemy should be the fast one")
	session.round_lifecycle.begin_player_turn(session)
	assert_true(int(session.player["hp"]) < 100, "faster enemy should attack before the player action")
	session.delete_save()


func test_dead_units_skipped() -> void:
	var session := _session()
	var dead_enemy: Dictionary = session.enemies[0]
	dead_enemy["hp"] = 0
	session.status_service.add_status(dead_enemy, {
		"id": "dead_status", "name": "尸体状态", "kind": "debuff",
		"stack": "replace", "duration": 1
	})
	session.round_lifecycle.begin_player_turn(session)
	var remaining: Array = dead_enemy["statuses"]
	assert_equal(remaining.size(), 1, "dead enemy status should not be ticked")
	assert_equal(int(remaining[0]["duration"]), 1, "dead enemy status duration should stay unchanged")
	var order: Array[Dictionary] = session.turn_order.compute_order(session)
	for entry in order:
		assert_true(int(entry.get("unit", {}).get("hp", 0)) > 0, "dead enemy should be excluded from action order")
	session.delete_save()


func test_end_round_fires_turn_end_and_completes() -> void:
	var session := _session()
	var enemy: Dictionary = session.enemies[0]
	session.status_service.add_status(enemy, {
		"id": "turn_end_block", "name": "回合结束格挡", "kind": "buff",
		"stack": "replace", "duration": -1,
		"triggers": [{"event": TriggerEvents.ON_TURN_END, "actions": [{"type": TriggerEvents.ACTION_GAIN_BLOCK, "value": 5}]}]
	})
	var block_before := int(enemy.get("block", 0))
	session.round_lifecycle.end_round(session)
	assert_equal(int(enemy.get("block", 0)), block_before + 5, "turn end trigger should grant block to the enemy")
	assert_equal(String(session.ai_turn_stage), "complete", "round end should mark ai turn stage complete")
	session.delete_save()
