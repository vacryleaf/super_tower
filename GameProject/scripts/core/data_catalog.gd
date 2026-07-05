extends RefCounted
class_name DataCatalog

const BATTLE_TYPES := ["normal", "normal", "normal", "elite", "normal", "normal", "normal", "elite", "normal", "boss"]

const STATE_CARDS := {
	"steady": {"name": "Steady", "weight": 50, "multiplier": 1.0, "tag": "numeric"},
	"good": {"name": "Good Effect", "weight": 20, "multiplier": 1.1, "tag": "numeric"},
	"great": {"name": "Great Effect", "weight": 10, "multiplier": 1.2, "tag": "numeric"},
	"critical": {"name": "Critical", "weight": 5, "multiplier": 2.0, "tag": "attack"},
	"read": {"name": "Read", "weight": 5, "multiplier": 2.0, "tag": "dodge"},
	"perfect_guard": {"name": "Perfect Guard", "weight": 5, "multiplier": 2.0, "tag": "defense"},
	"fallback": {"name": "Emergency Fallback", "weight": 5, "multiplier": 1.0, "tag": "hybrid"}
}

const CLASSES := {
	"warrior": {
		"name": "Warrior",
		"max_hp": 90,
		"base_attack": 7,
		"base_defense": 5,
		"resource": "rage",
		"first_skill": "heavy_slash"
	},
	"archer": {
		"name": "Archer",
		"max_hp": 70,
		"base_attack": 8,
		"base_defense": 4,
		"resource": "focus",
		"first_skill": "precise_shot"
	}
}

const SKILLS := {
	"heavy_slash": {"name": "Heavy Slash", "class": "warrior", "type": "attack", "cost": 1, "power": 12},
	"shield_wall": {"name": "Shield Wall", "class": "warrior", "type": "defense", "cost": 1, "power": 14},
	"counter_stance": {"name": "Counter Stance", "class": "warrior", "type": "stance", "cost": 2, "power": 6},
	"war_cry": {"name": "War Cry", "class": "warrior", "type": "buff", "cost": 1, "power": 2},
	"precise_shot": {"name": "Precise Shot", "class": "archer", "type": "attack", "cost": 1, "power": 10},
	"quick_shot": {"name": "Quick Shot", "class": "archer", "type": "attack", "cost": 2, "power": 18},
	"hunter_mark": {"name": "Hunter Mark", "class": "archer", "type": "debuff", "cost": 1, "power": 3},
	"roll": {"name": "Roll", "class": "archer", "type": "dodge", "cost": 0, "power": 5},
	"first_aid": {"name": "First Aid", "class": "common", "type": "heal", "cost": 1, "power": 18},
	"tactical_retreat": {"name": "Tactical Retreat", "class": "common", "type": "dodge", "cost": 1, "power": 1}
}

const EQUIPMENT := {
	"warrior_training_helm": {"class": "warrior", "slot": "head", "name": "Training Helm", "hp": 10, "attack": 0, "armor": 2},
	"warrior_old_chest": {"class": "warrior", "slot": "body", "name": "Old Chestplate", "hp": 14, "attack": 0, "armor": 3},
	"warrior_soldier_belt": {"class": "warrior", "slot": "waist", "name": "Soldier Belt", "hp": 8, "attack": 0, "armor": 1},
	"warrior_practice_greaves": {"class": "warrior", "slot": "legs", "name": "Practice Greaves", "hp": 6, "attack": 0, "armor": 4},
	"warrior_cloth_gloves": {"class": "warrior", "slot": "hands", "name": "Cloth Gloves", "hp": 4, "attack": 2, "armor": 1},
	"warrior_old_leggings": {"class": "warrior", "slot": "leggings", "name": "Old Leggings", "hp": 8, "attack": 0, "armor": 3},
	"warrior_march_boots": {"class": "warrior", "slot": "feet", "name": "March Boots", "hp": 5, "attack": 0, "armor": 3},
	"warrior_training_sword": {"class": "warrior", "slot": "weapon", "name": "Training Sword", "hp": 0, "attack": 5, "armor": 0},
	"warrior_wooden_shield": {"class": "warrior", "slot": "offhand", "name": "Wooden Shield", "hp": 4, "attack": 0, "armor": 5},
	"archer_practice_hood": {"class": "archer", "slot": "head", "name": "Practice Hood", "hp": 7, "attack": 1, "armor": 1},
	"archer_old_leather": {"class": "archer", "slot": "body", "name": "Old Leather", "hp": 10, "attack": 0, "armor": 2},
	"archer_hunter_belt": {"class": "archer", "slot": "waist", "name": "Hunter Belt", "hp": 6, "attack": 1, "armor": 1},
	"archer_light_pants": {"class": "archer", "slot": "legs", "name": "Light Pants", "hp": 6, "attack": 1, "armor": 2},
	"archer_bracers": {"class": "archer", "slot": "hands", "name": "Bracers", "hp": 3, "attack": 2, "armor": 1},
	"archer_soft_leggings": {"class": "archer", "slot": "leggings", "name": "Soft Leggings", "hp": 6, "attack": 0, "armor": 2},
	"archer_light_boots": {"class": "archer", "slot": "feet", "name": "Light Boots", "hp": 4, "attack": 1, "armor": 1},
	"archer_practice_bow": {"class": "archer", "slot": "weapon", "name": "Practice Bow", "hp": 0, "attack": 5, "armor": 0},
	"archer_simple_quiver": {"class": "archer", "slot": "offhand", "name": "Simple Quiver", "hp": 2, "attack": 2, "armor": 1}
}

const TUTORIAL_UNLOCKS := {
	"warrior": [
		"warrior_training_helm", "warrior_old_chest", "warrior_soldier_belt",
		"warrior_practice_greaves", "warrior_cloth_gloves", "warrior_old_leggings",
		"warrior_march_boots", "warrior_training_sword", "warrior_wooden_shield", "heavy_slash"
	],
	"archer": [
		"archer_practice_hood", "archer_old_leather", "archer_hunter_belt",
		"archer_light_pants", "archer_bracers", "archer_soft_leggings",
		"archer_light_boots", "archer_practice_bow", "archer_simple_quiver", "precise_shot"
	]
}

const TUTORIAL_ENCOUNTERS := [
	{"id": "tutorial_01", "type": "normal", "name": "Training Rat", "units": [{"name": "Training Rat", "rank": "normal", "hp": 12, "attack": 3, "defense": 0, "traits": []}]},
	{"id": "tutorial_02", "type": "normal", "name": "Slow Guard", "units": [{"name": "Slow Guard", "rank": "normal", "hp": 18, "attack": 4, "defense": 2, "traits": []}]},
	{"id": "tutorial_03", "type": "normal", "name": "Goblin Slinger", "units": [{"name": "Goblin Slinger", "rank": "normal", "hp": 16, "attack": 4, "defense": 1, "traits": []}]},
	{"id": "tutorial_04", "type": "elite", "name": "Shield Trainee", "units": [{"name": "Shield Trainee", "rank": "elite", "hp": 26, "attack": 5, "defense": 3, "traits": ["guard"]}]},
	{"id": "tutorial_05", "type": "normal", "name": "Goblin Pair", "units": [{"name": "Goblin Spear", "rank": "normal", "hp": 12, "attack": 3, "defense": 0, "traits": []}, {"name": "Goblin Stone", "rank": "normal", "hp": 12, "attack": 3, "defense": 0, "traits": []}]},
	{"id": "tutorial_06", "type": "normal", "name": "Poison Tail", "units": [{"name": "Poison Tail", "rank": "normal", "hp": 20, "attack": 4, "defense": 1, "traits": ["corrode"]}]},
	{"id": "tutorial_07", "type": "normal", "name": "Shadow Student", "units": [{"name": "Shadow Student", "rank": "normal", "hp": 18, "attack": 4, "defense": 1, "traits": ["first_strike"]}]},
	{"id": "tutorial_08", "type": "elite", "name": "Iron Trainer", "units": [{"name": "Iron Trainer", "rank": "elite", "hp": 34, "attack": 6, "defense": 4, "traits": ["thick_skin"]}]},
	{"id": "tutorial_09", "type": "normal", "name": "Echo Acolyte", "units": [{"name": "Echo Acolyte", "rank": "normal", "hp": 20, "attack": 4, "defense": 2, "traits": ["summon"]}, {"name": "Echo Servant", "rank": "normal", "hp": 10, "attack": 2, "defense": 0, "traits": ["support"]}]},
	{"id": "tutorial_10", "type": "boss", "name": "Trial Gatekeeper", "units": [{"name": "Trial Gatekeeper", "rank": "boss", "hp": 58, "attack": 7, "defense": 4, "traits": ["phase"]}]}
]

const NORMAL_UNITS := [
	{"id": "normal_rat_01", "name": "Rot Rat", "hp": 0.75, "attack": 0.90, "defense": 0.60, "traits": ["swarm"]},
	{"id": "normal_rat_02", "name": "Fang Rat", "hp": 0.80, "attack": 1.05, "defense": 0.60, "traits": ["claw"]},
	{"id": "normal_guard_01", "name": "Rust Guard", "hp": 1.10, "attack": 0.75, "defense": 1.30, "traits": ["thick_skin"]},
	{"id": "normal_guard_03", "name": "Spear Guard", "hp": 0.95, "attack": 1.00, "defense": 1.10, "traits": ["break_armor"]},
	{"id": "normal_shadow_01", "name": "Shade Thief", "hp": 0.75, "attack": 1.05, "defense": 0.70, "traits": ["first_strike"]},
	{"id": "normal_shadow_02", "name": "Dark Crossbow", "hp": 0.80, "attack": 1.15, "defense": 0.70, "traits": ["mark"]},
	{"id": "normal_caster_01", "name": "Acolyte", "hp": 0.80, "attack": 0.90, "defense": 0.80, "traits": ["curse"]},
	{"id": "normal_mutant_02", "name": "Crystal Beast", "hp": 0.95, "attack": 1.05, "defense": 0.95, "traits": ["break_armor"]}
]

const ELITE_UNITS := [
	{"id": "elite_rat_01", "name": "Rat Captain", "hp": 0.95, "attack": 1.05, "defense": 0.80, "traits": ["swarm", "summon"]},
	{"id": "elite_guard_01", "name": "Iron Captain", "hp": 1.20, "attack": 0.95, "defense": 1.50, "traits": ["guard", "fortify"]},
	{"id": "elite_shadow_01", "name": "Shadow Hunter", "hp": 0.90, "attack": 1.25, "defense": 0.90, "traits": ["first_strike", "mark"]},
	{"id": "elite_caster_01", "name": "Deep Priest", "hp": 1.00, "attack": 1.00, "defense": 1.00, "traits": ["curse", "summon"]},
	{"id": "elite_mutant_01", "name": "Tower Brute", "hp": 1.35, "attack": 1.00, "defense": 1.25, "traits": ["thick_skin", "revive"]}
]

const BOSS_UNITS := [
	{"id": "boss_rat_king", "name": "Rat King", "hp": 1.00, "attack": 1.10, "defense": 0.90, "traits": ["swarm", "summon", "enrage"]},
	{"id": "boss_iron_warden", "name": "Iron Warden", "hp": 1.25, "attack": 1.00, "defense": 1.45, "traits": ["thick_skin", "guard", "fortify"]},
	{"id": "boss_shadow_duke", "name": "Shadow Duke", "hp": 0.95, "attack": 1.30, "defense": 1.00, "traits": ["first_strike", "evade", "mark"]},
	{"id": "boss_deep_oracle", "name": "Deep Oracle", "hp": 1.05, "attack": 1.10, "defense": 1.20, "traits": ["curse", "spell_shield", "summon"]},
	{"id": "boss_tower_core", "name": "Tower Core", "hp": 1.20, "attack": 1.20, "defense": 1.20, "traits": ["revive", "charge", "split"]}
]


static func get_state_weight_total() -> int:
	var total := 0
	for card in STATE_CARDS.values():
		total += int(card["weight"])
	return total


static func get_floor_battle_type(index: int) -> String:
	return BATTLE_TYPES[index - 1]
