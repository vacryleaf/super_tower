extends RefCounted
class_name TraitCatalog

const LABELS := {
	"swarm": "群袭",
	"claw": "利爪",
	"thick_skin": "厚皮",
	"break_armor": "破甲",
	"first_strike": "先手",
	"cunning": "狡诈",
	"mark": "标记",
	"curse": "诅咒",
	"guard": "护卫",
	"tank": "肉盾",
	"taunt": "嘲讽",
	"backline": "后排",
	"fortify": "固守",
	"summon": "召唤",
	"revive": "复苏",
	"enrage": "狂暴",
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
}

const DESCRIPTIONS := {
	"swarm": "群袭：攻击时追加一段小额伤害。",
	"claw": "利爪：攻击伤害提高。",
	"thick_skin": "厚皮：入场获得额外护甲。",
	"break_armor": "破甲：命中时削弱玩家护甲（护甲×0.80，持续2回合）。",
	"first_strike": "先手：战斗开始时会先进行一次削弱后的攻击。",
	"cunning": "狡诈：隐藏真实意图，界面只显示狡诈而不会显示攻击、防守或闪避。",
	"mark": "标记：命中时给玩家施加易伤（受伤×1.25，持续2回合）。",
	"curse": "诅咒：每隔数回合对玩家造成直接伤害。",
	"guard": "护卫：会交替攻击与防守。",
	"tank": "肉盾：倾向于防守，保护队伍后排。",
	"taunt": "嘲讽：部分回合会嘲讽并防守，强制玩家优先攻击它。",
	"backline": "后排：队伍中的输出手，有前排存活时无法被选为目标。",
	"fortify": "固守：偶数回合会获得额外格挡。",
	"summon": "召唤：每隔数回合召唤一个弱化分身。",
	"revive": "复苏：每隔数回合恢复少量生命。",
	"enrage": "狂暴：低生命时攻击伤害提高。",
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
}


static func labels(traits: Array) -> String:
	if traits.is_empty():
		return "无"
	var result: Array[String] = []
	for trait_id in traits:
		result.append(LABELS.get(trait_id, trait_id))
	return "、".join(result)


func tooltip(traits: Array) -> String:
	if traits.is_empty():
		return "特性：无\n该敌人没有额外战斗规则。"
	var lines: Array[String] = ["特性说明"]
	for trait_id in traits:
		lines.append(DESCRIPTIONS.get(trait_id, "%s：暂无说明。" % trait_id))
	return "\n".join(lines)
