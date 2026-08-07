extends "res://scripts/tests/test_base.gd"

const TriggerEvents = preload("res://scripts/core/trigger_events.gd")
const BattleActionQueue = preload("res://scripts/core/battle/trigger/battle_action_queue.gd")
const BattleActionContext = preload("res://scripts/core/battle/battle_action_context.gd")


func run() -> void:
	test_extra_damage_goes_through_unified_damage_path()
	test_extra_damage_respects_target_armor()
	test_reflect_damages_attacker_through_unified_path()
	test_counter_all_only_fires_at_threshold()
	test_nested_action_queue_tracks_parent_chain()
	test_nested_action_queue_rejects_overflow()


func _session() -> RefCounted:
	var session := PlaySession.new()
	session.delete_save()
	session.start_new_game("warrior")
	return session


func _prepare_enemies(session: RefCounted, hp: int) -> void:
	for enemy in session.enemies:
		enemy["hp"] = hp
		enemy["max_hp"] = hp
		enemy["armor"] = 0
		enemy["block"] = 0
		enemy["dodge_layers"] = 0


func _has_hit_log(session: RefCounted) -> bool:
	return session.battle_log.any(func(line): return String(line).contains("命中"))


func test_extra_damage_goes_through_unified_damage_path() -> void:
	var session := _session()
	_prepare_enemies(session, 500)
	var enemy: Dictionary = session.enemies[0]
	session.status_service.add_status(session.player, {
		"id": "extra_damage_test",
		"triggers": [{
			"event": TriggerEvents.ON_HIT_DEALT,
			"actions": [{"type": TriggerEvents.ACTION_EXTRA_DAMAGE, "value": 10}]
		}]
	})
	session.status_service.fire_trigger(session.player, TriggerEvents.ON_HIT_DEALT, {
		"battle_log": session.battle_log,
		"session": session,
		"source": session.player,
		"damage": 5,
		"target": enemy
	})
	assert_equal(int(enemy["hp"]), 490, "extra damage should hit the target enemy once through the unified path")
	assert_true(_has_hit_log(session), "extra damage should produce a unified hit log entry")
	session.delete_save()


func test_extra_damage_respects_target_armor() -> void:
	var session := _session()
	_prepare_enemies(session, 500)
	var enemy: Dictionary = session.enemies[0]
	enemy["armor"] = 10
	session.status_service.add_status(session.player, {
		"id": "extra_damage_armor_test",
		"triggers": [{
			"event": TriggerEvents.ON_HIT_DEALT,
			"actions": [{"type": TriggerEvents.ACTION_EXTRA_DAMAGE, "value": 10}]
		}]
	})
	session.status_service.fire_trigger(session.player, TriggerEvents.ON_HIT_DEALT, {
		"battle_log": session.battle_log,
		"session": session,
		"source": session.player,
		"damage": 5,
		"target": enemy
	})
	# 10 点物理伤害经过 10 点护甲后实际造成 8 点（ARMOR_BASE=30）
	assert_equal(int(enemy["hp"]), 492, "extra damage should be reduced by target armor")
	session.delete_save()


func test_reflect_damages_attacker_through_unified_path() -> void:
	var session := _session()
	_prepare_enemies(session, 100)
	var enemy: Dictionary = session.enemies[0]
	session.status_service.add_status(session.player, {
		"id": "reflect_test",
		"triggers": [{
			"event": TriggerEvents.ON_HIT_RECEIVED,
			"actions": [{"type": TriggerEvents.ACTION_REFLECT, "value": 8}]
		}]
	})
	session.status_service.fire_trigger(session.player, TriggerEvents.ON_HIT_RECEIVED, {
		"battle_log": session.battle_log,
		"session": session,
		"source": enemy,
		"target": session.player
	})
	assert_equal(int(enemy["hp"]), 92, "reflect should damage the attacker through the unified path")
	assert_true(_has_hit_log(session), "reflect should produce a unified hit log entry")
	session.delete_save()


func test_counter_all_only_fires_at_threshold() -> void:
	var session := _session()
	_prepare_enemies(session, 100)
	session.status_service.add_status(session.player, {
		"id": "counter_all_test",
		"triggers": [{
			"event": TriggerEvents.ON_DODGE,
			"actions": [{"type": TriggerEvents.ACTION_COUNTER_ALL, "value": 6, "threshold": 2}]
		}]
	})
	session.dodge_streak = 1
	session.status_service.fire_trigger(session.player, TriggerEvents.ON_DODGE, {
		"battle_log": session.battle_log,
		"session": session,
		"source": session.enemies[0],
		"target": session.player
	})
	for enemy in session.enemies:
		assert_equal(int(enemy["hp"]), 100, "counter_all should not fire below the dodge threshold")
	assert_equal(session.dodge_streak, 1, "dodge streak should be preserved below the threshold")

	session.dodge_streak = 2
	session.status_service.fire_trigger(session.player, TriggerEvents.ON_DODGE, {
		"battle_log": session.battle_log,
		"session": session,
		"source": session.enemies[0],
		"target": session.player
	})
	for enemy in session.enemies:
		assert_equal(int(enemy["hp"]), 94, "counter_all should damage every living enemy at threshold")
	assert_equal(session.dodge_streak, 0, "counter_all should reset the dodge streak")
	session.delete_save()


func test_nested_action_queue_tracks_parent_chain() -> void:
	var queue := BattleActionQueue.new()
	var root := BattleActionContext.new({}, {})
	assert_true(queue.enqueue_nested_action(root), "root nested action should enqueue")
	var chain := String(root.get("chain_id"))
	assert_equal(queue.chain_depth(chain), 1, "root chain should start at depth 1")
	var child := BattleActionContext.new({}, {}, "parent-1", chain)
	assert_true(queue.enqueue_nested_action(child, chain), "child action should enqueue")
	assert_equal(queue.chain_depth(chain), 2, "child should inherit and deepen the parent chain")
	assert_true(not queue.is_empty(), "queue should hold pending actions")
	var first := queue.dequeue_nested_action()
	assert_equal(String(first.get("context_id")), String(root.get("context_id")), "queue should dequeue in FIFO order")
	assert_equal(queue.chain_depth(chain), 2, "chain depth should be kept after dequeue")


func test_nested_action_queue_rejects_overflow() -> void:
	var queue := BattleActionQueue.new()
	var root := BattleActionContext.new({}, {})
	assert_true(queue.enqueue_nested_action(root), "root nested action should enqueue")
	var chain := String(root.get("chain_id"))
	var accepted := 1
	while accepted < BattleActionQueue.MAX_CHAIN_DEPTH:
		var child := BattleActionContext.new({}, {}, "parent-%d" % accepted, chain)
		if not queue.enqueue_nested_action(child, chain):
			break
		accepted += 1
	assert_equal(accepted, BattleActionQueue.MAX_CHAIN_DEPTH, "queue should accept exactly MAX_CHAIN_DEPTH actions per chain")
	var overflow := BattleActionContext.new({}, {}, "overflow", chain)
	assert_true(not queue.enqueue_nested_action(overflow, chain), "queue should reject actions beyond MAX_CHAIN_DEPTH")
