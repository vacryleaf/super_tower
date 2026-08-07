extends RefCounted
class_name UiIntent

# UI 意图适配器：UI 动作层只通过本门面表达战斗/奖励意图，
# 由门面转发到 Run/Battle 层的公开 API。门面不做伤害结算、
# 不选择敌人 AI 行动、不读取 Mod 文件；只做转发与最小边界保护。

var session: Variant = null


func bind(target_session) -> void:
	session = target_session


func is_bound() -> bool:
	return session != null


func attack(target_index: int) -> void:
	if session == null:
		return
	session.player_attack(target_index)


func defend() -> void:
	if session == null:
		return
	session.player_defend()


func dodge() -> void:
	if session == null:
		return
	session.player_dodge()


func use_blood_potion() -> void:
	if session == null:
		return
	session.use_blood_potion_in_battle()


func end_turn() -> void:
	if session == null:
		return
	session.end_turn()


func use_skill(slot_index: int, target_index: int) -> void:
	if session == null:
		return
	session.use_skill(slot_index, target_index)


func use_charge(charge_id: String) -> void:
	if session == null:
		return
	session.use_charge(charge_id)


func use_consumable(consumable_id: String) -> void:
	if session == null:
		return
	session.use_consumable(consumable_id)


func choose_reward(index: int) -> void:
	if session == null:
		return
	session.choose_reward(index)


func choose_reward_target(index: int) -> void:
	if session == null:
		return
	session.choose_reward_target(index)
