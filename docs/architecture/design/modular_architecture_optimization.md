# 模块化架构优化方案

状态：设计已确认待实现。

版本：2026-08-06

关联需求：`docs/requirements/2026-08-06-modular-architecture-optimization.md`

执行清单：`docs/architecture/logic/modular_architecture_optimization_todo.md`

## 1. 方案定位

本方案不是恢复模拟战斗，也不是把现有脚本简单拆成更多文件，而是在当前数据驱动、实时战斗、服务化 Godot 架构上建立更明确的职责边界。

目标是让：

- 流程模块只负责时机、顺序、上下文和流程控制。
- 行动、技能、命中、闪避、伤害、状态、触发和 AI 决策分别由独立模块实现。
- 数据目录、运行时状态、成长存档、UI 展示和测试入口有稳定的边界。
- 每个子模块可以通过最小上下文单独实例化、单独测试和替换。
- 现有玩家行动、敌人行动、技能数据和存档行为保持兼容。

本方案以当前代码为事实基线。尚未落地的内容必须标记为“设计已确认待实现”，不能在其他文档中描述为已实现。

## 2. 当前基线与问题

### 2.1 当前真实入口

当前运行时仍以以下路径为主：

```text
DataCatalog / DataRepository / TraitCatalog
  -> Combatant
  -> PlaySession
  -> BattleService
  -> ActionPipeline / StatusService / TriggerService
  -> BattleState / RunStateSerializer / UI
```

权威代码入口：

- 运行时编排：`GameProject/scripts/core/play_session.gd`、`GameProject/scripts/core/battle_service.gd`。
- 战斗状态：`GameProject/scripts/core/battle_state.gd`。
- 技能动作：`GameProject/scripts/core/skill_action_service.gd`、`GameProject/scripts/core/action_pipeline.gd`。
- 状态与触发器：`GameProject/scripts/core/status_service.gd`、`GameProject/scripts/core/trigger_service.gd`。
- 内容来源：`GameProject/scripts/core/data_catalog.gd`、`GameProject/scripts/core/data_repository.gd`、`GameProject/scripts/core/trait_catalog.gd`。
- 成长与存档：`GameProject/scripts/core/encounter_service.gd`、`GameProject/scripts/core/reward_service.gd`、`GameProject/scripts/core/run_progress_service.gd`、`GameProject/scripts/core/run_state_serializer.gd`、`GameProject/scripts/core/save_profile.gd`。
- UI 宿主与视图：`GameProject/scripts/main.gd`、`GameProject/scripts/ui/`。

### 2.2 已确认的职责集中

| 当前位置 | 当前职责 | 目标处理方式 |
| --- | --- | --- |
| `play_session.gd` | 战斗初始化、回合开始、行动顺序、敌方回合、部分伤害结算、奖励、存档、高塔流程 | 保留单局和高塔生命周期；战斗时机交给 `BattleFlow`，成长和存档保留在 Run 层 |
| `battle_service.gd` | 玩家行动、敌方行动、技能 action 分发、命中、闪避、伤害、触发和部分效果 | 降为兼容门面；规则移入流程子模块和效果执行器 |
| `trigger_service.gd` | 触发筛选、状态修改、直接生命修改、额外伤害递归调用 | 保留触发筛选；效果通过统一执行器和嵌套行动队列执行 |
| `skill_action_service.gd` | 读取技能动作数组 | 保留数据读取；由 `EffectDispatcher` 负责执行器路由 |
| `data_catalog.gd` | 大量原版静态数据和查询方法 | 保留过渡期权威；通过 `RuntimeCatalog` 形成统一查询门面 |
| `main.gd` / `pre_run_view.gd` | 页面切换、控件组装、输入派发和部分页面状态 | 保留场景宿主；建立 View/Presenter/Intent 边界后渐进拆分 |

### 2.3 当前最危险的耦合

1. `BattleService` 的玩家技能和敌人技能存在两套执行路径，容易出现行为漂移。
2. `PlaySession._apply_damage_to_enemy()` 与 `BattleService.deal_damage()` 存在相近的命中/伤害处理路径。
3. `TriggerService` 直接修改运行时字典，并通过 `session.deal_damage()` 进入流程，容易绕过新时机。
4. 技能 action 的读取与 action 的执行边界不清晰，新增 action 会继续扩大 `BattleService`。
5. 许多模块通过 `PlaySession` 的具体方法和字段协作，无法用最小桩对象单独验证。
6. UI 视图虽然已经分文件，但缺少统一的只读状态和用户意图契约。
7. `ModLoader`、外部表和 `DataCatalog` 已有基础能力，但尚未形成统一的运行时内容注册门面。

## 3. 目标架构

### 3.1 总体分层

```text
内容定义层
  DataCatalog / JSON / ModLoader / TraitCatalog
        |
规范化与注册层
  SchemaRegistry / ContentValidator / RuntimeCatalog
        |
运行时状态层
  Combatant / BattleState / RunStateSnapshot
        |
决策与意图层
  PlayerActionAdapter / EnemyDecision / TargetResolver
        |
流程编排层
  BattleFlow / RoundFlow / ActionFlow / HitFlow
        |
规则与效果层
  SkillEffect / EffectDispatcher / Hit / Dodge / Damage / Status / Trigger
        |
成长与持久化层
  Encounter / Reward / RunProgress / SaveProfile / Serializer
        |
展示与输入层
  Main / ScreenCoordinator / Presenter / View / UIHelpers
        |
测试与诊断层
  Contract Tests / Service Tests / Integration Tests / UI Smoke / Trace
```

依赖方向必须从上到下或通过明确的端口返回，禁止下层反向依赖 UI；战斗规则不能反向依赖高塔奖励或页面节点。

### 3.2 项目层模块边界

| 模块 | 输入 | 输出 | 拥有的规则 | 禁止承担 | 当前映射 | 目标映射 |
| --- | --- | --- | --- | --- | --- | --- |
| 内容来源 | 原版常量、JSON、Mod 包 | 原始内容字典 | 文件发现、来源优先级、命名空间 | 改写战斗状态、访问 UI | `data_catalog.gd`、`data_repository.gd`、`mod_loader.gd` | `RuntimeCatalog` 的输入适配器 |
| Schema 与校验 | 原始字典、Schema、引用 | 规范化字典或结构化错误 | 必填字段、类型、引用、未知 action | 默认隐藏补齐核心业务效果 | `schema_registry.gd`、`content_validator.gd` | 保持现有服务，增加注册边界 |
| 运行时内容 | 规范化内容 | 按 ID 查询的内容 | 原版/外部/Mod 的一致查询、fallback | 直接读取 Mod 文件路径 | `DataCatalog`、`CatalogMigrationService` | `runtime_catalog.gd` |
| 状态转换 | 内容定义、装备、特性 | Combatant 运行时字典 | 默认值、特性状态、装备状态 | 决策行为、渲染 UI | `combatant.gd` | 保持 `Combatant`，只收敛输入 |
| 单局状态 | Combatant、战斗进度 | 可变战斗/单局状态 | 战斗当前状态和局内进度 | 解释技能、保存绝对路径 | `battle_state.gd`、`play_session.gd` | `BattleState` + `RunStateSnapshot` |
| 意图与决策 | 玩家输入、敌方状态 | ActionIntent | 目标、资源、冷却、行为选择 | 直接修改 HP 或 UI | `PlaySession`、`EnemyActionRules` | `decision/` 模块 |
| 流程编排 | 上下文、模块注册表 | 时机顺序、流程结果 | 回合/行动/命中阶段顺序、取消和结束 | 伤害公式、技能分支、存档 | `PlaySession`、`BattleService` | `BattleFlow`、子 Flow |
| 技能与效果 | Skill、Action、上下文 | EffectResult、事件 | action 路由、效果执行 | 页面逻辑、文件发现 | `BattleService`、`SkillActionService` | `SkillEffectModule`、`EffectDispatcher` |
| 命中与伤害 | HitContext、状态修正 | HitResult | 目标、闪避、暴击、护甲、格挡、生命 | 回合推进、奖励 | `BattleService`、`PlaySession` | `hit/` 模块 |
| 状态与触发 | Status、Trigger、事件 | 状态变化、嵌套行动 | 状态增删、条件、触发动作 | 绕过统一伤害路径 | `StatusService`、`TriggerService` | 保持服务，接入统一效果入口 |
| 行为决策 | 敌人和战场状态 | ActionIntent | 行为权重、冷却过滤、目标偏好 | 结算技能效果 | `enemy_action_rules.gd` | `EnemyDecisionModule` 门面 |
| 高塔与成长 | Floor、Encounter、Reward | 新遭遇、奖励、永久进度 | 教程、楼层、奖励和 NPC 解锁 | 处理命中细节 | `EncounterService`、`RewardService`、`RunProgressService` | 保持服务，拆出 Run 协调边界 |
| 持久化 | 稳定 ID、快照 | Profile、可恢复局内状态 | 版本迁移、缺失内容处理 | 保存对象引用、操作 UI | `SaveProfile`、`RunStateSerializer` | `RunStateSnapshot` + 现有服务 |
| 展示与输入 | Snapshot、事件、用户意图 | 视图、ActionIntent | 展示和输入转换 | 伤害、AI、图鉴第二份逻辑 | `main.gd`、`ui/*.gd` | `ScreenCoordinator`、Presenter、View |
| 测试与诊断 | 模块、上下文、事件 | 回归结果、Trace | 契约、服务、集成和 UI 冒烟 | 测试专用旁路代替正式路径 | `scripts/tests/` | 分层测试与可选 Trace |

## 4. 核心运行时契约

### 4.1 BattleFlow 与时机

目标文件：

- `GameProject/scripts/core/battle/battle_flow.gd`
- `GameProject/scripts/core/battle/battle_timing.gd`
- `GameProject/scripts/core/battle/battle_module.gd`
- `GameProject/scripts/core/battle/battle_module_registry.gd`

`BattleFlow` 只提供以下能力：

1. `start_battle(context)`：初始化流程并触发战斗开始时机。
2. `run_round(context)`：触发回合时机并请求行动顺序。
3. `submit_action(intent)`：将玩家或 AI 意图提交给行动流程。
4. `execute_skill(action_context)`：进入技能 action 流程。
5. `resolve_hit(hit_context)`：进入命中/闪避/伤害子流程。
6. `enqueue_nested_action(intent, parent_context)`：将触发器、反击、反伤等效果重新送回统一流程。
7. `finish_battle(result)`：返回胜负，不处理奖励和存档。

稳定时机由 `BattleTiming` 维护：

```text
battle_prepare
battle_start
battle_end

round_start_before
round_start
round_start_after
round_end_before
round_end

action_before
action_validate
action_start
action_execute
action_after
turn_end

skill_before
skill_effect_before
skill_effect
skill_effect_after
skill_after

hit_before
dodge_check
dodge
hit_confirmed
damage_before
damage_apply
damage_after
hit_after
```

时机不是效果，`on_hit_dealt`、`on_kill` 等仍属于内容触发事件，由 `TriggerService` 根据时机结果派发。

### 4.2 BattleModule

所有流程子模块实现统一契约：

```text
supports(timing) -> bool
priority(timing) -> int
execute(timing, context) -> BattleStepResult
```

`BattleStepResult` 至少支持：

| 结果 | 作用 |
| --- | --- |
| `continue` | 继续当前时机的下一个模块 |
| `skip` | 跳过当前效果或当前阶段的剩余处理 |
| `cancel_action` | 取消当前行动，不代表战斗结束 |
| `end_battle` | 立即结束战斗并返回结果 |
| `error` | 记录结构化错误并停止当前非法流程 |

模块注册顺序由显式优先级决定，不依赖脚本加载顺序或字典遍历顺序。

### 4.3 上下文对象

过渡期保留内部字典数据，但跨模块接口使用明确上下文对象：

#### `BattleContext`

```text
battle_state
combatants
current_actor
action_queue
round_index
rng
event_sink
flow_control
services
```

#### `ActionContext`

```text
actor
intent
skill
action
source
target_selection
cost
cancelled
parent_context_id
chain_id
```

#### `HitContext`

```text
source_actor
target_actor
source
skill_id
damage_type
base_damage
modified_damage
is_critical
is_dodged
armor_reduced
block_absorbed
final_damage
killed
parent_action_id
chain_id
```

模块不再要求接收完整 `PlaySession`，也不能通过任意私有方法修改高塔状态。

当前根目录 `GameProject/scripts/core/action_context.gd` 保留为旧伤害字典工厂。新流程契约使用 `GameProject/scripts/core/battle/battle_action_context.gd`（`BattleActionContext`）与 `battle_hit_context.gd`（`BattleHitContext`），避免在过渡期产生同名类冲突。

### 4.4 时机模块划分

| 目标模块 | 处理时机 | 责任 | 不处理 |
| --- | --- | --- | --- |
| `BattleSetupModule` | `battle_prepare`、`battle_start` | 建立战斗上下文、初始化 Combatant、战斗初始触发 | 奖励、存档 |
| `RoundLifecycleModule` | `round_start_*`、`round_end_*` | 冷却、状态 tick、回合资源、回合事件 | 选择技能、伤害 |
| `TurnOrderModule` | `round_start_after` | 根据敏捷和存活状态生成行动顺序 | 敌人行为权重 |
| `ActionLifecycleModule` | `action_*`、`turn_end` | 行动合法性、资源消耗、行动前后清理 | 具体 action 效果 |
| `PlayerActionModule` | `action_validate` | 将 UI 意图转为 ActionIntent | 计算命中 |
| `EnemyDecisionModule` | `action_validate` | 调用 `EnemyActionRules` 选择意图 | 执行技能 |
| `TargetResolutionModule` | `action_validate`、`hit_before` | 目标存在性、死亡、嘲讽重定向 | 修改 HP |
| `SkillEffectModule` | `skill_*` | 按技能 actions 顺序调度效果 | 直接实现每种效果 |
| `EffectDispatcher` | `skill_effect` | 根据 action type 路由执行器 | 回合推进 |
| `HitResolutionModule` | `hit_*` | 命中子流程编排并生成 HitResult | 具体伤害公式 |
| `DodgeResolutionModule` | `dodge_check`、`dodge` | 闪避判定、消耗躲避层、阻断伤害 | 护甲、格挡 |
| `DamageResolutionModule` | `damage_*` | 修正、暴击、护甲、格挡、抗性、生命变化 | 触发器筛选 |
| `HitTriggerModule` | `hit_after` | 命中、闪避、暴击、击杀和攻击结束事件 | 选择行动 |
| `TriggerDispatchModule` | 所有语义事件 | 过滤条件、调用触发动作、提交嵌套行动 | 绕过流程直接改生命 |
| `BattleResultModule` | `battle_end` | 判断胜负并输出 BattleResult | 奖励、存档、下一场 |

### 4.5 技能效果执行器

`SkillActionService` 继续负责读取和复制技能 `actions`，不负责具体执行。`EffectDispatcher` 负责注册以下执行器：

```text
damage          -> DamageEffectModule
modify_armor    -> ArmorEffectModule
apply_status    -> StatusEffectModule
gain_block      -> BlockEffectModule
gain_dodge      -> DodgeEffectModule
interrupt       -> InterruptEffectModule
heal            -> HealEffectModule
clear_debuffs   -> StatusEffectModule
set_duel        -> DuelEffectModule
set_deflect     -> DeflectEffectModule
summon          -> SummonEffectModule
```

玩家技能和敌方技能必须进入同一个 `SkillEffectModule`。角色差异只体现在行动者、目标解析和内容数据，不允许复制两套 action 解释器。

### 4.6 命中、闪避和伤害顺序

```text
TargetResolution
  -> hit_before
  -> DodgeResolution
      -> dodge_check
      -> 如果闪避：dodge -> hit_after
  -> 如果命中：hit_confirmed
  -> DamageResolution
      -> damage_before
      -> damage_apply
      -> damage_after
  -> HitTrigger
      -> on_hit_dealt / on_hit_received / on_critical / on_kill
  -> hit_after
```

命中和伤害必须保持两个概念：

- 闪避成功代表没有命中，不能产生普通伤害、护甲和格挡结算。
- 命中后伤害可能被护甲、格挡、抗性或状态修正为零，但仍可产生命中事件。
- 触发器产生的额外伤害、反击、反伤必须创建新的 `HitContext`，重新经过相同路径。

## 5. 非战斗模块边界

### 5.1 内容和 Mod

目标新增 `RuntimeCatalog` 作为运行时内容查询门面：

```text
DataCatalog / DataRepository / ModLoader
  -> SchemaRegistry + ContentValidator
  -> CatalogMigrationService
  -> RuntimeCatalog
  -> Combatant / Encounter / Reward / Encyclopedia / Battle modules
```

约束：

- `RuntimeCatalog` 只返回规范化内容，不暴露原始文件路径。
- `DataCatalog` 在迁移期间仍可作为默认后端，避免一次性重写全部数据。
- 未完成 parity 的外部表继续回退运行时表。
- Mod 内容必须经过 manifest、依赖、Schema、引用和命名空间校验。
- UI 和战斗模块不得直接读取 Mod 文件。

### 5.2 单局、高塔与成长

`PlaySession` 不再同时作为“战斗对象”和“全部游戏对象”。目标分为：

- `RunContext`：教程/正式楼层、当前场次、玩家局内成长、奖励状态。
- `BattleContext`：当前战斗、回合、行动队列和 Combatant。
- `ProgressionService` 族：遭遇、奖励、NPC、楼层和永久 Profile。
- `RunStateSerializer`：只在 `RunContext` 与稳定快照之间转换。

战斗结束只返回 `BattleResult`；奖励、解锁、保存和下一场由 Run 层处理。

### 5.3 持久化

保存边界保持现有规则：

- 保存稳定 ID、版本号和可迁移的规范化快照。
- 不保存 Godot 对象引用、Callable、节点路径或绝对文件路径。
- `RunStateSerializer` 负责字段归一化、旧字段迁移和缺失内容错误。
- `BattleState` 只通过 `RunStateSnapshot` 暴露给存档层。

目标接口：

```text
RunContext -> RunStateSnapshot -> RunStateSerializer -> SaveProfile
SaveProfile -> RunStateSerializer -> RunContext
```

### 5.4 UI

UI 分成四层：

```text
ScreenCoordinator
  -> Presenter / ViewModel
  -> View
  -> Godot Control 节点
```

- `ScreenCoordinator` 只负责页面切换和生命周期。
- Presenter 将 `RunContext`、`BattleState` 和图鉴索引转换为只读展示数据。
- View 只创建控件、展示文本和发出用户意图。
- `UIHelpers` 继续提供控件工厂和通用显示转换。
- UI 不计算伤害、不选择敌方行动、不复制图鉴效果逻辑。

现有 `main.gd`、`pre_run_view.gd`、`camp_view.gd`、`battle_view.gd` 采用渐进拆分，不在一次任务中重写全部页面。

### 5.5 测试与诊断

测试分为五层：

1. **契约测试**：时机顺序、模块注册、上下文和流程控制。
2. **服务测试**：命中、伤害、技能执行、状态、触发、内容校验、存档迁移。
3. **集成测试**：玩家和敌人共用技能路径、完整回合、胜负、奖励和保存。
4. **UI 冒烟**：节点、文本、按钮和回调，不读取图片资源。
5. **长时手工回归**：`playable_manual_test.gd`，不计入默认全量测试。

新增测试必须进入 `GameProject/scripts/tests/tutorial_and_floors_test.gd` 或明确标记为非默认入口；不得用测试专用旁路代替正式实时流程。

可选的 `BattleTrace` 只记录结构化事件：时机、上下文 ID、行动者、目标、结果和错误，不改变业务规则。

## 6. 兼容与迁移原则

### 6.1 兼容门面

迁移期间保留现有公开入口：

- `PlaySession.player_attack()`、`player_defend()`、`player_dodge()`、`use_skill()`。
- `PlaySession.deal_damage()` 作为兼容转发，但不得保留第二套结算逻辑。
- `BattleService` 先作为兼容门面，逐步转发到 `BattleFlow` 和模块注册表。

### 6.2 禁止行为

- 不恢复 `CombatEngine`、`RunSimulator` 或其他自动模拟路径。
- 不让 Mod 直接调用战斗模块私有方法。
- 不让 UI 监听事件后自行修改生命、状态或奖励。
- 不在 `BattleFlow` 中加入技能 ID、特性 ID 或数值分支。
- 不用模块拆分掩盖数据 Schema、存档迁移或测试缺口。
- 不在同一任务中同时改变战斗数值、文案和架构位置，除非验收明确要求。

### 6.3 跨平台

- 代码只使用 `res://`、`user://` 和 Godot 的路径 API。
- 测试脚本继续由 `run_tests.sh` 与 `run_tests.bat` 使用同一组入口和失败判定。
- 不写死 macOS 或 Windows 的业务路径。
- 日志和测试用户目录继续由测试入口隔离。

## 7. 实施阶段

| 阶段 | 目标 | 产出 |
| --- | --- | --- |
| A 基线 | 固化上下文、时机、模块注册和测试契约 | 无行为变化的新基础模块与契约测试 |
| B 战斗 | 抽取行动、技能、命中、闪避、伤害、触发和回合模块 | `BattleFlow` 可运行，`BattleService` 降为兼容门面 |
| C 内容 | 建立 `RuntimeCatalog`，统一原版、外部表和 Mod 查询 | 内容来源可替换，fallback 和 parity 不变 |
| D Run/存档 | 分离单局、高塔、奖励和存档快照 | 战斗结束不直接处理奖励/存档 |
| E UI | 建立页面协调、Presenter 和 View 契约 | UI 只展示状态和派发意图 |
| F 验收 | 完善契约、集成、UI、长时和跨平台测试 | 文档、清单、测试矩阵和代码一致 |

每个阶段拆为多个独立任务，具体任务、依赖、文件、测试和提交要求见 `docs/architecture/logic/modular_architecture_optimization_todo.md`。

## 8. 验收总标准

- `BattleFlow` 的流程代码不包含伤害公式、技能 ID、特性 ID 或 UI 分支。
- 玩家和敌人技能通过同一个 `SkillEffectModule` 与 `EffectDispatcher` 执行。
- 命中、闪避、伤害和命中触发分别有独立模块与服务级测试。
- 触发器产生的额外伤害、反击和反伤重新进入统一命中流程。
- `PlaySession` 只保留单局/高塔生命周期和兼容入口，不保留第二套伤害逻辑。
- `RuntimeCatalog` 统一原版、外部表和 Mod 内容查询，未完成 parity 的表继续 fallback。
- 存档只处理稳定快照，不保存运行时对象引用。
- UI 不计算战斗规则，不直接读取 Mod 原始文件。
- 每个任务都有独立测试、文档回写和单独提交记录。
- `sh run_tests.sh` 与 Windows 等价入口保持通过；不把未运行的长时手工测试称为全量通过。

## 9. 风险和待确认项

| 风险或问题 | 影响 | 默认决策 |
| --- | --- | --- |
| `BattleState` 当前字段较多 | 一次拆分容易造成存档和 UI 回归 | 先以 `BattleContext` 包装，不立即拆字段 |
| 现有 action 使用裸字典 | 类型边界不强 | 先建立上下文包装，保留内部字典兼容 |
| 触发器可能递归生成伤害 | 可能重入或无限链 | 引入 `chain_id`、父上下文和最大深度/重复保护 |
| 召唤改变敌方数组 | 旧 target index 可能失效 | 过渡期保留 index，新增稳定 combatant ID |
| `DataCatalog` 被多个 UI/服务直接引用 | RuntimeCatalog 迁移范围大 | 先加门面和 parity，再按领域替换调用方 |
| `main.gd` 和 `pre_run_view.gd` 较大 | UI 拆分可能超出单任务 | 先建立 View 契约，再逐个页面迁移 |
| 现有文档描述的是当前实现 | 设计与实现可能混淆 | 所有新设计标记“设计已确认待实现” |
