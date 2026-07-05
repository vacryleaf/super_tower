extends RefCounted
class_name DataCatalog

const DataRepository = preload("res://scripts/core/data_repository.gd")

const BATTLE_TYPES := ["normal", "normal", "normal", "elite", "normal", "normal", "normal", "elite", "normal", "boss"]

const STATE_CARDS := {
	"steady": {"name": "平稳", "weight": 50, "multiplier": 1.0, "tag": "numeric"},
	"good": {"name": "效果不错", "weight": 20, "multiplier": 1.1, "tag": "numeric"},
	"great": {"name": "效果拔群", "weight": 10, "multiplier": 1.2, "tag": "numeric"},
	"critical": {"name": "暴击", "weight": 5, "multiplier": 2.0, "tag": "attack"},
	"read": {"name": "识破", "weight": 5, "multiplier": 2.0, "tag": "dodge"},
	"perfect_guard": {"name": "完美格挡", "weight": 5, "multiplier": 2.0, "tag": "defense"},
	"fallback": {"name": "紧急回撤", "weight": 5, "multiplier": 1.0, "tag": "hybrid"}
}

const CLASSES := {
	"warrior": {
		"name": "战士",
		"max_hp": 90,
		"base_attack": 7,
		"base_defense": 1,
		"base_block": 5,
		"resource": "rage",
		"first_skill": "heavy_slash"
	},
	"archer": {
		"name": "弓箭手",
		"max_hp": 70,
		"base_attack": 8,
		"base_defense": 0,
		"base_block": 3,
		"resource": "focus",
		"first_skill": "precise_shot"
	}
}

const SKILLS := {
	"heavy_slash": {"name": "重劈", "class": "warrior", "type": "attack", "cost": 2, "multiplier": 2.25, "hits": 1},
	"shield_wall": {"name": "盾墙", "class": "warrior", "type": "defense", "cost": 2, "multiplier": 2.40},
	"counter_stance": {"name": "反击架势", "class": "warrior", "type": "stance", "cost": 2, "block_multiplier": 1.20, "counter_multiplier": 1.35},
	"war_cry": {"name": "战吼", "class": "warrior", "type": "buff", "cost": 2, "attack_multiplier": 1.25},
	"precise_shot": {"name": "精准射击", "class": "archer", "type": "attack", "cost": 2, "multiplier": 2.10, "hits": 1},
	"quick_shot": {"name": "连珠箭", "class": "archer", "type": "attack", "cost": 2, "multiplier": 1.20, "hits": 2},
	"hunter_mark": {"name": "猎人标记", "class": "archer", "type": "debuff", "cost": 2, "mark_multiplier": 1.35},
	"roll": {"name": "翻滚", "class": "archer", "type": "dodge", "cost": 2, "block_multiplier": 1.20, "dodge_layers": 1},
	"first_aid": {"name": "急救", "class": "common", "type": "heal", "cost": 2, "heal_multiplier": 0.25},
	"tactical_retreat": {"name": "战术后撤", "class": "common", "type": "dodge", "cost": 2, "block_multiplier": 0.90, "dodge_layers": 1}
}

const EQUIPMENT := {
	"warrior_training_helm": {"class": "warrior", "slot": "head", "name": "训练铁盔", "hp": 5, "attack": 0, "armor": 1, "block": 1},
	"warrior_old_chest": {"class": "warrior", "slot": "body", "name": "旧胸甲", "hp": 7, "attack": 0, "armor": 1, "block": 2},
	"warrior_soldier_belt": {"class": "warrior", "slot": "waist", "name": "士兵腰带", "hp": 4, "attack": 0, "armor": 0, "block": 1},
	"warrior_practice_greaves": {"class": "warrior", "slot": "legs", "name": "练习腿裤", "hp": 5, "attack": 0, "armor": 1, "block": 1},
	"warrior_cloth_gloves": {"class": "warrior", "slot": "hands", "name": "粗布手套", "hp": 2, "attack": 0, "armor": 0, "block": 0},
	"warrior_old_leggings": {"class": "warrior", "slot": "leggings", "name": "旧护腿", "hp": 4, "attack": 0, "armor": 1, "block": 1},
	"warrior_march_boots": {"class": "warrior", "slot": "feet", "name": "行军靴", "hp": 3, "attack": 0, "armor": 0, "block": 0},
	"warrior_training_sword": {"class": "warrior", "slot": "weapon", "name": "训练剑", "hp": 0, "attack": 4, "armor": 0, "block": 0},
	"warrior_wooden_shield": {"class": "warrior", "slot": "offhand", "name": "木盾", "hp": 0, "attack": 0, "armor": 2, "block": 2},
	"archer_practice_hood": {"class": "archer", "slot": "head", "name": "练习兜帽", "hp": 4, "attack": 1, "armor": 0, "block": 1},
	"archer_old_leather": {"class": "archer", "slot": "body", "name": "旧皮甲", "hp": 6, "attack": 0, "armor": 1, "block": 1},
	"archer_hunter_belt": {"class": "archer", "slot": "waist", "name": "猎人腰带", "hp": 4, "attack": 0, "armor": 0, "block": 1},
	"archer_light_pants": {"class": "archer", "slot": "legs", "name": "轻便护裤", "hp": 5, "attack": 0, "armor": 1, "block": 1},
	"archer_bracers": {"class": "archer", "slot": "hands", "name": "射手护腕", "hp": 2, "attack": 0, "armor": 0, "block": 0},
	"archer_soft_leggings": {"class": "archer", "slot": "leggings", "name": "软皮绑腿", "hp": 3, "attack": 0, "armor": 1, "block": 1},
	"archer_light_boots": {"class": "archer", "slot": "feet", "name": "轻便靴", "hp": 2, "attack": 0, "armor": 0, "block": 0},
	"archer_practice_bow": {"class": "archer", "slot": "weapon", "name": "练习弓", "hp": 0, "attack": 3, "armor": 0, "block": 0},
	"archer_simple_quiver": {"class": "archer", "slot": "offhand", "name": "简易箭袋", "hp": 0, "attack": 2, "armor": 1, "block": 2}
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
	{"id": "tutorial_01", "type": "normal", "name": "训练腐鼠", "units": [{"name": "训练腐鼠", "rank": "normal", "hp": 22, "attack": 5, "defense": 0, "traits": []}]},
	{"id": "tutorial_02", "type": "normal", "name": "迟缓守卫", "units": [{"name": "迟缓守卫", "rank": "normal", "hp": 34, "attack": 5, "defense": 1, "traits": []}]},
	{"id": "tutorial_03", "type": "normal", "name": "投石哥布林", "units": [{"name": "投石哥布林", "rank": "normal", "hp": 36, "attack": 6, "defense": 1, "traits": []}]},
	{"id": "tutorial_04", "type": "elite", "name": "盾卫学徒", "units": [{"name": "盾卫学徒", "rank": "elite", "hp": 34, "attack": 6, "defense": 3, "traits": ["guard"]}]},
	{"id": "tutorial_05", "type": "normal", "name": "哥布林二人队", "units": [{"name": "哥布林矛手", "rank": "normal", "hp": 18, "attack": 4, "defense": 0, "traits": []}, {"name": "哥布林投石手", "rank": "normal", "hp": 18, "attack": 4, "defense": 0, "traits": []}]},
	{"id": "tutorial_06", "type": "normal", "name": "毒尾幼鼠", "units": [{"name": "毒尾幼鼠", "rank": "normal", "hp": 34, "attack": 6, "defense": 1, "traits": ["corrode"]}]},
	{"id": "tutorial_07", "type": "normal", "name": "影贼学徒", "units": [{"name": "影贼学徒", "rank": "normal", "hp": 34, "attack": 6, "defense": 1, "traits": ["first_strike"]}]},
	{"id": "tutorial_08", "type": "elite", "name": "铁甲训练官", "units": [{"name": "铁甲训练官", "rank": "elite", "hp": 48, "attack": 7, "defense": 4, "traits": ["thick_skin"]}]},
	{"id": "tutorial_09", "type": "normal", "name": "术士残影", "units": [{"name": "术士残影", "rank": "normal", "hp": 34, "attack": 6, "defense": 2, "traits": ["summon"]}, {"name": "残影仆从", "rank": "normal", "hp": 18, "attack": 4, "defense": 0, "traits": ["support"]}]},
	{"id": "tutorial_10", "type": "boss", "name": "试炼守门人", "units": [{"name": "试炼守门人", "rank": "boss", "hp": 74, "attack": 7, "defense": 4, "traits": ["phase"]}]}
]

const NORMAL_UNITS := [
	{"id": "normal_rat_01", "name": "腐鼠", "hp": 0.75, "attack": 0.90, "defense": 0.60, "traits": ["swarm"]},
	{"id": "normal_rat_02", "name": "尖牙鼠", "hp": 0.80, "attack": 1.05, "defense": 0.60, "traits": ["claw"]},
	{"id": "normal_guard_01", "name": "生锈守卫", "hp": 1.10, "attack": 0.75, "defense": 1.30, "traits": ["thick_skin", "tank", "taunt"]},
	{"id": "normal_guard_03", "name": "矛卫", "hp": 0.95, "attack": 1.00, "defense": 1.10, "traits": ["break_armor", "tank"]},
	{"id": "normal_shadow_01", "name": "影贼", "hp": 0.75, "attack": 1.05, "defense": 0.70, "traits": ["first_strike", "evade", "cunning"]},
	{"id": "normal_shadow_02", "name": "暗弩手", "hp": 0.80, "attack": 1.15, "defense": 0.70, "traits": ["mark", "backline", "cunning"]},
	{"id": "normal_caster_01", "name": "学徒术士", "hp": 0.80, "attack": 0.90, "defense": 0.80, "traits": ["curse"]},
	{"id": "normal_mutant_02", "name": "晶刺兽", "hp": 0.95, "attack": 1.05, "defense": 0.95, "traits": ["break_armor"]}
]

const ELITE_UNITS := [
	{"id": "elite_rat_01", "name": "鼠群头目", "hp": 0.95, "attack": 1.05, "defense": 0.80, "traits": ["swarm", "summon"]},
	{"id": "elite_guard_01", "name": "铁甲队长", "hp": 1.20, "attack": 0.95, "defense": 1.50, "traits": ["guard", "fortify", "tank", "taunt"]},
	{"id": "elite_shadow_01", "name": "暗影猎长", "hp": 0.90, "attack": 1.25, "defense": 0.90, "traits": ["first_strike", "mark", "cunning"]},
	{"id": "elite_caster_01", "name": "深塔祭司", "hp": 1.00, "attack": 1.00, "defense": 1.00, "traits": ["curse", "summon"]},
	{"id": "elite_mutant_01", "name": "裂塔巨兽", "hp": 1.35, "attack": 1.00, "defense": 1.25, "traits": ["thick_skin", "revive"]}
]

const BOSS_UNITS := [
	{"id": "boss_rat_king", "name": "腐巢鼠王", "hp": 1.00, "attack": 1.10, "defense": 0.90, "traits": ["swarm", "summon", "enrage"]},
	{"id": "boss_iron_warden", "name": "铁狱典狱长", "hp": 1.25, "attack": 1.00, "defense": 1.45, "traits": ["thick_skin", "guard", "fortify"]},
	{"id": "boss_shadow_duke", "name": "夜幕公爵", "hp": 0.95, "attack": 1.30, "defense": 1.00, "traits": ["first_strike", "evade", "mark", "cunning"]},
	{"id": "boss_deep_oracle", "name": "深塔预言者", "hp": 1.05, "attack": 1.10, "defense": 1.20, "traits": ["curse", "spell_shield", "summon"]},
	{"id": "boss_tower_core", "name": "裂塔核心", "hp": 1.20, "attack": 1.20, "defense": 1.20, "traits": ["revive", "charge", "split"]}
]


static func get_state_weight_total() -> int:
	var total := 0
	for card in STATE_CARDS.values():
		total += int(card["weight"])
	return total


static func get_floor_battle_type(index: int) -> String:
	return BATTLE_TYPES[index - 1]


static func external_table(table_name: String) -> Dictionary:
	var repository := DataRepository.new()
	return repository.table(table_name)


static func external_catalog_version() -> int:
	var repository := DataRepository.new()
	return repository.version()


static func external_catalog_tables() -> Array[String]:
	var repository := DataRepository.new()
	return repository.available_tables()
