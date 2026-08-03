# 教程与楼层流程

状态：已实现（2026-08-03 更新首场教学）。

1. 新角色检测教程完成标记。
2. 未完成时进入固定 3 场教程；首场开始前由 `DataCatalog.TUTORIAL_STARTING_EQUIPMENT` 提供训练剑，并通过遭遇数据中的 `player_hint` 引导先积攒能量再使用技能。
3. 首场胜利固定奖励旧胸甲，不增加 `unlocked_skills`。
4. 第二场固定抽取 `perfect_guard` 防御加成卡并提示使用防御，胜利后固定奖励木盾。
5. 第三场固定抽取 `read` 闪避加成卡并提示使用闪避，胜利后固定奖励银戒指。
6. 教程结束只更新教程状态，完成后从正式第 1 层第 1 场开始，不消耗正式楼层。
7. 正式每层按照 `DataCatalog.BATTLE_TYPES` 生成 10 场：normal、normal、elite、normal、normal、elite、normal、normal、normal、boss。
8. 每场胜利后结算奖励；第 10 场结束进入下一层或完成单局。
