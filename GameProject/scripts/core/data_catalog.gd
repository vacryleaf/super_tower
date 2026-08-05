extends RefCounted
class_name DataCatalog

const DataRepository = preload("res://scripts/core/data_repository.gd")

const BATTLE_TYPES := ["normal", "normal", "elite", "normal", "normal", "elite", "normal", "normal", "normal", "boss"]

const ENERGY_MAX := 60
const ENERGY_START := 0
const ATTACK_ENERGY := 4
const DEFEND_ENERGY := 2
const DODGE_ENERGY := 2
const MAX_TOWER_FLOOR := 7
const MAX_TOWER_BONUS := 6
const NORMAL_CONSUMABLE_SLOTS := 3
const TOWER_EQUIPMENT_SLOTS := 4
const TOWER_COIN_MULTIPLIERS := {"normal": 1, "elite": 3, "boss": 10}
const TOWER_EQUIPMENT_DROP_CHANCES := {"normal": 0.10, "elite": 0.50, "boss": 1.00}
const TOWER_CONSUMABLE_DROP_CHANCE := 0.20
const PERMANENT_EQUIPMENT_PRICE := 20
const PERMANENT_SKILL_PRICE := 15

const BLOOD_POTION := {
	"id": "blood_potion",
	"name": "血瓶",
	"starting_uses": 3,
	"heal_ratio": 0.30,
	"level_heal_ratio": 0.05
}

const NPCS := {
	"merchant": {"name": "商人", "unlock_boss_floor": 1, "upgrade_floor": 1, "upgrade_groups": 9, "upgrade_feature": "merchant_upgraded"},
	"blacksmith": {"name": "铁匠", "unlock_boss_floor": 3, "upgrade_floor": 3, "upgrade_groups": 7, "upgrade_feature": "blacksmith_upgraded"},
	"mage": {"name": "法师", "unlock_boss_floor": 5, "upgrade_floor": 5, "upgrade_groups": 5, "upgrade_feature": "mage_upgraded"}
}

const PASSIVE_SKILLS := {
	"iron_will": {"name": "坚韧", "effects": [{"stat": "max_hp", "type": "flat", "value": 8}]}
}

const WEAPON_PROFILES := {
	"unarmed": {"name": "空手", "agility": 15, "attack_damage": 2, "critical_weight": 20, "skill_1": "po_jun", "skill_2": "explosive_strike"},
	"short_sword": {"name": "匕首", "agility": 13, "attack_damage": 4, "critical_weight": 30, "skill_1": "weak_point_break", "skill_2": "backstab"},
	"long_sword": {"name": "剑", "agility": 11, "attack_damage": 7, "critical_weight": 10, "skill_1": "tiao_zhan", "skill_2": "shattering_blow"},
	"short_bow": {"name": "弓", "agility": 11, "attack_damage": 6, "critical_weight": 15, "skill_1": "precise_shot", "skill_2": "quick_shot"},
	"hand_crossbow": {"name": "弩", "agility": 9, "attack_damage": 10, "critical_weight": 0, "skill_1": "quick_strike", "skill_2": "backstab"},
	"hand_axe": {"name": "斧", "agility": 8, "attack_damage": 10, "critical_weight": 0, "skill_1": "zhong_kan", "skill_2": "vacuum_slash"},
	"one_hand_hammer": {"name": "锤", "agility": 7, "attack_damage": 12, "critical_weight": 0, "skill_1": "weak_point_break", "skill_2": "backstab"},
	"whip": {"name": "鞭子", "agility": 13, "attack_damage": 6, "critical_weight": 15, "skill_1": "quick_strike", "skill_2": "hunter_mark"}
}

const WEAPON_ITEM_PROFILES := {
	"warrior_training_sword": "long_sword",
	"archer_practice_bow": "short_bow",
	"sparta_damascus_sword": "short_sword",
	"jungle_bow": "short_bow",
	"circus_whip": "whip"
}

const EQUIPMENT_SLOTS := ["weapon", "armor", "accessory", "offhand"]

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
	"unified": {
		"name": "探索者",
		"max_hp": 80,
		"base_attack": 7,
		"base_defense": 1,
		"base_block": 4,
		"resource": "adrenaline",
		"first_skill": "po_jun"
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
	"quick_shot": {"name": "连珠箭", "class": "archer", "type": "attack", "slot": 2, "energy_cost": 20, "cooldown": 0, "multiplier": 0.80, "hits": 7, "damage_type": "physical", "ignore_armor": 1.0, "actions": [{"type": "damage", "target": "selected", "multiplier": 0.80, "hits": 7, "damage_type": "physical", "ignore_armor": 1.0}]},
	"weak_point_break": {"name": "弱点击破", "class": "common", "type": "attack", "slot": 1, "energy_cost": 9, "cooldown": 0, "multiplier": 2.00, "hits": 1, "damage_type": "physical", "ignore_armor": 0.50, "actions": [{"type": "damage", "target": "selected", "multiplier": 2.00, "hits": 1, "damage_type": "physical", "ignore_armor": 0.50}]},
	"backstab": {"name": "背刺", "class": "common", "type": "attack", "slot": 2, "energy_cost": 20, "cooldown": 0, "multiplier": 6.00, "hits": 1, "damage_type": "physical", "ignore_armor": 1.0, "actions": [{"type": "damage", "target": "selected", "multiplier": 6.00, "hits": 1, "damage_type": "physical", "ignore_armor": 1.0}]},
	"quick_strike": {"name": "快速打击", "class": "common", "type": "attack", "slot": 1, "energy_cost": 9, "cooldown": 0, "multiplier": 1.00, "hits": 3, "damage_type": "physical", "actions": [{"type": "damage", "target": "selected", "multiplier": 1.00, "hits": 3, "damage_type": "physical"}]},
	"hunter_mark": {"name": "猎人标记", "class": "archer", "type": "debuff", "slot": 3, "energy_cost": 18, "cooldown": 0, "mark_multiplier": 1.35, "weaken_multiplier": 0.75, "actions": [{"type": "apply_status", "target": "selected", "status": {"id": "hunter_mark", "name": "猎人标记", "kind": "debuff", "stack": "replace", "effects": [{"stat": "damage_taken", "type": "multiply", "value": 1.35, "skill_bonus_stat": "attack"}, {"stat": "attack", "type": "multiply", "value": 0.75}], "duration": -1}}]},
	"roll": {"name": "翻滚", "class": "archer", "type": "dodge", "slot": 4, "energy_cost": 0, "cooldown": 3, "block_multiplier": 1.20, "dodge_layers": 1, "actions": [{"type": "gain_dodge", "target": "self", "layers": 1, "double_with_state": "read"}, {"type": "gain_block", "target": "self", "stat": "block_power", "multiplier": 1.20, "skill_bonus_stat": "defense", "repeat_with_charge": false}]},
	"first_aid": {"name": "急救", "class": "common", "type": "heal", "slot": 3, "energy_cost": 18, "cooldown": 0, "heal_multiplier": 0.25, "actions": [{"type": "heal", "target": "ally_selected", "stat": "max_hp", "multiplier": 0.25, "skill_bonus_stat": "hp"}]},
	"tactical_retreat": {"name": "战术后撤", "class": "common", "type": "dodge", "slot": 4, "energy_cost": 0, "cooldown": 3, "block_multiplier": 0.90, "dodge_layers": 1, "actions": [{"type": "gain_dodge", "target": "self", "layers": 1, "double_with_state": "read"}, {"type": "gain_block", "target": "self", "stat": "block_power", "multiplier": 0.90, "skill_bonus_stat": "defense", "repeat_with_charge": false}]},
	"enemy_heavy_strike": {"name": "重击", "class": "enemy", "type": "attack", "slot": 0, "energy_cost": 0, "cooldown": 0, "multiplier": 1.50, "hits": 1, "damage_type": "physical"},
	"enemy_pursuit": {"name": "追击", "class": "enemy", "type": "attack", "slot": 0, "energy_cost": 0, "cooldown": 3, "multiplier": 0.70, "hits": 2, "damage_type": "physical"},
	"enemy_call_rat_pack": {"name": "呼唤鼠群", "class": "enemy", "type": "summon", "slot": 0, "energy_cost": 0, "cooldown": 6},
	"enemy_bite": {"name": "撕咬", "class": "enemy", "type": "attack", "slot": 0, "energy_cost": 0, "cooldown": 5, "multiplier": 1.20, "hits": 1, "damage_type": "physical", "armor_reduction": 2},
	"enemy_rend": {"name": "撕裂", "class": "enemy", "type": "attack", "slot": 0, "energy_cost": 0, "cooldown": 0, "multiplier": 0.70, "hits": 2, "damage_type": "physical"},
	"enemy_fortify": {"name": "固守", "class": "enemy", "type": "defense", "slot": 0, "energy_cost": 0, "cooldown": 0, "multiplier": 1.50},
	"enemy_enrage": {"name": "狂暴", "class": "enemy", "type": "buff", "slot": 0, "energy_cost": 0, "cooldown": 6, "duration": 4, "attack_multiplier": 1.30},
	"enemy_weaken": {"name": "虚弱凝视", "class": "enemy", "type": "debuff", "slot": 0, "energy_cost": 0, "cooldown": 0, "weaken_multiplier": 0.80},
	"enemy_quick_evade": {"name": "迅捷闪避", "class": "enemy", "type": "dodge", "slot": 0, "energy_cost": 0, "cooldown": 0, "dodge_layers": 1},
	"enemy_dark_bolt": {"name": "暗影弹", "class": "enemy", "type": "attack", "slot": 0, "energy_cost": 0, "cooldown": 0, "multiplier": 1.20, "hits": 1, "damage_type": "shadow"},
	"enemy_shadow_armor": {"name": "暗影护甲", "class": "enemy", "type": "defense", "slot": 0, "energy_cost": 0, "cooldown": 5, "multiplier": 2.00},
	"enemy_taunt": {"name": "嘲讽", "class": "enemy", "type": "taunt", "slot": 0, "energy_cost": 0, "cooldown": 0, "taunt_duration": 1}
	,"enemy_skeleton_taunt": {"name": "嘲讽", "class": "enemy", "type": "taunt", "slot": 0, "energy_cost": 0, "cooldown": 4, "taunt_duration": 1, "block_multiplier": 1.50, "requires_living_ally": true}
	,"enemy_skeleton_heavy_strike": {"name": "重击", "class": "enemy", "type": "attack", "slot": 0, "energy_cost": 0, "cooldown": 4, "multiplier": 1.50, "hits": 1, "damage_type": "physical"}
	,"enemy_skeleton_fortify": {"name": "固守", "class": "enemy", "type": "defense", "slot": 0, "energy_cost": 0, "cooldown": 3, "multiplier": 2.00}
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
	"warrior_training_helm": {"class": "warrior", "slot": "armor", "name": "训练铁盔", "hp": 5, "attack": 0, "armor": 1, "block": 1},
	"warrior_old_chest": {"class": "warrior", "slot": "armor", "name": "旧胸甲", "hp": 7, "attack": 0, "armor": 1, "block": 2},
	"warrior_soldier_belt": {"class": "warrior", "slot": "armor", "name": "士兵腰带", "hp": 4, "attack": 0, "armor": 0, "block": 1},
	"warrior_practice_greaves": {"class": "warrior", "slot": "armor", "name": "练习腿裤", "hp": 5, "attack": 0, "armor": 1, "block": 1},
	"warrior_cloth_gloves": {"class": "warrior", "slot": "armor", "name": "粗布手套", "hp": 2, "attack": 0, "armor": 0, "block": 0},
	"warrior_old_leggings": {"class": "warrior", "slot": "armor", "name": "旧护腿", "hp": 4, "attack": 0, "armor": 1, "block": 1},
	"warrior_march_boots": {"class": "warrior", "slot": "armor", "name": "行军靴", "hp": 3, "attack": 0, "armor": 0, "block": 0},
	"warrior_training_sword": {"class": "warrior", "slot": "weapon", "name": "训练剑", "hp": 0, "attack": 4, "armor": 0, "block": 0},
	"warrior_wooden_shield": {"class": "warrior", "slot": "offhand", "name": "木盾", "hp": 0, "attack": 0, "armor": 2, "block": 2},
	"archer_practice_hood": {"class": "archer", "slot": "armor", "name": "练习兜帽", "hp": 4, "attack": 1, "armor": 0, "block": 1},
	"archer_old_leather": {"class": "archer", "slot": "armor", "name": "旧皮甲", "hp": 6, "attack": 0, "armor": 1, "block": 1},
	"archer_hunter_belt": {"class": "archer", "slot": "armor", "name": "猎人腰带", "hp": 4, "attack": 0, "armor": 0, "block": 1},
	"archer_light_pants": {"class": "archer", "slot": "armor", "name": "轻便护裤", "hp": 5, "attack": 0, "armor": 1, "block": 1},
	"archer_bracers": {"class": "archer", "slot": "armor", "name": "射手护腕", "hp": 2, "attack": 0, "armor": 0, "block": 0},
	"archer_soft_leggings": {"class": "archer", "slot": "armor", "name": "软皮绑腿", "hp": 3, "attack": 0, "armor": 1, "block": 1},
	"archer_light_boots": {"class": "archer", "slot": "armor", "name": "轻便靴", "hp": 2, "attack": 0, "armor": 0, "block": 0},
	"archer_practice_bow": {"class": "archer", "slot": "weapon", "name": "练习弓", "hp": 0, "attack": 3, "armor": 0, "block": 0},
	"archer_simple_quiver": {"class": "archer", "slot": "offhand", "name": "简易箭袋", "hp": 0, "attack": 2, "armor": 1, "block": 2},
	"common_moon_necklace": {"class": "common", "slot": "accessory", "name": "清辉", "hp": 3, "attack": 0, "armor": 0, "block": 1},
	"common_moon_ring": {"class": "common", "slot": "accessory", "name": "流霜", "hp": 2, "attack": 1, "armor": 0, "block": 1},
	"sparta_damascus_sword": {"class": "warrior", "slot": "weapon", "name": "大马士革钢刀", "hp": 0, "attack": 5, "armor": 0, "block": 0},
	"sparta_shield": {"class": "warrior", "slot": "offhand", "name": "斯巴达盾", "hp": 2, "attack": 0, "armor": 2, "block": 2},
	"sparta_chest": {"class": "warrior", "slot": "armor", "name": "斯巴达胸甲", "hp": 8, "attack": 0, "armor": 1, "block": 2},
	"sparta_helm": {"class": "warrior", "slot": "armor", "name": "斯巴达头盔", "hp": 5, "attack": 0, "armor": 1, "block": 1},
	"sparta_greaves": {"class": "warrior", "slot": "armor", "name": "斯巴达护胫", "hp": 5, "attack": 0, "armor": 1, "block": 1},
	"sparta_boots": {"class": "warrior", "slot": "armor", "name": "斯巴达鞋", "hp": 3, "attack": 0, "armor": 0, "block": 1},
	"boxer_belt": {"class": "warrior", "slot": "armor", "name": "冠军腰带", "hp": 4, "attack": 2, "armor": 0, "block": 1},
	"boxer_pants": {"class": "warrior", "slot": "armor", "name": "拳击裤", "hp": 5, "attack": 1, "armor": 1, "block": 1},
	"boxer_gloves": {"class": "warrior", "slot": "armor", "name": "拳击手套", "hp": 2, "attack": 3, "armor": 0, "block": 0},
	"circus_whip": {"class": "common", "slot": "weapon", "name": "鞭子", "hp": 0, "attack": 4, "armor": 0, "block": 0},
	"circus_torch": {"class": "common", "slot": "offhand", "name": "火把", "hp": 3, "attack": 1, "armor": 0, "block": 1},
	"circus_mask": {"class": "common", "slot": "armor", "name": "小丑面具", "hp": 4, "attack": 0, "armor": 1, "block": 1},
	"circus_gloves": {"class": "common", "slot": "armor", "name": "杂技手套", "hp": 2, "attack": 2, "armor": 0, "block": 0},
	"jungle_bow": {"class": "archer", "slot": "weapon", "name": "丛林弓", "hp": 0, "attack": 5, "armor": 0, "block": 0},
	"jungle_knife": {"class": "archer", "slot": "offhand", "name": "剥皮刀", "hp": 2, "attack": 2, "armor": 0, "block": 0},
	"jungle_hat": {"class": "archer", "slot": "armor", "name": "草帽", "hp": 4, "attack": 0, "armor": 1, "block": 1},
	"jungle_vest": {"class": "archer", "slot": "armor", "name": "树叶衣", "hp": 5, "attack": 0, "armor": 1, "block": 1},
	"jungle_pants": {"class": "archer", "slot": "armor", "name": "树叶裤", "hp": 5, "attack": 0, "armor": 1, "block": 1},
	"jungle_gloves": {"class": "archer", "slot": "armor", "name": "编制手套", "hp": 2, "attack": 2, "armor": 0, "block": 0},
	"ranger_hat": {"class": "archer", "slot": "armor", "name": "游侠帽", "hp": 4, "attack": 0, "armor": 1, "block": 1},
	"ranger_cape": {"class": "archer", "slot": "armor", "name": "游侠披风", "hp": 3, "attack": 0, "armor": 0, "block": 1},
	"ranger_vest": {"class": "archer", "slot": "armor", "name": "游侠紧身衣", "hp": 5, "attack": 0, "armor": 1, "block": 1},
	"ranger_shoulder": {"class": "archer", "slot": "armor", "name": "游侠护肩", "hp": 3, "attack": 0, "armor": 1, "block": 1},
	"ranger_belt": {"class": "archer", "slot": "armor", "name": "游侠腰带", "hp": 4, "attack": 0, "armor": 0, "block": 1},
	"ranger_gloves": {"class": "archer", "slot": "armor", "name": "游侠护手", "hp": 2, "attack": 2, "armor": 0, "block": 0}
}

const CONSUMABLES := {
	"minor_heal": {"name": "小型治疗剂", "desc": "战前携带的基础恢复品。", "kind": "heal", "value": 18},
	"iron_skin": {"name": "铁肤药剂", "desc": "战前携带的防护药剂。", "kind": "armor", "value": 2},
	"swift_step": {"name": "迅步药水", "desc": "战前携带的机动药水。", "kind": "dodge", "value": 1},
	"rage_draught": {"name": "狂怒药剂", "desc": "战前携带的进攻药剂。", "kind": "attack", "value": 3},
	"focus_tea": {"name": "凝神茶", "desc": "战前携带的专注饮品。", "kind": "skill", "value": 1},
	"emergency_kit": {"name": "应急包", "desc": "战前携带的保命工具。", "kind": "block", "value": 2},
	"huangqi_juice": {"name": "黄芪汁", "desc": "每场战斗可使用 3 次，每次回复 30% 生命值。", "kind": "charge_heal_percent", "value": 0.30, "uses": 3},
	"throwing_dart": {"name": "飞镖", "desc": "下一次攻击额外造成 5 点伤害。", "kind": "charge_bonus_damage", "value": 5}
}

const STARTER_CONSUMABLES := ["minor_heal", "iron_skin", "swift_step", "rage_draught", "focus_tea", "emergency_kit", "huangqi_juice"]

static func weapon_profile_for_item(item_id: String) -> Dictionary:
	var profile_id := String(WEAPON_ITEM_PROFILES.get(item_id, ""))
	if profile_id == "" or not WEAPON_PROFILES.has(profile_id):
		return {}
	return (WEAPON_PROFILES[profile_id] as Dictionary).duplicate(true)


static func weapon_profile_for_player(player: Dictionary) -> Dictionary:
	var equipment: Dictionary = player.get("equipment", {})
	var tower_equipment: Dictionary = player.get("tower_equipment", {})
	var weapon_id := String(tower_equipment.get("weapon", equipment.get("weapon", "")))
	if weapon_id == "":
		return (WEAPON_PROFILES["unarmed"] as Dictionary).duplicate(true)
	var profile := weapon_profile_for_item(weapon_id)
	if profile.is_empty():
		return (WEAPON_PROFILES["unarmed"] as Dictionary).duplicate(true)
	return profile

static func normalize_class_id(class_id: String) -> String:
	if CLASSES.has(class_id):
		return class_id
	# warrior/archer are historical save identifiers; all new runtime data uses unified.
	return "unified"


static func content_class_id(content: Dictionary) -> String:
	return String(content.get("content_class", content.get("class", "")))


static func runtime_class_id_for_content(content: Dictionary) -> String:
	var explicit_runtime_class := String(content.get("runtime_class", ""))
	if explicit_runtime_class != "":
		return normalize_class_id(explicit_runtime_class)
	var content_class := content_class_id(content)
	if content_class in ["common", "unified", "warrior", "archer"]:
		return "unified"
	return content_class


static func content_class_label(content: Dictionary) -> String:
	match content_class_id(content):
		"common":
			return "通用"
		"warrior":
			return "战士内容"
		"archer":
			return "弓箭手内容"
		"enemy":
			return "敌人"
		"unified":
			return "统一职业"
	return content_class_id(content)


static func skill_class_compatible(skill: Dictionary, class_id: String) -> bool:
	if content_class_id(skill) == "enemy":
		return false
	var normalized_class := normalize_class_id(class_id)
	return runtime_class_id_for_content(skill) == normalized_class


static func equipment_class_compatible(item: Dictionary, class_id: String) -> bool:
	var content_class := content_class_id(item)
	if content_class == "common":
		return true
	return runtime_class_id_for_content(item) == normalize_class_id(class_id)


static func equipment_slot(item_or_slot: Variant) -> String:
	var raw_slot := ""
	if typeof(item_or_slot) == TYPE_DICTIONARY:
		raw_slot = String((item_or_slot as Dictionary).get("slot", ""))
	else:
		raw_slot = String(item_or_slot)
	match raw_slot:
		"weapon":
			return "weapon"
		"offhand":
			return "offhand"
		"accessory", "necklace", "ring", "ring2":
			return "accessory"
		"armor", "head", "body", "waist", "legs", "hands", "leggings", "feet", "shoulders", "shoulder", "cloak", "cape":
			return "armor"
	return ""

const TUTORIAL_UNLOCKS := {
	"unified": [
		"warrior_old_chest", "warrior_wooden_shield", "common_moon_ring"
	]
}

const TUTORIAL_STARTING_EQUIPMENT := {
	"unified": "warrior_training_sword"
}

const TUTORIAL_ENCOUNTERS := [
	{"id": "tutorial_01", "type": "normal", "name": "攻击考官", "player_hint": "提示：先点击攻击积攒能量，再使用下方技能。", "units": [{"name": "攻击考官", "rank": "normal", "hp": 26, "attack": 5, "defense": 0, "passive_skills": ["", "", "", ""], "skills": ["enemy_heavy_strike"]}]},
	{"id": "tutorial_02", "type": "normal", "name": "防御考官", "player_hint": "提示：本场抽到防御加成，点击防御抵挡攻击。", "units": [{"name": "防御考官", "rank": "normal", "hp": 38, "attack": 5, "defense": 1, "passive_skills": ["tutorial_ramp", "", "", ""], "skills": ["enemy_rend", "enemy_fortify"]}]},
	{"id": "tutorial_03", "type": "normal", "name": "闪避考官", "player_hint": "提示：本场抽到闪避加成，点击闪避避开攻击。", "units": [{"name": "闪避考官", "rank": "normal", "hp": 34, "attack": 6, "defense": 1, "passive_skills": ["tutorial_evade", "", "", ""], "skills": ["enemy_heavy_strike", "enemy_quick_evade"]}]}
]
const NORMAL_UNITS := [
	{"id": "normal_rat_01", "name": "腐鼠", "fixed_stats": true, "hp": 30, "attack": 10, "defense": 1, "block_power": 3, "passive_skills": ["swarm", "corruption", "", ""], "skills": [], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10}},
	{"id": "normal_rat_02", "name": "尖牙鼠", "fixed_stats": true, "hp": 40, "attack": 12, "defense": 1, "block_power": 2, "passive_skills": ["swarm", "fang", "", ""], "skills": [], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10}},
	{"id": "normal_rat_03", "name": "狩猎鼠", "fixed_stats": true, "hp": 35, "attack": 15, "defense": 1, "block_power": 1, "passive_skills": ["swarm", "", "", ""], "skills": ["enemy_pursuit"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_pursuit": 20}},
	{"id": "normal_skeleton_01", "name": "刀盾骷髅", "fixed_stats": true, "hp": 50, "attack": 8, "defense": 4, "block_power": 5, "passive_skills": ["thick_skin", "", "", ""], "skills": ["enemy_skeleton_taunt"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_skeleton_taunt": 40}},
	{"id": "normal_skeleton_02", "name": "长矛骷髅", "fixed_stats": true, "hp": 35, "attack": 10, "defense": 2, "block_power": 4, "passive_skills": ["break_armor", "", "", ""], "skills": ["enemy_skeleton_heavy_strike"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_skeleton_heavy_strike": 30}},
	{"id": "normal_skeleton_03", "name": "铁甲骷髅", "fixed_stats": true, "hp": 55, "attack": 9, "defense": 4, "block_power": 4, "passive_skills": ["thick_skin", "guard", "tank", "taunt"], "skills": ["enemy_skeleton_fortify", "enemy_skeleton_taunt"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_skeleton_fortify": 30, "enemy_skeleton_taunt": 40}},
	{"id": "normal_shadow_01", "name": "盗贼", "hp": 28, "attack": 14, "defense": 0, "block_power": 2, "passive_skills": ["first_strike", "", "", ""], "skills": ["enemy_quick_evade", "enemy_rend"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_quick_evade": 15, "enemy_rend": 25}},
	{"id": "normal_shadow_02", "name": "暗弩手", "hp": 32, "attack": 16, "defense": 0, "block_power": 1, "passive_skills": ["mark", "hidden", "", ""], "skills": ["enemy_dark_bolt", "enemy_weaken"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_dark_bolt": 25, "enemy_weaken": 20}},
	{"id": "normal_caster_01", "name": "学徒术士", "hp": 32, "attack": 11, "defense": 1, "block_power": 2, "passive_skills": ["curse", "backline", "", ""], "skills": ["enemy_weaken", "enemy_dark_bolt"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_weaken": 20, "enemy_dark_bolt": 25}},
	{"id": "normal_mutant_02", "name": "晶刺兽", "hp": 50, "attack": 11, "defense": 3, "block_power": 4, "passive_skills": ["break_armor", "", "", ""], "skills": ["enemy_rend", "enemy_enrage"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_rend": 25, "enemy_enrage": 20}}
]

const ELITE_UNITS := [
	{"id": "elite_skeleton_01", "name": "刀盾骷髅", "fixed_stats": true, "hp": 50, "attack": 8, "defense": 4, "block_power": 5, "passive_skills": ["thick_skin", "", "", ""], "skills": ["enemy_skeleton_taunt"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_skeleton_taunt": 40}},
	{"id": "elite_skeleton_02", "name": "长矛骷髅", "fixed_stats": true, "hp": 35, "attack": 10, "defense": 2, "block_power": 4, "passive_skills": ["break_armor", "", "", ""], "skills": ["enemy_skeleton_heavy_strike"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_skeleton_heavy_strike": 30}},
	{"id": "elite_skeleton_03", "name": "铁甲骷髅", "fixed_stats": true, "hp": 55, "attack": 9, "defense": 4, "block_power": 4, "passive_skills": ["thick_skin", "guard", "", ""], "skills": ["enemy_skeleton_fortify", "enemy_skeleton_taunt"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_skeleton_fortify": 30, "enemy_skeleton_taunt": 40}},
	{"id": "elite_shadow_01", "name": "暗影猎长", "hp": 45, "attack": 20, "defense": 1, "block_power": 2, "passive_skills": ["mark", "cunning", "", ""], "skills": ["enemy_dark_bolt", "enemy_quick_evade"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_dark_bolt": 30, "enemy_quick_evade": 15}},
	{"id": "elite_caster_01", "name": "深塔祭司", "hp": 48, "attack": 10, "defense": 0, "block_power": 6, "passive_skills": ["curse", "abyss_communication", "", ""], "skills": ["enemy_weaken", "enemy_shadow_armor"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_weaken": 20, "enemy_shadow_armor": 20}},
	{"id": "elite_mutant_01", "name": "裂塔巨兽", "hp": 35, "attack": 16, "defense": 5, "block_power": 5, "passive_skills": ["revive", "", "", ""], "skills": ["enemy_heavy_strike", "enemy_enrage"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_heavy_strike": 30, "enemy_enrage": 20}}
]

const BOSS_UNITS := [
	{"id": "boss_rat_king", "name": "鼠王", "fixed_stats": true, "hp": 100, "attack": 20, "defense": 5, "block_power": 8, "passive_skills": ["swarm", "corruption", "", ""], "skills": ["enemy_pursuit", "enemy_call_rat_pack", "enemy_bite"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_pursuit": 20, "enemy_bite": 20, "enemy_call_rat_pack": 10}},
	{"id": "boss_skeleton_warden", "name": "骷髅典狱长", "fixed_stats": true, "hp": 100, "attack": 20, "defense": 7, "block_power": 10, "passive_skills": ["thick_skin", "enrage", "", ""], "skills": ["enemy_skeleton_fortify", "enemy_skeleton_heavy_strike"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_skeleton_fortify": 30, "enemy_skeleton_heavy_strike": 30}},
	{"id": "boss_shadow_duke", "name": "暗影公爵", "hp": 90, "attack": 24, "defense": 3, "block_power": 6, "passive_skills": ["first_strike", "evade", "mark", "cunning"], "skills": ["enemy_dark_bolt", "enemy_quick_evade", "enemy_weaken"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_dark_bolt": 30, "enemy_quick_evade": 15, "enemy_weaken": 20}},
	{"id": "boss_deep_oracle", "name": "深渊先知", "hp": 100, "attack": 22, "defense": 4, "block_power": 7, "passive_skills": ["curse", "spell_shield", "toxic_mist", ""], "skills": ["enemy_weaken", "enemy_dark_bolt", "enemy_shadow_armor"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_weaken": 20, "enemy_dark_bolt": 30, "enemy_shadow_armor": 20}},
	{"id": "boss_tower_core", "name": "裂塔核心", "hp": 100, "attack": 22, "defense": 6, "block_power": 8, "passive_skills": ["revive", "charge", "split", "blood_moon"], "skills": ["enemy_heavy_strike", "enemy_enrage", "enemy_rend"], "behavior_weights": {"innate_attack_1": 50, "innate_defend": 10, "innate_dodge": 10, "enemy_heavy_strike": 30, "enemy_enrage": 20, "enemy_rend": 25}}
]

const MONSTER_GROUP_ORDER := ["rat", "guard", "shadow", "caster", "mutant"]

const MONSTER_GROUPS := {
	"rat": {
		"name": "老鼠群落",
		"minion_passive_skills": ["swarm"],
		"normal_units": ["normal_rat_01", "normal_rat_02", "normal_rat_03"],
		"elite_units": ["normal_rat_01", "normal_rat_02", "normal_rat_03"],
		"boss_units": ["boss_rat_king"]
	},
	"guard": {
		"name": "骷髅群落",
		"minion_passive_skills": [],
		"normal_units": ["normal_skeleton_01", "normal_skeleton_02", "normal_skeleton_03"],
		"elite_units": ["elite_skeleton_01", "elite_skeleton_02", "elite_skeleton_03"],
		"boss_units": ["boss_skeleton_warden"]
	},
	"shadow": {
		"name": "暗影群落",
		"minion_passive_skills": ["first_strike", "evade", "cunning"],
		"normal_units": ["normal_shadow_01", "normal_shadow_02"],
		"elite_units": ["elite_shadow_01"],
		"boss_units": ["boss_shadow_duke"]
	},
	"caster": {
		"name": "术士群落",
		"minion_passive_skills": ["curse"],
		"normal_units": ["normal_caster_01"],
		"elite_units": ["elite_caster_01"],
		"boss_units": ["boss_deep_oracle"]
	},
	"mutant": {
		"name": "异变群落",
		"minion_passive_skills": ["break_armor"],
		"normal_units": ["normal_mutant_02"],
		"elite_units": ["elite_mutant_01"],
		"boss_units": ["boss_tower_core"]
	}
}


static func get_state_weight_total() -> int:
	var total := 0
	for card in STATE_CARDS.values():
		total += int(card["weight"])
	return total


static func get_floor_battle_type(index: int) -> String:
	return BATTLE_TYPES[index - 1]


static func monster_group_ids() -> Array[String]:
	var result: Array[String] = []
	for group_id in MONSTER_GROUP_ORDER:
		result.append(group_id)
	return result


static func monster_group(group_id: String) -> Dictionary:
	return MONSTER_GROUPS.get(group_id, {})


static func monster_group_name(group_id: String) -> String:
	return String(monster_group(group_id).get("name", group_id))


static func monster_group_minion_passive_skills(group_id: String) -> Array:
	var group: Dictionary = monster_group(group_id)
	return group.get("minion_passive_skills", [])


static func monster_group_units(group_id: String, rank: String) -> Array[Dictionary]:
	var group: Dictionary = monster_group(group_id)
	var ids: Array = group.get("%s_units" % rank, [])
	var units: Array[Dictionary] = []
	for unit_id in ids:
		var unit := monster_unit(String(unit_id))
		if not unit.is_empty():
			units.append(unit)
	return units


static func monster_unit(unit_id: String) -> Dictionary:
	for unit in NORMAL_UNITS:
		if String(unit.get("id", "")) == unit_id:
			return unit
	for unit in ELITE_UNITS:
		if String(unit.get("id", "")) == unit_id:
			return unit
	for unit in BOSS_UNITS:
		if String(unit.get("id", "")) == unit_id:
			return unit
	return {}


static func external_table(table_name: String) -> Dictionary:
	var repository := DataRepository.new()
	return repository.table(table_name)


static func external_catalog_version() -> int:
	var repository := DataRepository.new()
	return repository.version()


static func external_catalog_tables() -> Array[String]:
	var repository := DataRepository.new()
	return repository.available_tables()
