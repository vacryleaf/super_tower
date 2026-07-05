extends SceneTree

const PlaySession = preload("res://scripts/core/play_session.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")

var failures: Array[String] = []


func _init() -> void:
	run_all()
	if failures.is_empty():
		print("PLAYABLE MANUAL TESTS PASSED")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func run_all() -> void:
	run_manual_campaign("warrior")
	run_manual_campaign("archer")


func run_manual_campaign(class_id: String) -> void:
	var session := PlaySession.new()
	session.delete_save()
	session.start_new_game(class_id)
	var guard := 0
	while session.phase != "victory" and session.phase != "game_over" and guard < 2000:
		guard += 1
		if session.phase == "battle":
			_play_one_action(session)
		elif session.phase == "reward":
			session.choose_reward(_best_reward_index(session))
		elif session.phase == "reward_target":
			session.choose_reward_target(_best_target_index(session))
	assert_equal(session.phase, "game_over", "%s baseline manual campaign should eventually be stopped by the build gate" % class_id)
	assert_true(int(session.floor_index) >= 6, "%s should reach the post-floor-5 pressure zone" % class_id)
	assert_true(int(session.player["battles_completed"]) >= 50, "%s should clear the first five floors" % class_id)
	assert_true(bool(session.player["tutorial_completed"]), "%s tutorial completed" % class_id)
	assert_true(session.player["equipped_skills"].size() <= 4, "%s skill slots limited to 4" % class_id)
	assert_true(guard < 2000, "%s manual campaign guard" % class_id)


func _play_one_action(session: PlaySession) -> void:
	var target := _first_living_enemy(session)
	if target < 0:
		return
	var block_power := int(session.player.get("block_power", session.player.get("defense", 1)))
	if String(session.player["class_id"]) == "archer" and _incoming_damage(session) >= block_power and session.action_points >= 1 and session.dodge_layers <= 0:
		session.player_dodge()
		return
	if _incoming_damage(session) >= block_power and session.action_points >= 1 and session.player_block < block_power:
		session.player_defend()
		return
	if session.player["equipped_skills"].size() > 0:
		var skill_id: String = session.player["equipped_skills"][0]
		var skill_cost := int(DataCatalog.SKILLS[skill_id].get("cost", 2))
		if session.action_points >= skill_cost:
			session.use_skill(0, target)
			return
	if session.action_points >= 1:
		session.player_attack(target)
		return
	session.end_turn()


func _incoming_damage(session: PlaySession) -> int:
	var total := 0
	var attackers := 0
	for enemy in session.enemies:
		if int(enemy["hp"]) <= 0:
			continue
		if attackers >= 2:
			break
		total += int(enemy["attack"])
		attackers += 1
	return total


func _first_living_enemy(session: PlaySession) -> int:
	for i in range(session.enemies.size()):
		if int(session.enemies[i]["hp"]) > 0:
			return i
	return -1


func _best_reward_index(session: PlaySession) -> int:
	for i in range(session.reward_options.size()):
		if session.reward_options[i]["kind"] == "tutorial_unlock":
			return i
	for i in range(session.reward_options.size()):
		if session.reward_options[i]["kind"] == "skill":
			return i
	if float(session.player["hp"]) < float(session.player["max_hp"]) * 0.70:
		for i in range(session.reward_options.size()):
			if session.reward_options[i]["kind"] == "hp":
				return i
	var reward_cycle := int(session.player["battles_completed"]) % 3
	if reward_cycle == 1:
		for i in range(session.reward_options.size()):
			if session.reward_options[i]["kind"] == "defense":
				return i
	elif reward_cycle == 2:
		for i in range(session.reward_options.size()):
			if session.reward_options[i]["kind"] == "hp":
				return i
	for i in range(session.reward_options.size()):
		if session.reward_options[i]["kind"] == "attack":
			return i
	return 0


func _best_target_index(session: PlaySession) -> int:
	var reward_kind := String(session.pending_reward.get("kind", ""))
	if reward_kind == "attack":
		for i in range(session.reward_targets.size()):
			var target: Dictionary = session.reward_targets[i]
			if target.get("type", "") == "equipment":
				var item_id := String(target.get("id", ""))
				if DataCatalog.EQUIPMENT.has(item_id) and DataCatalog.EQUIPMENT[item_id]["slot"] == "weapon":
					return i
	if reward_kind == "defense":
		for slot in ["offhand", "body", "head"]:
			for i in range(session.reward_targets.size()):
				var target: Dictionary = session.reward_targets[i]
				if target.get("type", "") == "equipment":
					var item_id := String(target.get("id", ""))
					if DataCatalog.EQUIPMENT.has(item_id) and DataCatalog.EQUIPMENT[item_id]["slot"] == slot:
						return i
	for i in range(session.reward_targets.size()):
		if session.reward_targets[i].get("type", "") == "equipment":
			return i
	return 0


func assert_true(value: bool, message: String) -> void:
	if not value:
		failures.append(message)


func assert_equal(actual, expected, message: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])
