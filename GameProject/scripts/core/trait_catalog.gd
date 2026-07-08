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
	"phase": "阶段"
}

const DESCRIPTIONS := {
	"swarm": "群袭：攻击时追加一段小额伤害。",
	"claw": "利爪：攻击伤害提高。",
	"thick_skin": "厚皮：入场获得额外护甲。",
	"break_armor": "破甲：设计定位为削弱护甲的攻击型敌人。",
	"first_strike": "先手：战斗开始时会先进行一次削弱后的攻击。",
	"cunning": "狡诈：隐藏真实意图，界面只显示狡诈而不会显示攻击、防守或闪避。",
	"mark": "标记：设计定位为提高后续输出压力。",
	"curse": "诅咒：每隔数回合对玩家造成直接伤害。",
	"guard": "护卫：会交替攻击与防守。",
	"tank": "肉盾：倾向于防守，保护队伍后排。",
	"taunt": "嘲讽：部分回合会嘲讽并防守，强制玩家优先攻击它。",
	"backline": "后排：队伍中的输出手，通常由前排保护。",
	"fortify": "固守：偶数回合会获得额外格挡。",
	"summon": "召唤：每隔数回合追加一段伤害压力。",
	"revive": "复苏：每隔数回合恢复少量生命。",
	"enrage": "狂暴：低生命时攻击伤害提高。",
	"evade": "闪身：部分回合准备闪避，抵消下一次命中。",
	"spell_shield": "法盾：设计定位为抵御技能爆发。",
	"charge": "充能：设计定位为蓄力后的高压行动。",
	"split": "裂变：设计定位为多阶段或分裂战斗。",
	"corrode": "腐蚀：设计定位为持续削弱玩家防御。",
	"support": "辅助：队伍中的辅助单位。",
	"phase": "阶段：首领拥有阶段变化。"
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
