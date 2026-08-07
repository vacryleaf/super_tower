extends "res://scripts/tests/test_base.gd"

const RunContext = preload("res://scripts/core/run_context.gd")
const RunStateSnapshot = preload("res://scripts/core/run_state_snapshot.gd")
const SaveProfile = preload("res://scripts/core/save_profile.gd")


func run() -> void:
	test_run_context_round_trip_independent_of_session()
	test_run_snapshot_splits_run_and_battle_fields()
	test_legacy_active_run_migration()
	test_missing_content_uses_defaults()
	test_interrupted_data_recovers_partial_state()
	test_save_profile_reads_writes_active_run_independently()
	test_session_active_run_restored_by_run_context()


func test_run_context_round_trip_independent_of_session() -> void:
	var context := RunContext.new()
	context.class_id = "warrior"
	context.floor_index = 2
	context.battle_index = 3
	context.tower_bonus = 1
	context.floor_encounter_count = 2
	context.floor_group_id = "group_a"
	context.encountered_groups_by_floor = [["group_a"], ["group_a", "group_b"]]
	context.tutorial_active = false
	context.phase = "reward"
	context.message = "hello"
	context.player = {"class_id": "warrior", "hp": 10, "max_hp": 20}
	context.reward_options = [{"type": "equipment", "id": "iron_sword"}]
	context.pending_reward = {"type": "equipment", "id": "iron_sword"}
	context.reward_targets = [{"slot": 1}]
	var snapshot := RunStateSnapshot.new()
	snapshot.run_data = context.capture()
	var restored := RunContext.new()
	restored.apply_data(RunStateSnapshot.from_dict(snapshot.to_dict()).run_data)
	assert_equal(restored.class_id, "unified", "round trip class id")
	assert_equal(restored.floor_index, 2, "round trip floor")
	assert_equal(restored.battle_index, 3, "round trip battle")
	assert_equal(restored.tower_bonus, 1, "round trip tower bonus")
	assert_equal(restored.floor_encounter_count, 2, "round trip encounter count")
	assert_equal(String(restored.floor_group_id), "group_a", "round trip group id")
	assert_equal(restored.encountered_groups_by_floor.size(), 2, "round trip groups by floor")
	assert_true(not restored.tutorial_active, "round trip tutorial flag")
	assert_equal(String(restored.phase), "reward", "round trip phase")
	assert_equal(int(restored.player.get("hp", 0)), 10, "round trip player hp")
	assert_equal(restored.reward_options.size(), 1, "round trip reward options")
	assert_true(not restored.pending_reward.is_empty(), "round trip pending reward")
	assert_equal(restored.reward_targets.size(), 1, "round trip reward targets")


func test_run_snapshot_splits_run_and_battle_fields() -> void:
	var snapshot := RunStateSnapshot.new()
	snapshot.run_data = {"class_id": "unified", "phase": "battle"}
	snapshot.battle_data = {"enemies": [{"id": "slime"}], "energy": 3}
	var data := snapshot.to_dict()
	assert_equal(int(data.get("version", 0)), 4, "snapshot version")
	assert_equal(String(data.get("class_id", "")), "unified", "run field in flat dict")
	assert_equal(String(data.get("phase", "")), "battle", "run field in flat dict")
	assert_equal(int(data.get("energy", 0)), 3, "battle field in flat dict")
	var parsed := RunStateSnapshot.from_dict(data)
	assert_equal(String(parsed.run_data.get("class_id", "")), "unified", "parsed run data")
	assert_true(parsed.battle_data.has("enemies"), "parsed battle data")
	assert_true(not parsed.battle_data.has("class_id"), "battle data excludes run fields")
	assert_true(not parsed.run_data.has("energy"), "run data excludes battle fields")


func test_legacy_active_run_migration() -> void:
	var legacy_data := {
		"version": 2,
		"class_id": "warrior",
		"player": {"class_id": "warrior", "hp": 10},
		"floor_index": 1,
		"battle_index": 3,
		"floor_encounter_count": 3,
		"floor_group_id": "group_a",
		"phase": "battle"
	}
	var context := RunContext.new()
	context.apply_data(RunStateSnapshot.from_dict(legacy_data).run_data)
	assert_equal(context.class_id, "unified", "legacy class id migrates")
	assert_equal(String(context.player.get("class_id", "")), "unified", "legacy player class migrates")
	assert_equal(context.floor_encounter_count, 3, "legacy floor encounter count")
	assert_equal(context.encountered_groups_by_floor.size(), 1, "legacy groups by floor rows")
	assert_equal((context.encountered_groups_by_floor[0] as Array).size(), 3, "legacy groups filled")
	assert_equal(context.legacy_restored_count, 3, "legacy restored count")
	assert_true(context.tutorial_active, "legacy tutorial inferred on floor one")


func test_missing_content_uses_defaults() -> void:
	var context := RunContext.new()
	context.apply_data({})
	# 与旧实现一致：空数据经 normalize_class_id 回退到 unified。
	assert_equal(context.class_id, "unified", "missing class falls back to unified")
	assert_equal(context.floor_index, 1, "missing floor defaults one")
	assert_equal(context.battle_index, 1, "missing battle defaults one")
	assert_equal(context.tower_bonus, 0, "missing tower bonus defaults zero")
	assert_equal(context.floor_encounter_count, 0, "missing encounter count defaults zero")
	assert_equal(String(context.phase), "battle", "missing phase defaults battle")
	assert_equal(String(context.message), "继续游戏。", "missing message defaults continue text")
	assert_equal(String(context.player.get("class_id", "")), "unified", "missing player gets unified class")
	assert_true(context.encountered_groups_by_floor.is_empty(), "missing groups defaults empty")


func test_interrupted_data_recovers_partial_state() -> void:
	var data := {
		"version": 4,
		"player": {"class_id": "unified", "hp": 5},
		"phase": "reward"
	}
	var context := RunContext.new()
	context.apply_data(RunStateSnapshot.from_dict(data).run_data)
	assert_equal(int(context.player.get("hp", 0)), 5, "interrupted player recovered")
	assert_equal(context.class_id, "unified", "interrupted class from player")
	assert_equal(String(context.phase), "reward", "interrupted phase recovered")
	assert_equal(context.floor_index, 1, "interrupted floor default")
	assert_equal(context.battle_index, 1, "interrupted battle default")
	assert_equal(context.floor_encounter_count, 0, "interrupted encounter count default")


func test_save_profile_reads_writes_active_run_independently() -> void:
	var save_profile := SaveProfile.new()
	save_profile.delete_save()
	var context := RunContext.new()
	context.class_id = "unified"
	context.floor_index = 3
	context.battle_index = 5
	context.tutorial_active = false
	context.phase = "battle"
	context.player = {"class_id": "unified", "hp": 12, "max_hp": 20}
	assert_true(save_profile.write_active_run(1, context.capture()), "write active run independently")
	var restored := RunContext.new()
	restored.apply_data(save_profile.read_active_run(1, Callable()))
	assert_equal(restored.class_id, "unified", "independent class id")
	assert_equal(restored.floor_index, 3, "independent floor")
	assert_equal(restored.battle_index, 5, "independent battle")
	assert_equal(int(restored.player.get("hp", 0)), 12, "independent player hp")
	save_profile.delete_save()


func test_session_active_run_restored_by_run_context() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	assert_true(session.save_game(), "session save should succeed")
	var save_profile := SaveProfile.new()
	var active_run := save_profile.read_active_run(1, Callable())
	assert_true(not active_run.is_empty(), "active run exists after save")
	assert_equal(int(active_run.get("version", 0)), 4, "active run version preserved")
	assert_true(active_run.has("enemies"), "battle data stays flat in active run")
	assert_true(active_run.has("reward_options"), "run data stays flat in active run")
	var context := RunContext.new()
	context.apply_data(RunStateSnapshot.from_dict(active_run).run_data)
	assert_equal(context.class_id, "unified", "session run context class id")
	assert_equal(context.floor_index, 1, "session run context floor")
	assert_true(context.tutorial_active, "session run context tutorial active")
	assert_true(not context.player.is_empty(), "session run context player restored")
	assert_equal(context.encountered_groups_by_floor.size(), 0, "session run context groups empty on tutorial start")
	session.delete_save()
