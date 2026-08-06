# 行动管线

状态：已实现。

`BattleService` 接收技能定义，`SkillActionService` 读取 `actions` 数组并按顺序分发动作。`ActionPipeline` 负责处理行动上下文中的通用数值修正，例如充能带来的伤害倍率、附加伤害和重复次数。

状态效果由 `StatusService` 解析，事件动作由 `TriggerService` 执行。典型技能动作包括 `damage`、`gain_block`、`apply_status`、`modify_armor`、`interrupt`、`heal` 和 `summon`。动作可以声明 `conditions`，由同一条件评估器判断；`damage.ignore_armor` 会进入伤害结算的护甲倍率；敌方技能使用同一 actions 分发入口，不再因角色方不同而静默跳过。

新增行动类型时必须同时更新：Schema 注册、执行器、日志事件、单元测试和图鉴描述；未知 action 会记录错误，不能在某个技能中内联另一个行动解释器。

ARCH-05 已新增 `GameProject/scripts/core/battle/skill/effect_executor.gd`、`effect_dispatcher.gd` 和 `skill_effect_module.gd` 作为新的 action 路由契约。当前真实技能执行仍由 `BattleService` 负责；ARCH-06 起才按子任务逐类迁移无伤害效果，迁移完成前不得把新入口描述为运行时唯一权威。
