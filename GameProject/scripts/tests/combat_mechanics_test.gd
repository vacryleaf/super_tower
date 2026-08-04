extends "res://scripts/tests/test_base.gd"

const TestHelpers = preload("res://scripts/tests/test_helpers.gd")
const DataCatalog = preload("res://scripts/core/data_catalog.gd")
const CharacterService = preload("res://scripts/core/character_service.gd")
const Combatant = preload("res://scripts/core/combatant.gd")
const StatusService = preload("res://scripts/core/status_service.gd")
const CombatRules = preload("res://scripts/core/combat_rules.gd")
const TriggerEvents = preload("res://scripts/core/trigger_events.gd")
const UIHelpers = preload("res://scripts/ui/ui_helpers.gd")


func run() -> void:
	test_block_power_is_separate_from_armor()
	test_enemy_block_power_is_separate_from_armor()
	test_player_and_enemy_share_combatant_contract()
	test_thick_skin_always_grants_armor()
	test_loaded_enemy_traits_are_idempotent()
	test_rat_corruption_and_armor_reduction()
	test_swarm_triggers_one_assist_per_living_ally()
	test_hidden_targets_require_visible_fallback()
	test_curse_refreshes_instead_of_stacking()
	test_toxic_mist_hits_player_and_allies()
	test_arena_damage_and_heal_modifiers()
	test_new_units_wait_one_round()
	test_skill_multiplier_effects()
	test_counter_stance_and_multihit_dodge()
	test_block_expires_each_round()
	test_enemy_skill_execution()
	test_enemy_ai_skill_selection()
	test_enemy_enrage_duration_and_cooldown()
	test_enemy_taunt_skill()
	test_rank_skill_multiplier()
	test_basic_attack_agility_segments()
	test_agility_action_order()
	test_skeleton_passive_damage_rules()
	test_skeleton_taunt_requires_an_ally()
	test_documented_trigger_conditions()
	test_trigger_counters()
	test_skill_energy_cost_display_value()
	test_normal_consumables_can_be_used()
	test_weapon_critical_weight_and_trigger()
	test_data_driven_action_execution()
	test_damage_rounding_uses_ceiling()


func test_rat_corruption_and_armor_reduction() -> void:
	var status_service := StatusService.new()
	var player := {"hp": 100, "max_hp": 100, "defense": 1, "statuses": []}
	CombatRules.apply_corruption(player, 10, status_service)
	CombatRules.apply_corruption(player, 15, status_service)
	for _turn in range(3):
		CombatRules.resolve_corruption(player)
	assert_equal(int(player["hp"]), 91, "corruption should refresh and use the last hit attack value")
	CombatRules.apply_armor_reduction(player, 3, status_service, "测试减防")
	var combatant := Combatant.from_player(player, 0, 0, status_service)
	assert_equal(int(combatant["armor"]), -2, "armor reduction should allow negative defense")


func test_documented_trigger_conditions() -> void:
	var status_service := StatusService.new()
	var target := {"hp": 10, "max_hp": 100, "block": 0, "statuses": []}
	status_service.add_status(target, {
		"id": "documented_trigger",
		"triggers": [{
			"event": TriggerEvents.ON_HIT_RECEIVED,
			"conditions": [{"stat": "hp", "operator": "lt", "value": 20}],
			"actions": [{"type": TriggerEvents.ACTION_GAIN_BLOCK, "value": 4}]
		}]
	})
	status_service.fire_trigger(target, TriggerEvents.ON_HIT_RECEIVED, {})
	assert_equal(int(target["block"]), 4, "documented trigger condition should allow matching action")
	target["hp"] = 30
	target["block"] = 0
	status_service.fire_trigger(target, TriggerEvents.ON_HIT_RECEIVED, {})
	assert_equal(int(target["block"]), 0, "documented trigger condition should block non-matching action")


func test_trigger_counters() -> void:
	var session := PlaySession.new()
	session.delete_save()
	session.start_new_game("warrior")
	session.status_service.add_status(session.player, {
		"id": "counter_trigger_test",
		"triggers": [{
			"event": TriggerEvents.ON_HIT_RECEIVED,
			"actions": [{
				"type": TriggerEvents.ACTION_INCREMENT_COUNTER,
				"counter": "test_counter",
				"max": 10,
				"threshold": 2,
				"threshold_actions": [{"type": TriggerEvents.ACTION_GAIN_BLOCK, "value": 3}]
			}]
		}]
	})
	session.status_service.fire_trigger(session.player, TriggerEvents.ON_HIT_RECEIVED, {"session": session, "battle_log": []})
	assert_equal(session.get_counter("test_counter"), 1, "counter should increment on trigger")
	session.status_service.fire_trigger(session.player, TriggerEvents.ON_HIT_RECEIVED, {"session": session, "battle_log": []})
	assert_equal(session.get_counter("test_counter"), 0, "counter should reset by threshold consumption")
	assert_equal(int(session.player.get("block", 0)), 3, "counter threshold action should execute")
	session.set_counter("test_counter", -5)
	assert_equal(session.get_counter("test_counter"), 0, "counter should not become negative")
	session.delete_save()


func test_skill_energy_cost_display_value() -> void:
	assert_equal(UIHelpers.skill_energy_cost(DataCatalog.SKILLS["po_jun"]), 8, "skill pages should display energy_cost")
	assert_equal(UIHelpers.skill_energy_cost(DataCatalog.INNATE_SKILLS["innate_attack_1"]), 0, "innate skills without a cost should display zero")


func test_normal_consumables_can_be_used() -> void:
	var session := PlaySession.new()
	session.delete_save()
	session.start_new_game("warrior")
	var effects := {
		"minor_heal": "heal",
		"iron_skin": "armor",
		"swift_step": "dodge",
		"rage_draught": "attack",
		"focus_tea": "skill",
		"emergency_kit": "block"
	}
	for item_id in effects.keys():
		session.player["consumables"] = [String(item_id), "", ""]
		session.player["statuses"] = []
		session.player["hp"] = 40
		session.player_block = 0
		session.dodge_layers = 0
		session.energy = 0
		session.has_acted = false
		assert_true(session.available_consumables().any(func(item: Dictionary): return String(item.get("item_id", "")) == String(item_id)), "%s should appear in the battle item bar" % item_id)
		assert_true(session.use_consumable(0), "%s should be usable" % item_id)
		assert_equal(String(session.player["consumables"][0]), "", "%s should be consumed" % item_id)
		match String(effects[item_id]):
			"heal":
				assert_equal(int(session.player["hp"]), 58, "minor heal should restore its configured value")
			"armor":
				var armor := session.status_service.resolve_stat(session.player, float(session.player["defense"]), StatusService.STAT_ARMOR)
				assert_equal(int(armor), int(session.player["defense"]) + 2, "iron skin should add armor")
			"dodge":
				assert_equal(int(session.dodge_layers), 1, "swift step should add dodge layers")
			"attack":
				var attack := session.status_service.resolve_stat(session.player, float(session.player["attack"]), StatusService.STAT_ATTACK)
				assert_equal(int(attack), int(session.player["attack"]) + 3, "rage draught should add attack")
			"skill":
				assert_equal(int(session.energy), 1, "focus tea should restore energy")
			"block":
				assert_equal(int(session.player_block), 2, "emergency kit should add block")
		session.has_acted = false
	session.delete_save()


func test_weapon_critical_weight_and_trigger() -> void:
	var session := PlaySession.new()
	session.delete_save()
	session.start_new_game("warrior")
	session.player["attack"] = 10
	session.player["agility"] = 1
	session.player["critical_weight"] = 100
	session.player["critical_damage_bonus"] = 0.0
	session.player["statuses"] = []
	session.pending_state_card = ""
	var critical_status := {
		"id": "critical_test_trigger",
		"triggers": [{
			"event": TriggerEvents.ON_CRITICAL,
			"conditions": [{"stat": "is_critical", "operator": "eq", "value": true}],
			"actions": [{"type": TriggerEvents.ACTION_APPLY_STATUS, "status": {"id": "critical_marker", "kind": "buff", "effects": []}}]
		}]
	}
	session.status_service.add_status(session.player, critical_status)
	var critical_target := TestHelpers.test_enemy("暴击目标", 1000, 0, [])
	critical_target["agility"] = 2
	session.enemies = [critical_target]
	session.has_acted = false
	session.player_attack(0)
	assert_equal(int(session.enemies[0]["hp"]), 980, "critical weight 100 should double basic attack damage")
	assert_true(session.player.get("statuses", []).any(func(status: Dictionary): return String(status.get("id", "")) == "critical_marker"), "critical attack should fire ON_CRITICAL trigger")
	assert_true(session.battle_log.any(func(entry: String): return entry.contains("暴击命中")), "critical attack should be visible in battle log")
	session.player["critical_weight"] = 0
	session.player["statuses"] = []
	session.enemies[0]["hp"] = 1000
	session.has_acted = false
	session.player_attack(0)
	assert_equal(int(session.enemies[0]["hp"]), 990, "critical weight 0 should keep normal damage")
	session.delete_save()


func test_data_driven_action_execution() -> void:
	var conditional_skill := {"name": "条件动作测试", "type": "attack", "actions": [{"type": "damage", "target": "selected", "multiplier": 1.0, "conditions": [{"stat": "hp", "operator": "lt", "value": 50}]}]}
	var ignore_armor_skill := {"name": "破甲动作测试", "type": "attack", "actions": [{"type": "damage", "target": "selected", "multiplier": 1.0, "ignore_armor": 1.0}]}
	var enemy_damage_skill := {"name": "敌方动作测试", "type": "attack", "class": "enemy", "actions": [{"type": "damage", "target": "selected", "multiplier": 1.5}]}
	var enemy_summon_skill := {"name": "敌方召唤测试", "type": "summon", "class": "enemy", "actions": [{"type": "summon", "unit_id": "rat_minion", "count": 2, "delay": 1}]}
	var unknown_skill := {"name": "未知动作测试", "type": "attack", "actions": [{"type": "not_registered", "target": "self"}]}

	var session := PlaySession.new()
	session.delete_save()
	session.start_new_game("warrior")
	session.player["attack"] = 10
	session.player["critical_weight"] = 0
	session.pending_state_card = ""
	session.player["hp"] = 40
	var target := TestHelpers.test_enemy("动作目标", 100, 0, [])
	target["side"] = "enemy"
	target["agility"] = 9
	target["statuses"] = []
	session.enemies = [target]
	session.battle_service._execute_action_skill(session, "test_action_conditions", conditional_skill, 0, session.player, true)
	assert_equal(int(session.enemies[0]["hp"]), 90, "matching action conditions should execute damage")
	session.has_acted = false
	session.player["hp"] = 80
	session.enemies[0]["hp"] = 100
	session.battle_service._execute_action_skill(session, "test_action_conditions", conditional_skill, 0, session.player, true)
	assert_equal(int(session.enemies[0]["hp"]), 100, "non-matching action conditions should skip damage")

	session.has_acted = false
	session.enemies[0]["hp"] = 100
	session.enemies[0]["armor"] = 30
	session.enemies[0]["defense"] = 30
	session.battle_service._execute_action_skill(session, "test_action_ignore_armor", ignore_armor_skill, 0, session.player, true)
	assert_equal(int(session.enemies[0]["hp"]), 90, "ignore_armor should bypass target armor")

	var enemy := TestHelpers.test_enemy("敌方动作敌人", 100, 10, [])
	enemy["side"] = "enemy"
	enemy["fixed_stats"] = true
	enemy["statuses"] = []
	session.enemies = [enemy]
	session.player["hp"] = 80
	session.battle_service._execute_action_skill(session, "test_enemy_action_damage", enemy_damage_skill, 0, enemy, false)
	assert_equal(int(session.player["hp"]), 65, "enemy actions damage should use the shared target pipeline")

	session.battle_service._execute_action_skill(session, "test_enemy_action_summon", enemy_summon_skill, 0, enemy, false)
	assert_equal(session.enemies.size(), 3, "summon action should add the configured number of enemies")
	assert_equal(int(session.enemies[1].get("available_round", 0)), int(session.round_index) + 1, "summoned enemies should wait for the configured delay")

	session.has_acted = false
	session.message = ""
	session.battle_service._execute_action_skill(session, "test_action_unknown", unknown_skill, 0, session.player, true)
	assert_true(session.message.contains("未知 action"), "unknown action should report a product-visible error")

	session.delete_save()


func test_damage_rounding_uses_ceiling() -> void:
	var session := PlaySession.new()
	session.delete_save()
	session.start_new_game("warrior")
	session.pending_state_card = ""
	session.player["critical_weight"] = 0
	session.player["attack"] = 8
	session.battle_attack_multiplier = 1.05
	assert_equal(CombatRules.current_attack_value(session), 9, "8.4 attack damage should round up to 9")
	session.player["attack"] = 10.5
	assert_equal(CombatRules.skill_attack_value(session, "quick_shot"), 9, "8.4 skill damage should round up to 9")
	session.delete_save()


func test_basic_attack_agility_segments() -> void:
	var status_service := StatusService.new()
	var attacker := {"agility": 12, "statuses": []}
	var target := {"agility": 6, "statuses": []}
	assert_equal(CombatRules.basic_attack_hit_count(attacker, target, status_service), 2, "agility 12 versus 6 should produce two basic attack hits")
	attacker["agility"] = 11
	assert_equal(CombatRules.basic_attack_hit_count(attacker, target, status_service), 1, "agility 11 versus 6 should remain one basic attack hit")

	var session_script = load("res://scripts/core/play_session.gd")
	var realtime = session_script.new()
	realtime.delete_save()
	realtime.start_new_game("unified")
	realtime.tutorial_active = false
	realtime.pending_state_card = ""
	realtime.player["attack"] = 10
	realtime.player["agility"] = 12
	realtime.player["critical_weight"] = 0
	realtime.player["statuses"] = []
	var realtime_enemies: Array[Dictionary] = [TestHelpers.test_enemy("实时敏捷目标", 100, 0, [])]
	realtime.enemies = realtime_enemies
	realtime.enemies[0]["agility"] = 6
	realtime.enemies[0]["statuses"] = []
	realtime.has_acted = false
	realtime.player_attack(0)
	assert_equal(int(realtime.enemies[0]["hp"]), 80, "realtime basic attack should apply two agility-derived hits")



func test_agility_action_order() -> void:
	var status_service := StatusService.new()
	var player := {"name": "玩家", "side": "player", "hp": 100, "agility": 10, "statuses": []}
	var fast_enemy := TestHelpers.test_enemy("高速敌人", 100, 1, [])
	fast_enemy["agility"] = 20
	var slow_enemy := TestHelpers.test_enemy("低速敌人", 100, 1, [])
	slow_enemy["agility"] = 5
	var ordered := CombatRules.action_order(player, [fast_enemy, slow_enemy] as Array[Dictionary], [] as Array[Dictionary], status_service, 1)
	assert_equal(String(ordered[0]["unit"]["name"]), "高速敌人", "higher agility enemy should act first")
	assert_equal(String(ordered[1]["unit"]["name"]), "玩家", "player should be between faster and slower enemies")
	assert_equal(String(ordered[2]["unit"]["name"]), "低速敌人", "slower enemy should act after player")
	player["agility"] = 20
	fast_enemy["agility"] = 20
	ordered = CombatRules.action_order(player, [fast_enemy] as Array[Dictionary], [] as Array[Dictionary], status_service, 1)
	assert_equal(String(ordered[0]["unit"]["name"]), "玩家", "equal agility should prefer player")

	var session_script = load("res://scripts/core/play_session.gd")
	var realtime = session_script.new()
	realtime.start_new_game("unified")
	realtime.player["hp"] = 100
	realtime.player["max_hp"] = 100
	realtime.player["agility"] = 5
	var realtime_enemy := TestHelpers.test_enemy("实时高速敌人", 100, 1, [])
	realtime_enemy["agility"] = 20
	realtime.enemies = [realtime_enemy] as Array[Dictionary]
	realtime.round_index = 0
	realtime.battle_log.clear()
	realtime._begin_player_turn()
	assert_true(int(realtime.player["hp"]) < 100, "faster realtime enemy should attack before player's action")



func test_skeleton_passive_damage_rules() -> void:
	var armored_target := {"hp": 100, "armor": 10, "block": 0, "dodge_layers": 0}
	var damage_result := Combatant.apply_damage(armored_target, 30, "physical", 0.80)
	assert_equal(int(damage_result["damage"]), 24, "break armor should ignore 20 percent of armor")
	assert_equal(int(CombatRules.shadow_armor_reflect_damage({"damage_before_block": 10, "block_absorbed": 5, "block_broken": true, "damage": 5})), 10, "shadow armor should reflect twice when block breaks")
	var protected_target := {"hp": 100, "passive_skills": ["", "", "", ""]}
	var guard := {"hp": 100, "passive_skills": ["guard", "", "", ""]}
	assert_equal(CombatRules.ally_guard_damage_multiplier(protected_target, [protected_target, guard]), 0.80, "living guard should protect teammates")
	assert_equal(CombatRules.ally_guard_damage_multiplier(guard, [protected_target, guard]), 1.0, "guard should not protect itself")
	guard["hp"] = 0
	assert_equal(CombatRules.ally_guard_damage_multiplier(protected_target, [protected_target, guard]), 1.0, "dead guard should not protect teammates")
	var status_service := StatusService.new()
	var enraged := {"hp": 49, "max_hp": 100, "statuses": [], "passive_skills": ["enrage", "", "", ""]}
	Combatant.normalize_enemy(enraged)
	assert_equal(int(status_service.resolve_stat(enraged, 10.0, "attack")), 15, "enrage should increase damage below half health")
	assert_equal(status_service.resolve_stat(enraged, 1.0, "damage_taken"), 1.30, "enrage should increase damage taken below half health")


func test_skeleton_taunt_requires_an_ally() -> void:
	var EnemyActionRules = preload("res://scripts/core/enemy_action_rules.gd")
	var rules = EnemyActionRules.new()
	var skeleton := {
		"hp": 50, "max_hp": 50,
		"behavior_weights": {"enemy_skeleton_taunt": 40},
		"skill_cooldowns": {},
		"innate_skills": {"attack_1": "innate_attack_1"}
	}
	assert_equal(rules.choose_skill(skeleton, 1, {}, true), "innate_attack_1", "taunt should be unavailable when alone")
	skeleton["skill_cooldowns"] = {"enemy_skeleton_taunt": 2}
	assert_equal(rules.choose_skill(skeleton, 1, {}, false), "innate_attack_1", "taunt should respect cooldown")


func test_hidden_targets_require_visible_fallback() -> void:
	var hidden_enemy := {"hp": 10, "passive_skills": ["hidden", "", "", ""]}
	var visible_enemy := {"hp": 10, "passive_skills": ["", "", "", ""]}
	assert_equal(CombatRules.valid_target([hidden_enemy, visible_enemy], 0), 1, "hidden enemy should be skipped while visible targets exist")
	assert_equal(CombatRules.valid_target([hidden_enemy], 0), 0, "hidden enemy should still be targetable when alone")


func test_curse_refreshes_instead_of_stacking() -> void:
	var status_service := StatusService.new()
	var attacker := Combatant.from_enemy_unit({
		"name": "诅咒测试施法者",
		"rank": "normal",
		"hp": 20,
		"attack": 10,
		"defense": 0,
		"passive_skills": ["curse", "", "", ""],
		"skills": []
	}, "normal", 1)
	var target := {"hp": 100, "max_hp": 100, "statuses": []}
	status_service.fire_trigger(attacker, TriggerEvents.ON_HIT_DEALT, {"session": null, "battle_log": [], "source": attacker, "target": target})
	status_service.fire_trigger(attacker, TriggerEvents.ON_HIT_DEALT, {"session": null, "battle_log": [], "source": attacker, "target": target})
	var curse_statuses: Array = target.get("statuses", []).filter(func(status): return String(status.get("id", "")) == "curse_debuff")
	assert_equal(curse_statuses.size(), 1, "curse should refresh instead of stacking")
	assert_equal(int(curse_statuses[0]["duration"]), 3, "curse duration should refresh to 3 rounds")


func test_toxic_mist_hits_player_and_allies() -> void:
	var status_service := StatusService.new()
	var player := {"hp": 100, "max_hp": 100, "statuses": []}
	var ally := {"hp": 100, "max_hp": 100, "statuses": []}
	var enemy := {"hp": 100, "max_hp": 100, "side": "enemy", "statuses": [], "passive_skills": []}
	var boss := {
		"hp": 100,
		"max_hp": 100,
		"attack": 20,
		"defense": 0,
		"side": "enemy",
		"passive_skills": ["toxic_mist", "", "", ""],
		"statuses": []
	}
	CombatRules.apply_arena_effects(player, [boss, enemy], 3, status_service, [ally], [])
	assert_equal(int(player["hp"]), 94, "toxic mist should deal 30 percent of the boss attack to the player")
	assert_equal(int(ally["hp"]), 94, "toxic mist should deal 30 percent of the boss attack to allies")
	assert_equal(int(boss["hp"]), 100, "toxic mist should not affect its holder")
	assert_equal(int(enemy["hp"]), 100, "toxic mist should not affect enemy units")


func test_arena_damage_and_heal_modifiers() -> void:
	var status_service := StatusService.new()
	var player := {"hp": 100, "max_hp": 100, "attack": 10, "statuses": []}
	var shadow_boss := {"hp": 100, "max_hp": 100, "side": "enemy", "passive_skills": ["shadow_domain", "", "", ""], "statuses": []}
	CombatRules.apply_arena_effects(player, [shadow_boss], 1, status_service)
	assert_equal(status_service.resolve_stat(player, 1.0, StatusService.STAT_SHADOW_DAMAGE), 1.20, "shadow domain should increase shadow damage")
	assert_equal(status_service.resolve_stat(player, 10.0, StatusService.STAT_HEAL), 5.0, "shadow domain should halve healing")

	player["statuses"] = []
	var blood_boss := {"hp": 100, "max_hp": 100, "side": "enemy", "passive_skills": ["blood_moon", "", "", ""], "statuses": []}
	CombatRules.apply_arena_effects(player, [blood_boss], 1, status_service)
	assert_equal(int(status_service.resolve_stat(player, 10.0, StatusService.STAT_ATTACK)), 11, "blood moon should add one attack")
	assert_equal(int(status_service.resolve_stat(player, 10.0, StatusService.STAT_HEAL)), 11, "blood moon should add one healing")

	var session := PlaySession.new()
	session.delete_save()
	session.start_new_game("warrior")
	session.player["hp"] = 40
	session.player["max_hp"] = 80
	session.player["statuses"] = [{"id": "shadow_heal_test", "kind": "debuff", "effects": [{"stat": StatusService.STAT_HEAL, "type": StatusService.EFFECT_MULTIPLY, "value": 0.50}]}]
	session.has_acted = false
	session.use_blood_potion_in_battle()
	assert_equal(int(session.player["hp"]), 52, "blood potion should respect healing modifiers")
	session.delete_save()


func test_new_units_wait_one_round() -> void:
	var summoned := Combatant.rat_minion(4, 5)
	assert_equal(int(summoned["available_round"]), 5, "summoned unit should wait until the next round")

	var split_enemy := {
		"hp": 40,
		"max_hp": 100,
		"attack": 8,
		"defense": 2,
		"block_power": 2,
		"passive_skills": ["split", "", "", ""],
		"skills": [],
		"split_triggered": false
	}
	var split_enemies: Array[Dictionary] = [split_enemy]
	CombatRules.check_split_after_damage(split_enemies, split_enemy, 7, [])
	assert_equal(int(split_enemies[1]["available_round"]), 8, "split unit should wait until the next round")


func test_swarm_triggers_one_assist_per_living_ally() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	session.player["hp"] = 100
	session.player["defense"] = 0
	session.player_block = 0
	var rats: Array[Dictionary] = [
		TestHelpers.test_enemy("群袭甲", 30, 10, []),
		TestHelpers.test_enemy("群袭乙", 30, 10, [])
	]
	for rat in rats:
		rat["passive_skills"] = ["swarm", "", "", ""]
	session.enemies = rats
	session._enemy_attack(session.enemies[0], 0, false)
	assert_equal(int(session.player["hp"]), 80, "one living swarm ally should contribute exactly one normal attack")


func test_block_power_is_separate_from_armor() -> void:
	assert_equal(int(DataCatalog.CLASSES["unified"]["base_block"]), 4, "unified base block")
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("archer")
	session.player["defense"] = 0
	session.player["block_power"] = 7
	session.player_defend()
	assert_equal(int(session.player_block), 7, "defend should use block power even when armor is zero")


func test_enemy_block_power_is_separate_from_armor() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	var enemy := {
		"name": "格挡测试敌人",
		"rank": "normal",
		"max_hp": 100,
		"hp": 100,
		"attack": 1,
		"defense": 3,
		"armor": 3,
		"block_power": 9,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": []
	}
	var gained: int = session._enemy_defend(enemy, 1.0)
	assert_equal(gained, 9, "enemy defend should use block power")
	assert_equal(int(enemy["armor"]), 3, "enemy defend should not increase armor")
	assert_equal(int(enemy["block"]), 9, "enemy defend should increase current block")
	var test_enemies: Array[Dictionary] = [enemy]
	session.enemies = test_enemies
	session._apply_damage_to_enemy(0, 30)
	assert_true(int(session.enemies[0]["hp"]) < 100, "damage should pass after armor and block")
	assert_true(int(session.enemies[0]["block"]) < 9, "enemy block should absorb part of incoming damage")


func test_player_and_enemy_share_combatant_contract() -> void:
	var character := CharacterService.new()
	var player := character.create_character("warrior")
	var player_unit := Combatant.from_player(player, 0, 0)
	var enemy_unit := Combatant.from_enemy_unit({
		"name": "统一模板测试敌人",
		"rank": "normal",
		"hp": 30,
		"attack": 5,
		"defense": 2,
		"traits": []
	}, "normal", 1)
	for key in ["side", "rank", "max_hp", "hp", "attack", "defense", "armor", "block_power", "block", "dodge_layers", "taunt", "passive_skills"]:
		assert_true(player_unit.has(key), "player combatant has %s" % key)
		assert_true(enemy_unit.has(key), "enemy combatant has %s" % key)
	var player_damage := Combatant.apply_damage(player_unit, 20)
	var enemy_damage := Combatant.apply_damage(enemy_unit, 20)
	assert_true(int(player_damage["damage"]) > 0, "player combatant should take resolved damage")
	assert_true(int(enemy_damage["damage"]) > 0, "enemy combatant should take resolved damage")


func test_thick_skin_always_grants_armor() -> void:
	var enemy: Dictionary = Combatant.scaled_enemy({
		"name": "厚皮测试",
		"hp": 1.0,
		"attack": 1.0,
		"defense": 0.0,
		"traits": ["thick_skin"]
	}, 1, "normal", 1.0)
	assert_true(int(enemy["armor"]) >= 1, "thick skin should grant at least one armor")

	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	var loaded_enemies: Array[Dictionary] = [{
		"name": "旧存档厚皮",
		"rank": "normal",
		"max_hp": 10,
		"hp": 10,
		"attack": 1,
		"defense": 0,
		"armor": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": ["thick_skin"]
	}]
	session.enemies = loaded_enemies
	session._normalize_loaded_enemies()
	assert_true(int(session.enemies[0]["armor"]) >= 1, "loaded thick skin enemy should recover armor")


func test_loaded_enemy_traits_are_idempotent() -> void:
	var enemy := Combatant.from_enemy_unit({
		"name": "重复特性测试",
		"rank": "normal",
		"hp": 30,
		"attack": 5,
		"defense": 2,
		"passive_skills": ["curse", "", "", ""]
	}, "normal", 1)
	enemy["statuses"].append({"id": "saved_dynamic_status", "kind": "debuff", "duration": 2})
	Combatant.normalize_enemy(enemy)
	Combatant.normalize_enemy(enemy)
	var trait_statuses: Array = enemy["statuses"].filter(func(status): return String(status.get("id", "")).begins_with("trait_"))
	assert_equal(trait_statuses.size(), 1, "reloading an enemy should not duplicate trait statuses")
	assert_true(enemy["statuses"].any(func(status): return String(status.get("id", "")) == "saved_dynamic_status"), "reloading should preserve dynamic statuses")


func test_skill_multiplier_effects() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var warrior = session_script.new()
	warrior.start_new_game("warrior")
	warrior.player["equipped_skills"] = ["", "", "war_cry", ""]
	warrior.energy = 12
	warrior.use_skill(2, 0)
	var statuses: Array = warrior.player.get("statuses", [])
	assert_true(statuses.size() > 0, "war cry should add a status to player")
	var resolved_attack: float = warrior.status_service.resolve_stat(warrior.player, float(warrior.player["attack"]), StatusService.STAT_ATTACK)
	assert_true(resolved_attack > float(warrior.player["attack"]), "war cry should increase resolved attack via status")

	var archer = session_script.new()
	archer.start_new_game("archer")
	archer.player["equipped_skills"] = ["", "", "hunter_mark", ""]
	archer.player["attack"] = 10
	var marked_enemies: Array[Dictionary] = [{
		"name": "标记测试敌人",
		"rank": "normal",
		"max_hp": 100,
		"hp": 100,
		"attack": 0,
		"defense": 0,
		"armor": 0,
		"block_power": 1,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": []
	}]
	archer.enemies = marked_enemies
	archer.energy = int(DataCatalog.SKILLS["hunter_mark"]["energy_cost"])
	archer.use_skill(2, 0)
	assert_true(archer.enemies[0].get("statuses", []).size() > 0, "hunter mark should add a debuff status to enemy")
	var dmg_mult: float = archer.status_service.resolve_stat(archer.enemies[0], 1.0, StatusService.STAT_DAMAGE_TAKEN)
	assert_true(dmg_mult > 1.0, "hunter mark should increase damage taken multiplier")
	archer.has_acted = false
	archer.player_attack(0)
	assert_true(int(archer.enemies[0]["hp"]) < 90, "hunter mark should amplify following attack damage")


func test_counter_stance_and_multihit_dodge() -> void:
	var session_script = load("res://scripts/core/play_session.gd")

	var warrior = session_script.new()
	warrior.start_new_game("warrior")
	warrior.player["equipped_skills"] = ["counter_stance"]
	warrior.player["attack"] = 10
	var counter_enemies: Array[Dictionary] = [TestHelpers.test_enemy("反击测试敌人", 100, 1, [])]
	warrior.enemies = counter_enemies
	warrior.energy = int(DataCatalog.SKILLS["counter_stance"]["energy_cost"])
	warrior.use_skill(0, 0)
	warrior._enemy_attack(warrior.enemies[0], 0, false)
	assert_true(int(warrior.enemies[0]["hp"]) < 100, "counter stance should counterattack after being hit")
	assert_equal(int(warrior.counter_stance_charges), 0, "counter stance should consume one counter charge")

	var archer = session_script.new()
	archer.delete_save()
	archer.start_new_game("archer")
	archer.tutorial_active = false
	archer.pending_state_card = ""
	archer.player["extra_hits"] = 0
	archer.player["skill_attachments"] = {}
	archer.player["weapon_skill_2"] = "quick_shot"
	archer.player["attack"] = 10
	archer.player["critical_weight"] = 0
	var dodging_enemies: Array[Dictionary] = [TestHelpers.test_enemy("闪避测试敌人", 100, 0, [])]
	dodging_enemies[0]["dodge_layers"] = 1
	archer.enemies = dodging_enemies
	archer.energy = int(DataCatalog.SKILLS["quick_shot"]["energy_cost"])
	archer.use_skill(1, 0)
	assert_equal(int(archer.enemies[0]["hp"]), 52, "quick shot should only lose its first hit to one dodge layer")

	var dodger = session_script.new()
	dodger.start_new_game("warrior")
	dodger.player["hp"] = 100
	dodger.player["defense"] = 0
	dodger.player_block = 0
	dodger.dodge_layers = 1
	var swarm_enemies: Array[Dictionary] = [TestHelpers.test_enemy("多段测试敌人", 100, 10, ["swarm"])]
	dodger.enemies = swarm_enemies
	dodger._enemy_attack(dodger.enemies[0], 0, false)
	assert_equal(int(dodger.dodge_layers), 0, "one dodge layer should be consumed by the first hit only")
	assert_equal(int(dodger.player["hp"]), 100, "swarm should not add a self extra hit without a living swarm ally")


func test_block_expires_each_round() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	session.player_block = 999
	session.end_turn()
	assert_equal(int(session.player_block), 0, "block should expire when next player turn begins")

func test_enemy_skill_execution() -> void:
	var session_script = load("res://scripts/core/play_session.gd")
	var session = session_script.new()
	session.start_new_game("warrior")
	session.player["hp"] = 200
	var enemy := {
		"name": "技能测试敌人",
		"rank": "normal",
		"max_hp": 100,
		"hp": 20,
		"attack": 10,
		"defense": 3,
		"armor": 0,
		"block_power": 3,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": [],
		"skills": ["enemy_heavy_strike"],
		"innate_skills": {"attack_1": "innate_attack_1", "defend": "innate_defend", "dodge": "innate_dodge"}
	}
	session.enemies = [enemy] as Array[Dictionary]
	session.end_turn()
	var used_skill := false
	for entry in session.battle_log:
		if "重击" in entry:
			used_skill = true
			break
	assert_true(used_skill, "enemy with heavy strike skill should use it during its turn")

	session = session_script.new()
	session.start_new_game("warrior")
	session.player["hp"] = 200
	var defend_enemy := {
		"name": "防御技能敌人",
		"rank": "normal",
		"max_hp": 100,
		"hp": 100,
		"attack": 10,
		"defense": 3,
		"armor": 0,
		"block_power": 3,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": ["fortify"],
		"skills": ["enemy_fortify"],
		"innate_skills": {"attack_1": "innate_attack_1", "defend": "innate_defend", "dodge": "innate_dodge"}
	}
	session.enemies = [defend_enemy, TestHelpers.test_enemy("防御旁观敌人", 10, 0, [])] as Array[Dictionary]
	session.end_turn()
	var used_defend := false
	for entry in session.battle_log:
		if "固守" in entry:
			used_defend = true
			break
	assert_true(used_defend, "enemy with fortify skill should use it")
	assert_true(int(defend_enemy["block"]) > 0, "enemy should gain block from fortify skill")


func test_enemy_ai_skill_selection() -> void:
	var EnemyActionRules = preload("res://scripts/core/enemy_action_rules.gd")
	var rules = EnemyActionRules.new()

	var enemy := {
		"name": "AI测试敌人",
		"rank": "normal",
		"max_hp": 100,
		"hp": 100,
		"attack": 10,
		"defense": 3,
		"armor": 0,
		"block_power": 3,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": [],
		"skills": ["enemy_heavy_strike", "enemy_fortify"],
		"innate_skills": {"attack_1": "innate_attack_1", "defend": "innate_defend", "dodge": "innate_dodge"}
	}
	assert_equal(rules.choose_skill(enemy, 1), "enemy_heavy_strike", "should choose attack skill when healthy")

	enemy["hp"] = 20
	var chosen := rules.choose_skill(enemy, 1)
	assert_equal(chosen, "enemy_fortify", "should choose defense skill when low HP")

	var tank_enemy := {
		"name": "坦克AI",
		"rank": "normal",
		"max_hp": 100,
		"hp": 100,
		"attack": 10,
		"defense": 5,
		"armor": 0,
		"block_power": 5,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": ["tank"],
		"skills": ["enemy_heavy_strike", "enemy_fortify"],
		"innate_skills": {"attack_1": "innate_attack_1", "defend": "innate_defend", "dodge": "innate_dodge"}
	}
	assert_equal(rules.choose_skill(tank_enemy, 2), "enemy_fortify", "tank should prefer defense on even rounds")

	var no_skills_enemy := {
		"name": "无技能敌人",
		"rank": "normal",
		"max_hp": 50,
		"hp": 50,
		"attack": 5,
		"defense": 0,
		"armor": 0,
		"block_power": 1,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": [],
		"skills": [],
		"innate_skills": {"attack_1": "innate_attack_1", "defend": "innate_defend", "dodge": "innate_dodge"}
	}
	assert_equal(rules.choose_skill(no_skills_enemy, 1), "innate_attack_1", "enemy with no skills should fallback to innate attack")


func test_enemy_enrage_duration_and_cooldown() -> void:
	var enrage_skill: Dictionary = DataCatalog.SKILLS["enemy_enrage"]
	assert_equal(int(enrage_skill["duration"]), 4, "enemy enrage should last four rounds")
	assert_equal(int(enrage_skill["cooldown"]), 6, "enemy enrage should have a six-round cooldown")

	var play_session_script = load("res://scripts/core/play_session.gd")
	var battle_service_script = load("res://scripts/core/battle_service.gd")
	var session = play_session_script.new()
	session.delete_save()
	session.start_new_game("warrior")
	session.player["hp"] = 200
	var enemy := {
		"name": "狂暴测试敌人",
		"side": "enemy",
		"rank": "normal",
		"max_hp": 100,
		"hp": 100,
		"attack": 10,
		"defense": 3,
		"armor": 0,
		"block_power": 3,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"passive_skills": [],
		"skills": ["enemy_enrage", "enemy_heavy_strike"],
		"behavior_weights": {"enemy_enrage": 20},
		"skill_cooldowns": {},
		"statuses": [],
		"innate_skills": {"attack_1": "innate_attack_1", "defend": "innate_defend", "dodge": "innate_dodge"}
	}
	session.enemies = [enemy] as Array[Dictionary]
	var battle_service = battle_service_script.new()
	battle_service.resolve_enemy_action(session, enemy, 0)
	assert_equal(int(enemy["skill_cooldowns"]["enemy_enrage"]), 6, "using enemy enrage should start its cooldown")
	var enrage_status: Dictionary = {}
	for status in enemy["statuses"]:
		if String(status.get("id", "")) == "enemy_enrage":
			enrage_status = status
			break
	assert_equal(int(enrage_status.get("duration", -1)), 4, "enemy enrage status should last four rounds")

	var rules = load("res://scripts/core/enemy_action_rules.gd").new()
	enemy["behavior_weights"] = {"enemy_enrage": 20, "enemy_heavy_strike": 1}
	assert_equal(rules.choose_skill(enemy, 1), "enemy_heavy_strike", "cooling-down enemy enrage should be excluded from behavior weights")
	session.delete_save()


func test_enemy_taunt_skill() -> void:
	var EnemyActionRules = preload("res://scripts/core/enemy_action_rules.gd")
	var rules = EnemyActionRules.new()

	var taunt_enemy := {
		"name": "嘲讽测试敌人",
		"rank": "normal",
		"max_hp": 100,
		"hp": 100,
		"attack": 10,
		"defense": 3,
		"armor": 0,
		"block_power": 3,
		"block": 0,
		"dodge_layers": 0,
		"taunt": 0,
		"traits": ["taunt"],
		"skills": ["enemy_taunt"],
		"innate_skills": {"attack_1": "innate_attack_1", "defend": "innate_defend", "dodge": "innate_dodge"}
	}
	assert_equal(rules.choose_skill(taunt_enemy, 1), "enemy_taunt", "taunt enemy should use taunt skill on round 1")
	assert_equal(rules.choose_skill(taunt_enemy, 2), "innate_attack_1", "taunt enemy should use innate attack on round 2")

	taunt_enemy["taunt"] = 1
	assert_equal(rules.choose_skill(taunt_enemy, 4), "innate_attack_1", "taunt enemy with active taunt should not taunt again on round 4")


func test_rank_skill_multiplier() -> void:
	var CombatRules = preload("res://scripts/core/combat_rules.gd")

	var normal_enemy := {
		"name": "普通敌人",
		"rank": "normal",
		"attack": 10,
		"block_power": 5,
		"max_hp": 100
	}
	var elite_enemy := {
		"name": "精英敌人",
		"rank": "elite",
		"attack": 10,
		"block_power": 5,
		"max_hp": 100
	}
	var boss_enemy := {
		"name": "Boss敌人",
		"rank": "boss",
		"attack": 10,
		"block_power": 5,
		"max_hp": 100
	}

	var normal_dmg := CombatRules.skill_attack_value_for_actor(normal_enemy, "enemy_heavy_strike")
	var elite_dmg := CombatRules.skill_attack_value_for_actor(elite_enemy, "enemy_heavy_strike")
	var boss_dmg := CombatRules.skill_attack_value_for_actor(boss_enemy, "enemy_heavy_strike")

	assert_equal(normal_dmg, 15, "normal rank should use base 1.50 multiplier")
	assert_equal(elite_dmg, 18, "elite rank should apply 1.20 rank multiplier")
	assert_equal(boss_dmg, 22, "boss rank should apply 1.45 rank multiplier")

	var normal_block := CombatRules.skill_defense_value_for_actor(normal_enemy, "enemy_fortify")
	var elite_block := CombatRules.skill_defense_value_for_actor(elite_enemy, "enemy_fortify")

	assert_equal(normal_block, 8, "normal defense should use base multiplier")
	assert_equal(elite_block, 9, "elite defense should apply rank multiplier")
