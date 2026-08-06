# 实时战斗流程

状态：已实现。

```text
PlaySession._start_current_battle() 创建遭遇并初始化 BattleState
  -> 战斗开始事件与先手行动
  -> 按敏捷生成本回合行动顺序
  -> 当前行动者执行普通行动或数据技能
  -> SkillActionService / ActionPipeline / StatusService / TriggerService 结算
  -> 继续处理行动顺序中的下一名角色
  -> 回合结束、胜负与奖励
  -> PlaySession 保存并切换下一场
```

调用关系：`PlaySession` 管理战斗生命周期；`BattleService` 编排实时行动；`CombatRules` 提供共享规则；`EnemyActionRules` 决策敌人；`SkillActionService` 读取技能动作；`ActionPipeline` 处理行动修正；`StatusService` 和 `TriggerService` 处理状态与事件。

2026-08-06 已新增 `GameProject/scripts/core/battle/battle_flow.gd` 作为时机串联骨架，并由 `BattleService.dispatch_battle_timing()` 提供兼容入口。当前真实战斗仍使用原有 `PlaySession -> BattleService` 路径；在 ARCH-04 及后续任务完成前，不得把空骨架描述为完整运行时权威。

ARCH-04 已新增 `battle/decision/` 下的 ActionIntent、玩家/敌方决策适配和目标解析模块；这些模块目前只产出意图与结构化目标结果，不接管现有技能和伤害执行。
