# 战斗领域

状态：已实现。

## 二级目录

- `design/`：战斗设计目标、回合顺序和状态/触发原则。
- `logic/`：实时战斗流程、行动管线、回合详述。
- `data/`：行动、状态、触发器数据契约。

唯一实时路径：`PlaySession -> BattleService -> ActionPipeline / StatusService / TriggerService`。

当前路径仍是运行时事实。已确认待实现的模块化拆分方案见 [模块化架构优化方案](../architecture/design/modular_architecture_optimization.md)，其中将以兼容迁移方式引入 `BattleFlow`、时机模块和效果执行器，不恢复模拟战斗。

ARCH-10 起，`TriggerService` 只保留事件与条件筛选，触发动作统一由 `battle/trigger/trigger_dispatch_module.gd` 执行；伤害类触发动作经 `battle/trigger/battle_action_queue.gd` 嵌套行动队列进入统一命中/伤害流程。

ARCH-11 起，回合时机由 `battle/lifecycle/round_lifecycle_module.gd` 与 `battle/lifecycle/turn_order_module.gd` 统一管理；`PlaySession._begin_player_turn()` 与 `BattleService` 回合收尾只保留薄适配转发。

ARCH-12 起，战斗胜负由 `battle/lifecycle/battle_result_module.gd` 判定并输出 `BattleResult`，`PlaySession` 胜负回调仅负责把结果转发给 Run 层（奖励、存档、下一场）。
