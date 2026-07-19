extends RefCounted
class_name DataCatalog

const DataRepository = preload("res://scripts/core/data_repository.gd")

const BATTLE_TYPES := ["normal", "normal", "normal", "elite", "normal", "normal", "normal", "elite", "normal", "boss"]

const ENERGY_MAX := 60
const ENERGY_START := 0
const ATTACK_ENERGY := 4
const DEFEND_ENERGY := 3
const DODGE_ENERGY := 2

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
		"first_skill": "po_jun"
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
		"po_jun": {"name": "破军", "class": "warrior", "type": "attack", "slot": 1, "energy_cost": 8, "cooldown": 0, "multiplier": 2.00, "hits": 1, "armor_reduce": 0.30, "damage_type": "physical", "actions": [{"type": "modify_armor", "target": "selected", "multiplier": 0.70}, {"type": "damage", "target": "selected", "multiplier": 2.00, "hits": 1, "damage_type": "physical"}]},
		"heng_sao": {"name": "横扫", "class": "warrior", "type": "attack", "slot": 1, "energy_cost": 9, "cooldown": 0, "multiplier": 1.80, "hits": 1, "splash": true, "damage_type": "physical", "actions": [{"type": "damage", "target": "selected", "multiplier": 1.80, "hits": 1, "damage_type": "physical"}, {"type": "damage", "target": "adjacent", "multiplier": 1.80, "hits": 1, "damage_type": "physical", "repeat_with_charge": false, "include_extra_hits": false}]},
		"tiao_zhan": {"name": "挑斩", "class": "warrior", "type": "attack", "slot": 1, "energy_cost": 10, "cooldown": 0, "multiplier": 2.00, "hits": 1, "interrupt": true, "damage_type": "physical", "actions": [{"type": "damage", "target": "selected", "multiplier": 2.00, "hits": 1, "damage_type": "physical"}, {"type": "interrupt", "target": "selected"}]},
		"zhong_kan": {"name": "重砍", "class": "warrior", "type": "attack", "slot": 1, "energy_cost": 9, "cooldown": 0, "multiplier": 2.20, "hits": 1, "weaken_multiplier": 0.70, "damage_type": "physical", "actions": [{"type": "damage", "target": "selected", "multiplier": 2.20, "hits": 1, "damage_type": "physical"}, {"type": "apply_status", "target": "selected", "status": {"id": "zhong_kan", "name": "重砍", "kind": "debuff", "stack": "replace", "effects": [{"stat": "attack", "type": "multiply", "value": 0.70}], "duration": 2}}]},
	"shield_wall": {"name": "盾墙", "class": "warrior", "type": "defense", "slot": 3, "energy_cost": 18, "cooldown": 0, "multiplier": 2.40, "actions": [{"type": "gain_block", "target": "self", "stat": "block_power", "multiplier": 2.40, "skill_bonus_stat": "defense", "charge_tag": "defense", "apply_defense_charge": true}]},
	"counter_stance": {"name": "反击架势", "class": "warrior", "type": "stance", "slot": 3, "energy_cost": 18, "cooldown": 0, "block_multiplier": 1.20, "counter_multiplier": 1.35, "actions": [{"type": "gain_block", "target": "self", "stat": "block_power", "multiplier": 1.20, "skill_bonus_stat": "defense", "charge_tag": "defense", "apply_defense_charge": true}, {"type": "set_counter_attack", "target": "self", "charges": 1, "multiplier": 1.35, "skill_bonus_stat": "attack"}]},
	"battle_cry": {"name": "战吼", "class": "warrior", "type": "buff", "slot": 3, "energy_cost": 15, "cooldown": 0, "duration": 5, "effects": [{"stat": "attack", "type": "multiply", "value": 1.30}, {"stat": "damage_taken", "type": "multiply", "value": 0.70}], "tick_effects": [{"stat": "hp", "type": "percent", "value": 0.05}], "actions": [{"type": "apply_status", "target": "self", "status": {"id": "battle_cry", "name": "战吼", "kind": "buff", "stack": "replace", "effects": [{"stat": "attack", "type": "multiply", "value": 1.30, "skill_bonus_stat": "attack"}, {"stat": "damage_taken", "type": "multiply", "value": 0.70}], "tick_effects": [{"stat": "hp", "type": "percent", "value": 0.05}], "duration": 5}}]},
	"fury": {"name": "狂怒", "class": "warrior", "type": "buff", "slot": 3, "energy_cost": 16, "cooldown": 0, "duration": 5, "effects": [{"stat": "attack", "type": "multiply", "value": 2.00}, {"stat": "damage_taken", "type": "multiply", "value": 1.30}], "tick_effects": [{"stat": "hp", "type": "percent", "value": -0.05}], "actions": [{"type": "apply_status", "target": "self", "status": {"id": "fury", "name": "狂怒", "kind": "buff", "stack": "replace", "effects": [{"stat": "attack", "type": "multiply", "value": 2.00, "skill_bonus_stat": "attack"}, {"stat": "damage_taken", "type": "multiply", "value": 1.30}], "tick_effects": [{"stat": "hp", "type": "percent", "value": -0.05}], "duration": 5}}]},
	"iron_stance": {"name": "钢铁姿态", "class": "warrior", "type": "buff", "slot": 3, "energy_cost": 15, "cooldown": 0, "duration": 4, "effects": [{"stat": "armor", "type": "multiply", "value": 2.00}, {"stat": "damage_taken", "type": "multiply", "value": 0.50}], "reflect_multiplier": 0.50, "actions": [{"type": "apply_status", "target": "self", "status": {"id": "iron_stance", "name": "钢铁姿态", "kind": "buff", "stack": "replace", "effects": [{"stat": "armor", "type": "multiply", "value": 2.00}, {"stat": "damage_taken", "type": "multiply", "value": 0.50}], "reflect_multiplier": 0.50, "duration": 4}}]},
	"quick_prep": {"name": "快速准备", "class": "warrior", "type": "buff", "slot": 3, "energy_cost": 14, "cooldown": 0, "duration": 8, "effects": [{"stat": "extra_hits", "type": "flat", "value": 1}, {"stat": "energy_cost", "type": "flat", "value": -3}, {"stat": "cooldown", "type": "flat", "value": -1}], "actions": [{"type": "apply_status", "target": "self", "status": {"id": "quick_prep", "name": "快速准备", "kind": "buff", "stack": "replace", "effects": [{"stat": "extra_hits", "type": "flat", "value": 1}, {"stat": "energy_cost", "type": "flat", "value": -3}, {"stat": "cooldown", "type": "flat", "value": -1}], "duration": 8}}]},
	"war_cry": {"name": "战吼", "class": "warrior", "type": "buff", "slot": 4, "energy_cost": 0, "cooldown": 3, "attack_multiplier": 1.25, "actions": [{"type": "apply_status", "target": "self", "status": {"id": "war_cry", "name": "战吼", "kind": "buff", "stack": "replace", "effects": [{"stat": "attack", "type": "multiply", "value": 1.25, "skill_bonus_stat": "attack"}], "duration": -1}}]},
	"adrenaline": {"name": "肾上腺素", "class": "warrior", "type": "buff", "slot": 4, "energy_cost": 0, "cooldown": 20, "duration": 5, "effects": [{"stat": "attack", "type": "multiply", "value": 2.00}, {"stat": "damage_taken", "type": "multiply", "value": 0.50}], "tick_effects": [{"stat": "energy", "type": "flat", "value": 5}], "deferred_damage_percent": 0.30, "actions": [{"type": "apply_status", "target": "self", "status": {"id": "adrenaline", "name": "肾上腺素", "kind": "buff", "stack": "replace", "effects": [{"stat": "attack", "type": "multiply", "value": 2.00, "skill_bonus_stat": "attack"}, {"stat": "damage_taken", "type": "multiply", "value": 0.50}], "tick_effects": [{"stat": "energy", "type": "flat", "value": 5}], "deferred_damage_percent": 0.30, "duration": 5}}]},
		"iron_blood_reckoning": {"name": "铁血清算", "class": "warrior", "type": "attack", "slot": 4, "energy_cost": 0, "cooldown": 19, "multiplier": 5.00, "hits": 1, "aoe": true, "heal_percent": 0.50, "clear_debuffs": true, "dot_multiplier": 1.00, "dot_duration": 5, "damage_type": "physical", "actions": [{"type": "damage", "target": "all_enemies", "multiplier": 5.00, "hits": 1, "damage_type": "physical"}, {"type": "heal", "target": "self", "stat": "attack", "multiplier": 2.50}, {"type": "clear_debuffs", "target": "self"}, {"type": "apply_status", "target": "all_enemies", "status": {"id": "iron_blood_reckoning_dot", "name": "铁血清算 DOT", "kind": "debuff", "stack": "replace", "tick_effects": [{"stat": "hp", "type": "flat", "source_stat": "attack", "source_multiplier": 1.00, "negative": true}], "duration": 5}}]},
	"duel_domain": {"name": "单挑领域", "class": "warrior", "type": "duel", "slot": 4, "energy_cost": 0, "cooldown": 18, "attack_multiplier": 2.00, "actions": [{"type": "set_duel", "target": "selected", "multiplier": 2.00, "duration": -1}]},
	"force_deflection": {"name": "力拨千斤", "class": "warrior", "type": "deflect", "slot": 4, "energy_cost": 0, "cooldown": 20, "actions": [{"type": "set_deflect", "target": "self"}]},
			"explosive_strike": {"name": "爆裂猛击", "class": "warrior", "type": "attack", "slot": 2, "energy_cost": 19, "cooldown": 0, "multiplier": 6.80, "hits": 1, "splash": true, "splash_multiplier": 1.00, "self_block_multiplier": 1.00, "damage_type": "physical", "actions": [{"type": "damage", "target": "selected", "multiplier": 6.80, "hits": 1, "damage_type": "physical"}, {"type": "damage", "target": "adjacent", "multiplier": 6.80, "hits": 1, "damage_type": "physical", "repeat_with_charge": false, "include_extra_hits": false}, {"type": "gain_block", "target": "self", "stat": "block_power", "multiplier": 1.00}]},
			"counter_storm": {"name": "反击风暴", "class": "warrior", "type": "attack", "slot": 2, "energy_cost": 21, "cooldown": 0, "multiplier": 2.00, "hits": 2, "aoe": true, "counter_attack_multiplier": 0.80, "counter_charges": 1, "damage_type": "physical", "actions": [{"type": "damage", "target": "all_enemies", "multiplier": 2.00, "hits": 2, "damage_type": "physical"}, {"type": "set_counter_attack", "target": "self", "charges": 1, "multiplier": 0.80}]},
			"shattering_blow": {"name": "碎裂斩", "class": "warrior", "type": "attack", "slot": 2, "energy_cost": 22, "cooldown": 0, "armor_reduce": 0.75, "multiplier": 3.00, "hits": 1, "aoe_multiplier": 2.00, "damage_type": "physical", "actions": [{"type": "modify_armor", "target": "selected", "multiplier": 0.25}, {"type": "damage", "target": "selected", "multiplier": 3.00, "hits": 1, "damage_type": "physical"}, {"type": "damage", "target": "all_enemies", "multiplier": 2.00, "hits": 1, "damage_type": "physical", "repeat_with_charge": false, "include_extra_hits": false}]},
			"vacuum_slash": {"name": "真空斩", "class": "warrior", "type": "attack", "slot": 2, "energy_cost": 21, "cooldown": 0, "multiplier": 5.00, "hits": 1, "damage_type": "true", "weaken_multiplier": 0.60, "actions": [{"type": "damage", "target": "selected", "multiplier": 5.00, "hits": 1, "damage_type": "true"}, {"type": "apply_status", "target": "selected", "status": {"id": "vacuum_slash", "name": "真空斩", "kind": "debuff", "stack": "replace", "effects": [{"stat": "attack", "type": "multiply", "value": 0.60}], "duration": 2}}]},
		"precise_shot": {"name": "精准射击", "class": "archer", "type": "attack", "slot": 1, "energy_cost": 12, "cooldown": 0, "multiplier": 2.10, "hits": 1, "armor_reduce": 0.30, "damage_type": "physical", "actions": [{"type": "modify_armor", "target": "selected", "multiplier": 0.70}, {"type": "damage", "target": "selected", "multiplier": 2.10, "hits": 1, "damage_type": "physical"}]},
		"quick_shot": {"name": "连珠箭", "class": "archer", "type": "attack", "slot": 2, "energy_cost": 30, "cooldown": 0, "multiplier": 0.60, "hits": 4, "damage_type": "physical", "actions": [{"type": "damage", "target": "selected", "multiplier": 0.60, "hits": 4, "damage_type": "physical"}]},
	"hunter_mark": {"name": "猎人标记", "class": "archer", "type": "debuff", "slot": 3, "energy_cost": 18, "cooldown": 0, "mark_multiplier": 1.35, "weaken_multiplier": 0.75, "actions": [{"type": "apply_status", "target": "selected", "status": {"id": "hunter_mark", "name": "猎人标记", "kind": "debuff", "stack": "replace", "effects": [{"stat": "damage_taken", "type": "multiply", "value": 1.35, "skill_bonus_stat": "attack"}, {"stat": "attack", "type": "multiply", "value": 0.75}], "duration": -1}}]},
	"roll": {"name": "翻滚", "class": "archer", "type": "dodge", "slot": 4, "energy_cost": 0, "cooldown": 3, "block_multiplier": 1.20, "dodge_layers": 1, "actions": [{"type": "gain_dodge", "target": "self", "layers": 1, "double_with_state": "read"}, {"type": "gain_block", "target": "self", "stat": "block_power", "multiplier": 1.20, "skill_bonus_stat": "defense", "repeat_with_charge": false}]},
	"first_aid": {"name": "急救", "class": "common", "type": "heal", "slot": 3, "energy_cost": 18, "cooldown": 0, "heal_multiplier": 0.25, "actions": [{"type": "heal", "target": "ally_selected", "stat": "max_hp", "multiplier": 0.25, "skill_bonus_stat": "hp"}]},
	"tactical_retreat": {"name": "战术后撤", "class": "common", "type": "dodge", "slot": 4, "energy_cost": 0, "cooldown": 3, "block_multiplier": 0.90, "dodge_layers": 1, "actions": [{"type": "gain_dodge", "target": "self", "layers": 1, "double_with_state": "read"}, {"type": "gain_block", "target": "self", "stat": "block_power", "multiplier": 0.90, "skill_bonus_stat": "defense", "repeat_with_charge": false}]},
	"enemy_heavy_strike": {"name": "重击", "class": "enemy", "type": "attack", "slot": 0, "energy_cost": 0, "cooldown": 0, "multiplier": 1.50, "hits": 1, "damage_type": "physical"},
	"enemy_rend": {"name": "撕裂", "class": "enemy", "type": "attack", "slot": 0, "energy_cost": 0, "cooldown": 0, "multiplier": 0.70, "hits": 2, "damage_type": "physical"},
	"enemy_fortify": {"name": "固守", "class": "enemy", "type": "defense", "slot": 0, "energy_cost": 0, "cooldown": 0, "multiplier": 1.50},
	"enemy_enrage": {"name": "狂怒", "class": "enemy", "type": "buff", "slot": 0, "energy_cost": 0, "cooldown": 0, "attack_multiplier": 1.30},
	"enemy_weaken": {"name": "虚弱凝视", "class": "enemy", "type": "debuff", "slot": 0, "energy_cost": 0, "cooldown": 0, "weaken_multiplier": 0.80},
	"enemy_quick_evade": {"name": "迅捷闪避", "class": "enemy", "type": "dodge", "slot": 0, "energy_cost": 0, "cooldown": 0, "dodge_layers": 1},
	"enemy_dark_bolt": {"name": "暗影弹", "class": "enemy", "type": "attack", "slot": 0, "energy_cost": 0, "cooldown": 0, "multiplier": 1.20, "hits": 1, "damage_type": "shadow"},
		"enemy_taunt": {"name": "嘲讽", "class": "enemy", "type": "taunt", "slot": 0, "energy_cost": 0, "cooldown": 0, "taunt_duration": 1}
}

const INNATE_SKILLS := {
	"innate_attack_1": {"name": "普通攻击", "type": "attack", "multiplier": 1.0, "hits": 1, "damage_type": "physical", "energy_gain": 4},
	"innate_attack_2": {"name": "攻击·贰", "type": "attack", "multiplier": 1.0, "hits": 1, "damage_type": "physical", "energy_gain": 4},
	"innate_attack_3": {"name": "攻击·叁", "type": "attack", "multiplier": 1.0, "hits": 1, "damage_type": "physical", "energy_gain": 4},
	"innate_attack_4": {"name": "攻击·肆", "type": "attack", "multiplier": 1.0, "hits": 1, "damage_type": "physical", "energy_gain": 4},
	"ranger_flurry": {"name": "游侠连射", "type": "attack", "multiplier": 0.3, "hits": 4, "damage_type": "physical", "energy_gain": 4},
	"innate_defend": {"name": "防御", "type": "defense", "multiplier": 1.0, "energy_gain": 3},
	"innate_dodge": {"name": "闪避", "type": "dodge", "dodge_layers": 1, "energy_gain": 2}
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
	"archer_simple_quiver": {"class": "archer", "slot": "offhand", "name": "简易箭袋", "hp": 0, "attack": 2, "armor": 1, "block": 2},
	"common_moon_necklace": {"class": "common", "slot": "necklace", "name": "清辉", "hp": 3, "attack": 0, "armor": 0, "block": 1, "set_id": "moon_pair"},
	"common_moon_ring": {"class": "common", "slot": "ring", "name": "流霜", "hp": 2, "attack": 1, "armor": 0, "block": 1, "set_id": "moon_pair"},
	"sparta_damascus_sword": {"class": "warrior", "slot": "weapon", "name": "大马士革钢刀", "hp": 0, "attack": 5, "armor": 0, "block": 0, "set_id": "sparta"},
	"sparta_shield": {"class": "warrior", "slot": "offhand", "name": "斯巴达盾", "hp": 2, "attack": 0, "armor": 2, "block": 2, "set_id": "sparta"},
	"sparta_chest": {"class": "warrior", "slot": "body", "name": "斯巴达胸甲", "hp": 8, "attack": 0, "armor": 1, "block": 2, "set_id": "sparta"},
	"sparta_helm": {"class": "warrior", "slot": "head", "name": "斯巴达头盔", "hp": 5, "attack": 0, "armor": 1, "block": 1, "set_id": "sparta"},
	"sparta_greaves": {"class": "warrior", "slot": "leggings", "name": "斯巴达护胫", "hp": 5, "attack": 0, "armor": 1, "block": 1, "set_id": "sparta"},
	"sparta_boots": {"class": "warrior", "slot": "feet", "name": "斯巴达鞋", "hp": 3, "attack": 0, "armor": 0, "block": 1, "set_id": "sparta"},
	"boxer_belt": {"class": "warrior", "slot": "waist", "name": "冠军腰带", "hp": 4, "attack": 2, "armor": 0, "block": 1, "set_id": "boxer"},
	"boxer_pants": {"class": "warrior", "slot": "legs", "name": "拳击裤", "hp": 5, "attack": 1, "armor": 1, "block": 1, "set_id": "boxer"},
	"boxer_gloves": {"class": "warrior", "slot": "hands", "name": "拳击手套", "hp": 2, "attack": 3, "armor": 0, "block": 0, "set_id": "boxer"},
	"circus_whip": {"class": "common", "slot": "weapon", "name": "鞭子", "hp": 0, "attack": 4, "armor": 0, "block": 0, "set_id": "circus"},
	"circus_torch": {"class": "common", "slot": "offhand", "name": "火把", "hp": 3, "attack": 1, "armor": 0, "block": 1, "set_id": "circus"},
	"circus_mask": {"class": "common", "slot": "head", "name": "小丑面具", "hp": 4, "attack": 0, "armor": 1, "block": 1, "set_id": "circus"},
	"circus_gloves": {"class": "common", "slot": "hands", "name": "杂技手套", "hp": 2, "attack": 2, "armor": 0, "block": 0, "set_id": "circus"},
	"jungle_bow": {"class": "archer", "slot": "weapon", "name": "丛林弓", "hp": 0, "attack": 5, "armor": 0, "block": 0, "set_id": "jungle"},
	"jungle_knife": {"class": "archer", "slot": "offhand", "name": "剥皮刀", "hp": 2, "attack": 2, "armor": 0, "block": 0, "set_id": "jungle"},
	"jungle_hat": {"class": "archer", "slot": "head", "name": "草帽", "hp": 4, "attack": 0, "armor": 1, "block": 1, "set_id": "jungle"},
	"jungle_vest": {"class": "archer", "slot": "body", "name": "树叶衣", "hp": 5, "attack": 0, "armor": 1, "block": 1, "set_id": "jungle"},
	"jungle_pants": {"class": "archer", "slot": "legs", "name": "树叶裤", "hp": 5, "attack": 0, "armor": 1, "block": 1, "set_id": "jungle"},
	"jungle_gloves": {"class": "archer", "slot": "hands", "name": "编制手套", "hp": 2, "attack": 2, "armor": 0, "block": 0, "set_id": "jungle"},
	"ranger_hat": {"class": "archer", "slot": "head", "name": "游侠帽", "hp": 4, "attack": 0, "armor": 1, "block": 1, "set_id": "ranger"},
	"ranger_cape": {"class": "archer", "slot": "cape", "name": "游侠披风", "hp": 3, "attack": 0, "armor": 0, "block": 1, "set_id": "ranger"},
	"ranger_vest": {"class": "archer", "slot": "body", "name": "游侠紧身衣", "hp": 5, "attack": 0, "armor": 1, "block": 1, "set_id": "ranger"},
	"ranger_shoulder": {"class": "archer", "slot": "shoulder", "name": "游侠护肩", "hp": 3, "attack": 0, "armor": 1, "block": 1, "set_id": "ranger"},
	"ranger_belt": {"class": "archer", "slot": "waist", "name": "游侠腰带", "hp": 4, "attack": 0, "armor": 0, "block": 1, "set_id": "ranger"},
	"ranger_gloves": {"class": "archer", "slot": "hands", "name": "游侠护手", "hp": 2, "attack": 2, "armor": 0, "block": 0, "set_id": "ranger"}
}

const CONSUMABLES := {
	"minor_heal": {"name": "小型治疗剂", "desc": "战前携带的基础恢复品。", "kind": "heal", "value": 18},
	"iron_skin": {"name": "铁肤药剂", "desc": "战前携带的防护药剂。", "kind": "armor", "value": 2},
	"swift_step": {"name": "迅步药水", "desc": "战前携带的机动药水。", "kind": "dodge", "value": 1},
	"rage_draught": {"name": "狂怒药剂", "desc": "战前携带的进攻药剂。", "kind": "attack", "value": 3},
	"focus_tea": {"name": "凝神茶", "desc": "战前携带的专注饮品。", "kind": "skill", "value": 1},
	"emergency_kit": {"name": "应急包", "desc": "战前携带的保命工具。", "kind": "block", "value": 2}
}

const STARTER_CONSUMABLES := ["minor_heal", "iron_skin", "swift_step", "rage_draught", "focus_tea", "emergency_kit"]

const EQUIPMENT_SETS := {
	"moon_pair": {
		"name": "清辉流霜",
		"bonuses": {
			2: {"label": "其余 3 件套以上套装要求 -1。", "set_requirement_delta": 1}
		}
	},
	"sparta": {
		"name": "斯巴达",
		"bonuses": {
			2: {"label": "斯巴达气势：结算时增加 20% 伤害。", "modifiers": [{"stat": "attack", "type": "multiply", "value": 1.20, "priority": 300}]},
			4: {"label": "斯巴达战吼：降低所有敌人 20% 伤害，持续 3 回合。", "on_battle_start": [{"action": "weaken_enemies", "value": 0.20}]},
			6: {"label": "狂战血统：血量越低攻击越高，满血时无加成，30% 血量时攻击翻倍。", "modifiers": [{"stat": "attack", "type": "multiply", "value": "dynamic:berserker", "priority": 300}]}
		}
	},
	"boxer": {
		"name": "拳击手",
		"bonuses": {
			2: {"label": "专注：连续攻击同一敌人时，每次伤害提升 20%，切换敌人重置。", "modifiers": [{"stat": "attack", "type": "multiply", "value": "dynamic:focus_combo", "priority": 300}]},
			3: {"label": "KO：暴击 buff 下攻击造成 3 倍伤害。", "modifiers": [{"stat": "attack", "type": "multiply", "value": "dynamic:ko_critical", "priority": 300}]}
		}
	},
	"circus": {
		"name": "马戏团",
		"bonuses": {
			2: {"label": "杂耍：闪避成功时给攻击者追加100%攻击伤害。", "on_battle_start": [{"action": "apply_status", "status": {"id": "circus_juggling", "name": "杂耍", "kind": "buff", "duration": -1, "triggers": [{"event": "on_dodge", "actions": [{"type": "reflect", "target_stat": "attack", "target_ratio": 1.0}]}]}}]},
			4: {"label": "表演：连续两次闪避成功时，给全部敌人追加100%攻击的伤害。", "on_battle_start": [{"action": "apply_status", "status": {"id": "circus_performance", "name": "表演", "kind": "buff", "duration": -1, "triggers": [{"event": "on_dodge", "actions": [{"type": "counter_all", "threshold": 2, "target_stat": "attack", "target_ratio": 1.0}]}]}}]}
		}
	},
	"jungle": {
		"name": "丛林",
		"bonuses": {
			2: {"label": "缜密：每闪避成功一次，增加10%伤害，最多增加50%伤害。", "on_battle_start": [{"action": "apply_status", "status": {"id": "jungle_meticulous", "name": "缜密", "kind": "buff", "duration": -1, "triggers": [{"event": "on_dodge", "actions": [{"type": "increment_counter", "counter": "meticulous_stacks", "max": 5}]}, {"event": "on_hit_received", "actions": [{"type": "reset_counter", "counter": "meticulous_stacks"}]}]}}], "modifiers": [{"stat": "attack", "type": "multiply", "value": "dynamic:meticulous", "priority": 300}]},
			4: {"label": "寻绽：每个不攻击的回合增加30%伤害，最多增加90%伤害。", "on_battle_start": [{"action": "apply_status", "status": {"id": "jungle_seek_bloom", "name": "寻绽", "kind": "buff", "duration": -1, "triggers": [{"event": "on_turn_start", "condition": {"not_attacked_last_turn": true}, "actions": [{"type": "increment_counter", "counter": "seek_bloom_stacks", "max": 3}]}]}}], "modifiers": [{"stat": "attack", "type": "multiply", "value": "dynamic:seek_bloom", "priority": 300}]},
			6: {"label": "狩猎：缜密5层后追加50%伤害，寻绽3层后追加90%伤害。造成伤害后重置。", "on_battle_start": [{"action": "apply_status", "status": {"id": "jungle_hunt", "name": "狩猎", "kind": "buff", "duration": -1, "triggers": [{"event": "on_hit_dealt", "actions": [{"type": "reset_counter", "counter": "meticulous_stacks"}, {"type": "reset_counter", "counter": "seek_bloom_stacks"}]}]}}], "modifiers": [{"stat": "attack", "type": "multiply", "value": "dynamic:hunt", "priority": 300}]}
		}
	},
	"ranger": {
		"name": "游侠",
		"bonuses": {
			2: {"label": "攻防一体：普攻变为0.3×4次攻击，每攻击4次提供1层闪避。", "on_battle_start": [{"action": "set_innate_skill", "slot": "attack", "skill_id": "ranger_flurry"}, {"action": "apply_status", "status": {"id": "ranger_attack_defense", "name": "攻防一体", "kind": "buff", "duration": -1, "triggers": [{"event": "on_hit_dealt", "actions": [{"type": "increment_counter", "counter": "ranger_hit_count", "max": 999, "threshold": 4, "threshold_actions": [{"type": "gain_dodge", "value": 1}]}]}]}}]},
			4: {"label": "追击：攻击结束后，追加1倍攻击力×攻击段数的伤害。", "on_battle_start": [{"action": "apply_status", "status": {"id": "ranger_pursuit", "name": "追击", "kind": "buff", "duration": -1, "triggers": [{"event": "on_attack_complete", "actions": [{"type": "extra_damage", "source_stat": "attack", "source_ratio": 1.0, "counter": "ranger_hit_count", "damage_type": "true"}]}]}}]},
			6: {"label": "折返：闪避后对进攻方进行一次普攻反击（0.3×4段）。", "modifiers": [{"stat": "attack", "type": "multiply", "value": "dynamic:ranger_return", "priority": 302, "action_source": "counter_attack"}]}
		}
	}
}

const TUTORIAL_UNLOCKS := {
	"warrior": [
		"warrior_training_helm", "warrior_old_chest", "warrior_soldier_belt",
		"warrior_practice_greaves", "warrior_cloth_gloves", "warrior_old_leggings",
		"warrior_march_boots", "warrior_training_sword", "warrior_wooden_shield", "po_jun"
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
	{"id": "normal_rat_01", "name": "腐鼠", "hp": 0.75, "attack": 0.90, "defense": 0.60, "traits": ["swarm"], "skills": ["enemy_rend", "enemy_enrage"]},
	{"id": "normal_rat_02", "name": "尖牙鼠", "hp": 0.80, "attack": 1.05, "defense": 0.60, "traits": ["claw"], "skills": ["enemy_heavy_strike", "enemy_rend"]},
	{"id": "normal_guard_01", "name": "生锈守卫", "hp": 1.10, "attack": 0.75, "defense": 1.30, "traits": ["thick_skin", "tank", "taunt"], "skills": ["enemy_fortify", "enemy_taunt"]},
	{"id": "normal_guard_03", "name": "矛卫", "hp": 0.95, "attack": 1.00, "defense": 1.10, "traits": ["break_armor", "tank"], "skills": ["enemy_heavy_strike", "enemy_fortify"]},
	{"id": "normal_shadow_01", "name": "影贼", "hp": 0.75, "attack": 1.05, "defense": 0.70, "traits": ["first_strike", "evade", "cunning"], "skills": ["enemy_quick_evade", "enemy_rend"]},
	{"id": "normal_shadow_02", "name": "暗弩手", "hp": 0.80, "attack": 1.15, "defense": 0.70, "traits": ["mark", "backline", "cunning"], "skills": ["enemy_dark_bolt", "enemy_weaken"]},
	{"id": "normal_caster_01", "name": "学徒术士", "hp": 0.80, "attack": 0.90, "defense": 0.80, "traits": ["curse"], "skills": ["enemy_weaken", "enemy_dark_bolt"]},
	{"id": "normal_mutant_02", "name": "晶刺兽", "hp": 0.95, "attack": 1.05, "defense": 0.95, "traits": ["break_armor"], "skills": ["enemy_rend", "enemy_enrage"]}
]

const ELITE_UNITS := [
	{"id": "elite_rat_01", "name": "鼠群头目", "hp": 0.95, "attack": 1.05, "defense": 0.80, "traits": ["swarm", "summon"], "skills": ["enemy_rend", "enemy_enrage"]},
	{"id": "elite_guard_01", "name": "铁甲队长", "hp": 1.20, "attack": 0.95, "defense": 1.50, "traits": ["guard", "fortify", "tank", "taunt"], "skills": ["enemy_fortify", "enemy_heavy_strike", "enemy_taunt"]},
	{"id": "elite_shadow_01", "name": "暗影猎长", "hp": 0.90, "attack": 1.25, "defense": 0.90, "traits": ["first_strike", "mark", "cunning"], "skills": ["enemy_dark_bolt", "enemy_quick_evade"]},
	{"id": "elite_caster_01", "name": "深塔祭司", "hp": 1.00, "attack": 1.00, "defense": 1.00, "traits": ["curse", "summon"], "skills": ["enemy_weaken", "enemy_dark_bolt"]},
	{"id": "elite_mutant_01", "name": "裂塔巨兽", "hp": 1.35, "attack": 1.00, "defense": 1.25, "traits": ["thick_skin", "revive"], "skills": ["enemy_heavy_strike", "enemy_enrage"]}
]

const BOSS_UNITS := [
	{"id": "boss_rat_king", "name": "腐巢鼠王", "hp": 1.00, "attack": 1.10, "defense": 0.90, "traits": ["swarm", "summon", "enrage"], "skills": ["enemy_rend", "enemy_enrage", "enemy_heavy_strike"]},
	{"id": "boss_iron_warden", "name": "铁狱典狱长", "hp": 1.25, "attack": 1.00, "defense": 1.45, "traits": ["thick_skin", "guard", "fortify"], "skills": ["enemy_fortify", "enemy_heavy_strike", "enemy_enrage"]},
	{"id": "boss_shadow_duke", "name": "夜幕公爵", "hp": 0.95, "attack": 1.30, "defense": 1.00, "traits": ["first_strike", "evade", "mark", "cunning", "shadow_domain"], "skills": ["enemy_dark_bolt", "enemy_quick_evade", "enemy_weaken"]},
	{"id": "boss_deep_oracle", "name": "深塔预言者", "hp": 1.05, "attack": 1.10, "defense": 1.20, "traits": ["curse", "spell_shield", "summon", "toxic_mist"], "skills": ["enemy_weaken", "enemy_dark_bolt", "enemy_fortify"]},
	{"id": "boss_tower_core", "name": "裂塔核心", "hp": 1.20, "attack": 1.20, "defense": 1.20, "traits": ["revive", "charge", "split", "blood_moon"], "skills": ["enemy_heavy_strike", "enemy_enrage", "enemy_rend"]}
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
