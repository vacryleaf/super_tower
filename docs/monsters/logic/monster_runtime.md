# 怪物运行逻辑

状态：已实现。

`EncounterService` 根据楼层、战斗序号和群落生成遭遇；`Combatant.from_enemy_unit()`/`scaled_enemy()` 转换单位和倍率；`EnemyActionRules` 选择敌方行动；BattleService 负责实时执行。普通、精英和 Boss 共用同一流程，只由 rank/数据改变内容。
