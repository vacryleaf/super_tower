# 行动管线

状态：已实现。

`BattleService` 接收技能定义，`SkillActionService` 读取 `actions` 数组并按顺序分发动作。`ActionPipeline` 负责处理行动上下文中的通用数值修正，例如充能带来的伤害倍率、附加伤害和重复次数。

状态效果由 `StatusService` 解析，事件动作由 `TriggerService` 执行。典型技能动作包括 `damage`、`gain_block`、`apply_status`、`modify_armor`、`interrupt`、`heal` 和 `summon`。动作可以声明 `conditions`，由同一条件评估器判断；`damage.ignore_armor` 会进入伤害结算的护甲倍率；敌方技能使用同一 actions 分发入口，不再因角色方不同而静默跳过。

新增行动类型时必须同时更新：Schema 注册、执行器、日志事件、单元测试和图鉴描述；未知 action 会记录错误，不能在某个技能中内联另一个行动解释器。

ARCH-05 已新增 `GameProject/scripts/core/battle/skill/effect_executor.gd`、`effect_dispatcher.gd` 和 `skill_effect_module.gd` 作为新的 action 路由契约。ARCH-06 已将格挡、闪避、治疗、状态、护甲、打断和清除 Debuff 接入独立执行器；伤害、反击、召唤和决斗仍按后续 ARCH 子任务迁移。

ARCH-10 已新增 `battle/trigger/trigger_dispatch_module.gd`（`TriggerDispatchModule`）与 `battle/trigger/battle_action_queue.gd`（`BattleActionQueue`）。`TriggerService` 现在只负责事件与条件筛选，匹配后的触发动作统一交给 `TriggerDispatchModule` 执行：`dot`/`reflect`/`extra_damage`/`counter_all` 先进入嵌套行动队列，再由 `session.deal_damage()` 走统一命中与伤害流程，不再直接修改 HP 或绕过命中流程；`heal`/`hot`/`lifesteal`/`gain_block`/`gain_dodge`/`apply_status`/`remove_status` 与计数器动作保持原有数值语义，但执行位置移到分发模块。嵌套行动队列按父链 ID 继承深度，超过最大深度（10 层）时丢弃，防止触发链无限递归。
