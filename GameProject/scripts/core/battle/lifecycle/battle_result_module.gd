extends RefCounted
class_name BattleResultModule

const BattleResult = preload("res://scripts/core/battle/lifecycle/battle_result.gd")
const CombatRules = preload("res://scripts/core/combat_rules.gd")

const REASON_PLAYER_DEATH := "player_death"
const REASON_ENEMIES_DEFEATED := "enemies_defeated"


# 判定当前战斗胜负；战斗尚未结束时返回 null。
# 只负责输出 BattleResult，奖励、存档和下一场由 Run 层回调处理。
func judge(session: RefCounted) -> RefCounted:
	if int(session.player.get("hp", 0)) <= 0:
		return build_defeat(session, REASON_PLAYER_DEATH)
	if alive_enemy_count(session) == 0:
		return build_victory(session)
	return null


func build_victory(session: RefCounted) -> RefCounted:
	return _build(session, BattleResult.OUTCOME_VICTORY, REASON_ENEMIES_DEFEATED)


func build_defeat(session: RefCounted, reason: String) -> RefCounted:
	return _build(session, BattleResult.OUTCOME_DEFEAT, reason)


func alive_enemy_count(session: RefCounted) -> int:
	return CombatRules.alive_count(session.enemies)


func _build(session: RefCounted, outcome: String, reason: String) -> RefCounted:
	return BattleResult.new(
		outcome,
		reason,
		int(session.round_index),
		int(session.floor_index),
		int(session.battle_index),
		bool(session.is_tutorial()),
		int(session.player.get("hp", 0)),
		int(session.player.get("max_hp", session.player.get("base_max_hp", 1))),
		alive_enemy_count(session)
	)
