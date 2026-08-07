extends RefCounted
class_name TurnOrderModule

const CombatRules = preload("res://scripts/core/combat_rules.gd")


# 计算当前回合的统一行动顺序；代理 CombatRules 的排序规则，
# 供回合生命周期、实时战斗流程和模拟流程共享同一行动顺序来源。
func compute_order(session: RefCounted) -> Array[Dictionary]:
	return CombatRules.action_order(
		session.player,
		session.enemies,
		session.allies,
		session.status_service,
		session.round_index
	)


# 查找玩家在行动顺序中的位置；不存在时返回 -1。
func find_player_position(action_order: Array[Dictionary]) -> int:
	for index in range(action_order.size()):
		if String(action_order[index].get("type", "")) == "player":
			return index
	return -1


# 将行动顺序格式化为调试文本：类型:名称，按顺序逗号分隔。
func format_order(action_order: Array[Dictionary]) -> String:
	var labels: Array[String] = []
	for entry in action_order:
		var actor_type := String(entry.get("type", ""))
		var unit: Dictionary = entry.get("unit", {})
		labels.append("%s:%s" % [actor_type, String(unit.get("name", actor_type))])
	return ",".join(labels)
