extends RefCounted
class_name TraitCatalog

const LABELS := {
	"swarm": "群袭",
	"corruption": "腐败",
	"fang": "尖牙",
	"claw": "利爪",
	"thick_skin": "厚皮",
	"break_armor": "破甲",
	"first_strike": "先手",
	"cunning": "狡诈",
	"hidden": "隐蔽",
	"mark": "标记",
	"curse": "诅咒",
	"abyss_communication": "深渊沟通",
	"guard": "护卫",
	"tank": "肉盾",
	"taunt": "嘲讽",
	"backline": "后排",
	"fortify": "固守",
	"summon": "召唤",
	"revive": "复苏",
	"enrage": "狂怒",
	"evade": "闪身",
	"spell_shield": "法盾",
	"charge": "充能",
	"split": "裂变",
	"corrode": "腐蚀",
	"support": "辅助",
	"phase": "阶段",
	"toxic_mist": "毒雾",
	"shadow_domain": "暗影领域",
	"blood_moon": "血月"
	,"tutorial_ramp": "考官：防御"
	,"tutorial_evade": "考官：闪避"
}

const DESCRIPTIONS := {
	"swarm": "群袭：普通攻击时，所有存活的群袭同伴对同一目标各进行一次普通攻击；协攻不会再次触发群袭。",
	"corruption": "腐败：攻击命中后使目标在行动前受到攻击力 20% 的真实伤害，持续 3 回合；重复命中刷新持续时间并使用最后一次攻击力。",
	"fang": "尖牙：攻击命中后使目标防御降低 1 点，持续至战斗结束，可叠加。",
	"claw": "利爪：攻击伤害提高。",
	"thick_skin": "厚皮：护甲提高20%。",
	"break_armor": "破甲：造成伤害时无视目标20%护甲。",
	"first_strike": "先手：战斗开始时会先进行一次削弱后的攻击。",
	"cunning": "狡诈：隐藏真实意图，界面只显示狡诈而不会显示攻击、防守或闪避。",
	"hidden": "隐蔽：有非隐蔽单位存活时无法被选为主要目标。",
	"mark": "标记：命中时给目标施加易伤（受伤×1.25，持续2回合），不叠加但会刷新。",
	"curse": "诅咒：命中时给目标施加削弱（伤害×0.8，持续3回合），不叠加但会刷新。",
	"abyss_communication": "深渊沟通：每回合获得自身格挡值50%的额外格挡并回复5%生命。",
	"guard": "护卫：存活时使队友承受的伤害降低20%。",
	"tank": "肉盾：倾向于防守，保护队伍后排。",
	"taunt": "嘲讽：部分回合会嘲讽并防守，强制玩家优先攻击它。",
	"backline": "后排：队伍中的输出手，有前排存活时无法被选为目标。",
	"fortify": "固守：偶数回合会获得额外格挡。",
	"summon": "召唤：每隔数回合召唤一个弱化分身。",
	"revive": "复苏：每隔数回合恢复少量生命。",
	"enrage": "狂怒：生命低于50%时伤害提高50%，承受伤害提高30%。",
	"evade": "闪身：部分回合准备闪避，抵消下一次命中。",
	"spell_shield": "法盾：每3回合获得1层法盾，减伤50%持续1回合。",
	"charge": "充能：每3回合充能，下一次攻击力翻倍。",
	"split": "裂变：首次HP低于50%时分裂为两个小型单位。",
	"corrode": "腐蚀：每回合削弱玩家护甲（护甲×0.85）。",
	"support": "辅助：每2回合治疗血量最低的友军（10%最大HP）。",
	"phase": "阶段：HP越低攻击越强（30%-60%：×1.30，<30%：×1.60）。",
	"toxic_mist": "毒雾：每3回合所有单位受到1点伤害。效果在首领存活时持续。",
	"shadow_domain": "暗影领域：暗影伤害+20%，所有治疗-50%。效果在首领存活时持续。",
	"blood_moon": "血月：所有攻击+1，所有治疗+1。效果在首领存活时持续。"
	,"tutorial_ramp": "考官：防御：每次成功造成伤害后，后续攻击会更强。"
	,"tutorial_evade": "考官：闪避：每 2 回合会使用一次重攻击。"
}


static func labels(passive_skills: Array) -> String:
	var active_skills := passive_skills.filter(func(skill_id): return skill_id != "")
	if active_skills.is_empty():
		return "无"
	var result: Array[String] = []
	for skill_id in active_skills:
		result.append(LABELS.get(skill_id, skill_id))
	return "、".join(result)


func tooltip(passive_skills: Array) -> String:
	var active_skills := passive_skills.filter(func(skill_id): return skill_id != "")
	if active_skills.is_empty():
		return "被动技能：无\n该单位没有额外战斗规则。"
	var lines: Array[String] = ["被动技能说明"]
	for skill_id in active_skills:
		lines.append(DESCRIPTIONS.get(skill_id, "%s：暂无说明。" % skill_id))
	return "\n".join(lines)
