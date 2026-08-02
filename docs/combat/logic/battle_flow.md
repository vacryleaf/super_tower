# 实时战斗流程

状态：已实现。

```text
PlaySession 创建遭遇
  -> BattleState 初始化
  -> BattleService.start_battle()
  -> 战斗开始事件与首击
  -> 玩家行动（普通/防御/躲避/技能）
  -> ActionPipeline 执行动作
  -> StatusService / TriggerService 结算
  -> 敌方行为规则选择行动
  -> 回合结束、胜负与奖励
  -> PlaySession 保存并切换下一场
```

调用关系：`CombatRules` 放共享数值规则；`BattleService` 编排实时流程；`EnemyActionRules` 决策敌人；`StatusService` 和 `TriggerService` 处理通用状态。
