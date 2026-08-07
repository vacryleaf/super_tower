# Super Tower 项目架构地图

状态：已实现 + 持续维护。

本文是顾问 Ghost 的项目知识入口。它用于缩短定位时间，但不能替代对当前代码的验证。若本文、其他 Markdown 与代码不一致，必须指出冲突并以当前实现为准。

## 权威入口

1. `docs/system.index.md`：Markdown 文档索引、全局硬规则和代码权威入口。
2. 各领域的 `README.md`：领域边界和二级文档导航。
3. 各领域 `design/`、`logic/`、`data/`：设计、流程和 Schema。
4. `GameProject/scripts/core/`：运行时真实行为。
5. `GameProject/scripts/tests/` 与 `run_tests.sh`、`run_tests.bat`：验收入口。

## 当前运行时主链路

```text
内容定义
  -> DataCatalog / TraitCatalog / DataRepository
  -> 领域服务按 ID 取得并规范化数据
  -> Combatant 转换角色、装备、怪物和能力为运行时字典
  -> PlaySession 创建遭遇并管理单局生命周期
  -> BattleService 编排实时行动和战斗结果
  -> SkillActionService 解释技能 actions
  -> ActionPipeline 处理行动上下文的通用修正
  -> StatusService 处理状态、持续时间和条件效果
  -> TriggerService 按事件执行触发动作
  -> BattleState / PlaySession 同步状态、奖励、存档和 UI
```

当前唯一实时战斗路径是：

`PlaySession -> BattleService -> ActionPipeline / StatusService / TriggerService`

敌人行为由 `enemy_action_rules.gd` 决策；UI 只展示状态和派发玩家意图。

## 已确认待实现的模块化优化

当前运行时边界仍以上述实现为准。2026-08-06 已确认一套渐进式模块化优化方案，目标是让 `BattleFlow` 仅负责编排时机，将行动、技能、命中、闪避、伤害和触发拆为可独立测试的模块，并同步建立内容注册、Run/存档、UI 和测试边界。实施顺序和验收以 `docs/architecture/design/modular_architecture_optimization.md`、`docs/architecture/logic/modular_architecture_optimization_todo.md` 和 `docs/develop_list.md` 为准；这些均为设计/计划，不能视为当前已实现行为。

## 模块边界

| 模块 | 输入 | 输出 | 当前映射 | 不应承担 |
| --- | --- | --- | --- | --- |
| 内容定义 | 静态常量、JSON 表、未来 Mod 文件 | 原始内容字典 | `data_catalog.gd`、`trait_catalog.gd`、`catalog_v1.json`、`data_repository.gd` | 直接修改战斗状态、依赖 UI 场景 |
| 规范化与校验 | 原始内容、Schema、引用 ID | 可注册的规范化字典或结构化错误 | `docs/architecture/data/`、`docs/architecture/logic/content_validation.md`，当前原版校验由测试覆盖部分路径 | 静默接受未知 action、隐藏补齐核心效果 |
| 状态转换 | 角色、装备、怪物、能力定义 | 运行时 `Dictionary` 状态 | `combatant.gd` 的 `from_player()`、`from_enemy_unit()`、`scaled_enemy()`、`fixed_enemy()`、`_apply_trait_statuses()` | 决策敌人下一步行为、更新 UI 控件 |
| 行为决策 | 行动者状态、行为权重、敌我关系 | 敌方行动或技能选择 | `enemy_action_rules.gd` | 直接编排整场战斗、把规则复制到 UI |
| 战斗流程 | `PlaySession`、`BattleState`、玩家输入、敌方选择 | 行动顺序、结算结果、战斗日志和胜负 | `play_session.gd`、`battle_service.gd`、`battle_state.gd` | 维护静态内容表、把每个技能写成独立分支 |
| 动作与效果解释 | 技能 `actions`、行动上下文、状态定义 | 伤害、格挡、治疗、状态、召唤等效果 | `skill_action_service.gd`、`action_pipeline.gd`、`status_service.gd` | 读取 UI 资源路径、保存业务流程进度 |
| 事件与触发 | 事件名、条件、actions | 触发后的统一效果 | `trigger_events.gd`、`trigger_service.gd` | 在 UI 监听事件后自行改战斗状态 |
| 共享战斗规则 | 攻击、伤害、护甲、状态相关参数 | 可复用的规则计算结果 | `combat_rules.gd`、`modifier_pipeline.gd`、`condition_evaluator.gd`、`dynamic_value_resolver.gd` | 维护页面生命周期或存档槽位 |
| 成长与遭遇 | 高塔进度、楼层、奖励池、NPC、角色 | 新遭遇、奖励、局内和永久进度 | `encounter_service.gd`、`reward_service.gd`、`reward_apply_service.gd`、`run_progress_service.gd`、`character_service.gd` | 结算技能内部 action、直接渲染控件 |
| 持久化 | Profile、局内快照、稳定 ID | 可恢复的状态或迁移错误 | `save_profile.gd`、`run_state_serializer.gd`、`play_session.gd` | 保存绝对路径、保存不可迁移的对象引用 |
| 展示与输入 | 规范化数据、运行时快照、玩家点击 | UI 状态和用户意图 | `GameProject/scripts/ui/` | 计算伤害、选择敌方行为、定义独立图鉴数据 |
| 测试与知识 | 测试场景、验收标准、文档索引 | 回归信号和可复用规则 | `GameProject/scripts/tests/`、`docs/testing/`、`docs/system.index.md` | 用测试绕过正式运行时路径 |

## 数据驱动规则

- 技能、武器、物品、怪物、状态和触发器优先由稳定 ID 和声明式字段描述。
- 技能效果优先使用 `actions`；状态效果优先使用 `effects`、`conditional_effects`、`tick_effects` 和 `triggers`。
- 新增行动类型时要同时考虑 Schema 注册、解释器、日志、图鉴和测试。
- 跨领域引用使用 ID，不直接保存对象；Mod ID 必须带命名空间并且不能覆盖原版 ID。
- 图鉴和 UI 读取规范化数据，不能复制一套运行时效果逻辑。

## 新功能归属决策表

| 需求特征 | 首选位置 | 典型做法 |
| --- | --- | --- |
| 新增内容、数值、技能或怪物 | 数据定义与 Schema | 增加数据字段或条目，补齐校验和图鉴入口 |
| 角色或装备改变初始状态 | `combatant.gd` | 通过 `_apply_trait_statuses()` 或已有状态转换入口生成运行时状态 |
| 状态持续、条件效果或事件反应 | `status_service.gd` / `trigger_service.gd` | 扩展统一状态或触发 Schema，不在流程层硬编码 |
| 敌人选什么行动 | `enemy_action_rules.gd` | 使用状态、能力和行为权重决定行动 |
| 所有行动都适用的数值修正 | `action_pipeline.gd` / `modifier_pipeline.gd` | 通过行动上下文收集通用修正 |
| 新的技能动作类型 | Schema + `skill_action_service.gd` + 日志 + 测试 | 先登记解释器支持，再让数据使用 |
| 一场战斗如何开始、结束或切换 | `play_session.gd` / `battle_service.gd` | 保持流程层只做编排，不定义内容细节 |
| 存档字段、局内快照或迁移 | `save_profile.gd` / `run_state_serializer.gd` | 保存稳定 ID 和规范化快照，补迁移及缺失内容策略 |
| 页面展示和用户输入 | 对应 `scripts/ui/` | UI 读取状态、派发意图，不计算规则 |

## 当前明确不是实现的内容

- 完整 Mod Loader 尚未落地；`docs/architecture/logic/mod_loading_pipeline.md` 记录的是设计预留。
- 通用内容注册、完整 Schema 校验和跨领域引用校验仍有设计待实现部分。
- 自动模拟战斗脚本已经删除；不要恢复 `CombatEngine`、`RunSimulator`、`SimulationRewardPolicy` 或 `ChargeSimulator`。
- 旧职业、旧装备部位和旧套装字段只用于迁移或历史资料，不能作为新功能依据。

## 领域导航

| 领域 | 入口 | 主要问题 |
| --- | --- | --- |
| 架构 | `docs/architecture/` | 数据驱动、Schema、扩展边界和 Mod 预留 |
| 战斗 | `docs/combat/` | 行动、伤害、状态、触发和实时流程 |
| 技能 | `docs/skills/` | 技能数据、动作执行和图鉴 |
| 武器 | `docs/weapons/` | 武器属性、普攻和技能绑定 |
| 物品 | `docs/items/` | 资源、消耗品、奖励和图鉴 |
| 怪物 | `docs/monsters/` | 单位、群落、能力、遭遇和行为 |
| 成长与高塔 | `docs/progression/` | 教程、楼层、奖励、Profile 和局内成长 |
| UI | `docs/ui/` | 页面职责、输入和图鉴展示 |
| 测试与维护 | `docs/testing/` | 测试矩阵、验收和文档同步 |

## 测试入口

跨平台入口是仓库根目录的 `run_tests.sh` 和 `run_tests.bat`，都以 Godot headless 运行 `tutorial_and_floors_test.gd` 并检查脚本加载和编译错误。需求分析时应根据风险补充具体测试脚本，而不是只依赖总入口。

## 顾问使用准则

回答一个功能问题时，至少定位到：

1. 数据或输入的来源。
2. 状态转换或规范化入口。
3. 流程、解释器或决策入口。
4. 状态如何同步到 UI 或存档。
5. 直接覆盖它的测试。

提出模块拆分时，先复用上述边界，再讨论是否需要新模块。能用现有 Schema 和服务表达的功能，不应先建议新框架。
