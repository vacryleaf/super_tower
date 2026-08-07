# 模块化架构优化需求

状态：已确认待实现。

## 1. 文档信息

- 功能名称：Super Tower 模块化架构优化
- 目标日期：2026-08-06 起分阶段实施
- 关联领域：架构、战斗、技能、怪物、成长与高塔、持久化、UI、测试与维护
- 架构方案：`docs/architecture/design/modular_architecture_optimization.md`
- 执行 TODO：`docs/architecture/logic/modular_architecture_optimization_todo.md`
- 总入口：`docs/develop_list.md`

## 2. 背景与目标

### 背景

当前项目已经按服务拆分，但 `PlaySession` 和 `BattleService` 仍承担多个生命周期和规则职责。技能 action 的读取与执行、命中与伤害、触发器与嵌套伤害、战斗流程与高塔流程之间存在耦合。UI 视图虽已分文件，但缺少统一的只读状态和用户意图契约。内容加载、外部表、Mod 注册和运行时查询也尚未完全通过同一门面接入。

### 目标

- 建立只负责时机和流程串联的 `BattleFlow`。
- 将回合、行动、技能效果、命中、闪避、伤害、触发和战斗结果拆成可独立验证的模块。
- 统一玩家和敌人的技能 action 执行路径。
- 使触发器产生的额外伤害、反击和反伤重新进入统一流程。
- 分离战斗生命周期、单局/高塔成长、存档和 UI 展示边界。
- 建立 `RuntimeCatalog`，统一原版、外部规范化表和 Mod 内容查询。
- 为每项后续改动定义独立文件范围、测试入口、验收标准和提交边界。

### 非目标

- 不恢复自动模拟战斗。
- 不改变现有战斗数值、技能数据、楼层规则、奖励规则或存档语义，除非独立任务明确要求。
- 不一次性拆完所有大文件，不进行与模块边界无关的格式化或重命名。
- 不引入第三方依赖、复杂事件总线或新的场景框架。
- 不把项目改造成脱离 Godot 的普通独立程序。

## 3. 可观察结果

完成全部方案后：

1. 新增技能 action 只需更新 Schema、对应执行器、测试和图鉴，不需要在 `BattleFlow` 增加技能分支。
2. 命中、闪避、伤害和触发可以用最小 `BattleContext`/`HitContext` 桩对象单独测试。
3. 玩家和敌人相同 action 使用同一个效果分发入口。
4. `PlaySession` 负责单局和高塔生命周期，`BattleFlow` 负责战斗时机，奖励和存档在战斗结束后由 Run 层处理。
5. UI 只能读取展示状态并提交意图，不能计算伤害或选择敌方技能。
6. 外部内容是否可作为运行时权威由 `RuntimeCatalog`、Schema 和 parity 结果共同决定。

## 4. 规则和数据契约

### 4.1 流程时机

稳定时机为：

```text
battle_prepare -> battle_start
round_start_before -> round_start -> round_start_after
action_before -> action_validate -> action_start -> action_execute -> action_after -> turn_end
skill_before -> skill_effect_before -> skill_effect -> skill_effect_after -> skill_after
hit_before -> dodge_check -> dodge 或 hit_confirmed
hit_confirmed -> damage_before -> damage_apply -> damage_after -> hit_after
round_end_before -> round_end
battle_end
```

时机接口与内容触发事件分离。`TriggerEvents` 负责 `on_hit_dealt`、`on_kill` 等语义事件，不能替代流程时机。

### 4.2 跨模块上下文

跨模块接口必须使用明确上下文：

- `BattleContext`：战斗状态、行动队列、随机源、事件出口和服务端口。
- `ActionContext`：行动者、行动意图、技能、具体 action、来源和取消状态。
- `HitContext`：攻击者、目标、伤害类型、修正结果、闪避、格挡、击杀和链路信息。
- `BattleStepResult`：继续、跳过、取消当前行动、结束战斗或结构化错误。

过渡期允许上下文内部持有现有 `BattleState` 和运行时字典，但模块不得依赖完整 `PlaySession` 的私有字段和方法。

### 4.3 内容契约

内容仍以稳定 ID、Schema、`actions`、`effects`、`conditional_effects`、`tick_effects` 和 `triggers` 为主。`RuntimeCatalog` 负责统一查询和 fallback，不暴露 Mod 原始路径。未完成 parity 的外部表不得成为运行时权威。

### 4.4 存档契约

保存稳定 ID、版本和规范化快照；不保存节点、Callable、绝对路径或不可序列化对象。战斗结果以 DTO/字典传回 Run 层，战斗模块不直接写奖励或 Profile。

ARCH-15（2026-08-07）已落地：新增 `RunContext`（Run 层状态容器）与 `RunStateSnapshot`（run/battle 字段切分的纯数据快照），`RunStateSerializer` 委托二者完成保存与恢复，磁盘 `active_run` 格式与 version=4 不变；`SaveProfile` 新增 `read_active_run/write_active_run` 让 Run 层可独立读写快照，Battle 层不直接读写 Profile。旧存档迁移（legacy class_id、楼层组历史、tutorial 推断）保留在 RunContext。

## 5. 架构影响

| 层 | 主要当前文件 | 目标变化 |
| --- | --- | --- |
| 内容定义 | `data_catalog.gd`、`trait_catalog.gd`、`catalog_v1.json` | 保留来源，统一经 `RuntimeCatalog` 查询 |
| 校验与迁移 | `schema_registry.gd`、`content_validator.gd`、`catalog_migration_service.gd`、`mod_loader.gd` | 保持现有能力，补注册门面和跨表契约 |
| 状态转换 | `combatant.gd`、`battle_state.gd` | 保持数据结构兼容，增加上下文端口 |
| 战斗流程 | `play_session.gd`、`battle_service.gd` | 新增 `battle/` 流程和模块目录，保留兼容门面 |
| 效果与触发 | `skill_action_service.gd`、`action_pipeline.gd`、`status_service.gd`、`trigger_service.gd` | action 路由、命中和伤害拆分，触发改为统一嵌套行动 |
| 行为决策 | `enemy_action_rules.gd` | 只返回行动意图，由行动流程执行 |
| 成长与存档 | `encounter_service.gd`、`reward_service.gd`、`run_progress_service.gd`、`run_state_serializer.gd`、`save_profile.gd` | 引入 Run 边界和快照契约，保持旧存档迁移 |
| UI | `main.gd`、`pre_run_view.gd`、`ui/*.gd` | 引入协调器、Presenter/ViewModel 和 View 输入契约 |
| 测试 | `scripts/tests/`、`run_tests.sh`、`run_tests.bat` | 新增契约测试，继续使用跨平台 headless 入口 |

完整模块边界、目标文件和阶段请以架构方案为准。

## 6. 调用链

```text
内容来源
  -> Schema / ContentValidator / CatalogMigrationService
  -> RuntimeCatalog
  -> Combatant / Encounter / Reward / Encyclopedia
  -> RunContext 创建 BattleContext
  -> BattleFlow 触发时机
  -> ActionIntent / SkillEffect / Hit / Dodge / Damage / Trigger
  -> BattleResult
  -> RunProgress / Reward / SaveProfile
  -> Presenter / View / UI
```

触发器产生的新伤害必须进入 `BattleFlow.enqueue_nested_action()`，不得直接修改 HP 或调用兼容门面绕过命中流程。

## 7. UI、持久化和平台影响

- UI 只消费快照、事件和图鉴索引；不读取 Mod 原始文件。
- 存档继续由 `SaveProfile` 和 `RunStateSerializer` 管理，新增上下文不得直接序列化。
- `run_tests.sh` 和 `run_tests.bat` 保持同一组测试入口和失败判定。
- 所有路径使用 `res://`、`user://` 或 Godot 路径 API；不写死平台目录。

## 8. 验收标准

- [ ] 架构契约类和注册表可以独立实例化，并有契约测试。
- [ ] `BattleFlow` 能按固定顺序触发时机，支持取消、跳过和结束。
- [ ] 玩家和敌人技能共享 `SkillEffectModule` 与 `EffectDispatcher`。
- [ ] 命中、闪避、伤害和触发有独立模块和服务级测试。
- [ ] 触发器额外伤害、反击、反伤经过统一命中流程。
- [ ] `PlaySession` 不再保留重复伤害结算逻辑。
- [ ] `RuntimeCatalog` 覆盖原版、外部表和 Mod 查询边界，并保留 parity/fallback。
- [ ] Run、Battle、Persistence、UI 之间只通过明确契约交互。
- [ ] 每个 TODO 子任务都有独立测试、文档回写、清单状态和单独提交。
- [ ] `sh run_tests.sh` 与 Windows 等价入口通过；长时手工测试单独记录。

## 9. 待确认问题

| 问题 | 默认决策 | 影响 |
| --- | --- | --- |
| 是否最终将裸 `Dictionary` 全部替换为 Resource/类对象 | 暂不替换，先用 `RefCounted` 上下文包装 | 控制迁移规模和存档风险 |
| 召唤后目标是否全面改用稳定 combatant ID | 过渡期保留 index，同时新增 ID | 影响目标解析和旧测试 |
| 是否允许模块注册 Mod 自定义时机 | 第一阶段只允许内置时机，Mod 只扩展 Schema/action | 避免 Mod 改写核心流程 |
| UI 是否在本轮完全拆分 `main.gd` | 不完全拆分，先建立边界再渐进迁移 | 控制 UI 回归范围 |
