# 模块化架构优化 TODO

状态：ARCH-00 ～ ARCH-18 已完成，ARCH-19 ～ ARCH-20 待执行。

方案：`docs/architecture/design/modular_architecture_optimization.md`

需求：`docs/requirements/2026-08-06-modular-architecture-optimization.md`

总清单：`docs/develop_list.md`

## 1. 执行协议

每个 TODO 子任务必须独立完成以下步骤：

1. 将本项标记为 `进行中`，不得同时处理未列入本项的行为改动。
2. 只修改本项“文件范围”内的代码、数据、测试和文档。
3. 先运行本项的“针对性测试”，再运行 `sh run_tests.sh`；Windows 使用 `run_tests.bat`。
4. 将实现状态、测试命令、结果和剩余风险回写到本 TODO 和对应领域 Markdown。
5. 通过后将本项改为 `[x]`，记录日期、测试命令和结果。
6. 单独提交本项相关文件，再向用户报告，然后才进入下一项。

### 状态约定

- `[ ]` 待执行
- `[~]` 进行中
- `[x]` 已完成并提交
- `[!]` 被阻塞，需要记录原因，不得伪装完成

### 独立性约束

- 一个任务必须有明确的输入、输出和最小测试桩。
- 一个任务不得同时改变无关数值、文案、UI 布局或数据迁移。
- 任务之间可以有依赖，但每项完成后都必须能通过自己的测试和完整回归。
- 如果发现当前任务必须扩大范围，先拆成新任务并更新本文件，不在原任务中隐式扩大。

## 2. 基线阶段

### [x] ARCH-00｜建立架构优化方案、需求和 TODO

- 状态：已完成于 2026-08-06；`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。
- 目标：形成唯一方案、需求、任务清单和执行协议。
- 文件范围：架构方案、需求文档、TODO、文档索引和开发清单。
- 针对性验证：Markdown 路径存在、链接目标存在、清单只新增本架构任务。
- 完整验证：`sh run_tests.sh`。
- 文档回写：本文件、`docs/develop_list.md`、`docs/system.index.md`。

## 3. 流程基础阶段

### [x] ARCH-01｜建立 BattleContext 与 BattleStepResult 契约

- 依赖：ARCH-00。
- 目标：新增 `BattleContext`、`ActionContext`、`HitContext`、`BattleStepResult`，内部可以包装现有 `BattleState` 和字典。
- 文件范围：`GameProject/scripts/core/battle/battle_context.gd`、`battle_action_context.gd`、`battle_hit_context.gd`、`battle_step_result.gd`、对应契约测试和战斗文档。根目录 `action_context.gd` 保留为旧伤害字典工厂，迁移完成前不得同名覆盖。
- 禁止：不改变玩家/敌人实际战斗行为，不移动 `BattleService` 逻辑。
- 针对性测试：`battle_context_contract_test.gd`，覆盖默认值、复制、链路 ID 和结果状态。
- 完成标准：模块不需要接收完整 `PlaySession` 才能构造上下文。
- 结果：已完成于 2026-08-06；新增 `BattleContext`、`BattleActionContext`、`BattleHitContext` 和 `BattleStepResult`，并接入默认测试链。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。

### [x] ARCH-02｜建立 BattleTiming、模块接口和注册表

- 依赖：ARCH-01。
- 目标：定义稳定时机、`BattleModule` 接口和按优先级排序的 `BattleModuleRegistry`。
- 文件范围：`GameProject/scripts/core/battle/battle_timing.gd`、`battle_module.gd`、`battle_module_registry.gd`、契约测试和架构文档。
- 禁止：不执行真实伤害，不引入技能 ID 分支。
- 针对性测试：`battle_module_registry_test.gd`，覆盖注册、优先级、同优先级稳定顺序、未知时机和取消结果。
- 完成标准：同一时机的调用顺序由显式优先级决定。
- 结果：已完成于 2026-08-06；新增 `BattleTiming`、`BattleModule` 和 `BattleModuleRegistry`，并接入默认测试链。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。

### [x] ARCH-03｜建立 BattleFlow 空流程和兼容入口

- 依赖：ARCH-02。
- 目标：新增只负责时机串联的 `BattleFlow`，让 `BattleService` 保持兼容门面。
- 文件范围：`GameProject/scripts/core/battle/battle_flow.gd`、`battle_service.gd` 的转发部分、`play_session.gd` 的最小接入、流程测试和文档。
- 禁止：不迁移伤害或技能实现，不改变胜负和奖励。
- 针对性测试：`battle_flow_contract_test.gd`，覆盖战斗开始、单回合、行动取消和战斗结束顺序。
- 完成标准：`BattleFlow` 本身不包含技能、特性、伤害数值和 UI 分支。
- 结果：已完成于 2026-08-06；新增空流程和 `BattleService.dispatch_battle_timing()` 兼容入口，真实战斗仍由旧路径执行。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。

## 4. 行动与技能阶段

### [x] ARCH-04｜统一 ActionIntent 与目标解析

- 依赖：ARCH-03。
- 目标：把玩家输入和敌人决策都转换为统一行动意图，集中处理目标存活、嘲讽和索引兼容。
- 文件范围：`decision/action_intent.gd`、`player_action_module.gd`、`enemy_decision_module.gd`、`target_resolution_module.gd`、相关测试和战斗文档。
- 禁止：不执行 action，不修改 HP。
- 针对性测试：`action_intent_test.gd`，覆盖玩家/敌人、无目标、死亡目标、嘲讽和非法技能。
- 完成标准：`EnemyActionRules` 只返回意图，不能直接执行效果。
- 结果：已完成于 2026-08-06；新增 `BattleActionIntent`、玩家/敌方意图适配和目标解析模块，复用现有 `CombatRules`/`EnemyActionRules`，不执行 action。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。

### [x] ARCH-05｜建立 EffectDispatcher 和技能效果入口

- 依赖：ARCH-04。
- 目标：将技能 `actions` 的读取、条件判断和执行器路由分开。
- 文件范围：`skill/skill_effect_module.gd`、`skill/effect_dispatcher.gd`、`skill_action_service.gd` 的兼容调整、Schema/测试/文档。
- 禁止：本项只接入路由和最小执行器，不迁移全部效果。
- 针对性测试：`effect_dispatcher_test.gd`，覆盖已知 action、未知 action、条件跳过和玩家/敌人共用入口。
- 完成标准：新增 action 的入口不再要求修改 `BattleFlow`。
- 结果：已完成于 2026-08-06；新增 EffectExecutor、EffectDispatcher 和 SkillEffectModule，当前仅提供路由契约，真实效果仍由旧 BattleService 执行。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。

### [x] ARCH-06｜抽取无伤害效果执行器

- 依赖：ARCH-05。
- 目标：先迁移 `gain_block`、`gain_dodge`、`heal`、`apply_status`、`modify_armor`、`interrupt`、`clear_debuffs`。
- 文件范围：`skill/effects/*_effect_module.gd` 中本项涉及的执行器、`StatusService`/`Combatant` 适配、效果测试和领域文档。
- 禁止：不迁移 damage、反击、反伤、召唤和决斗。
- 针对性测试：`skill_effect_module_test.gd`，覆盖每种 action 的目标、状态变化、日志事件和非法参数。
- 完成标准：玩家和敌方非伤害 action 不再依赖 `BattleService` 内部 `_execute_action_*` 分支。
- 结果：已完成于 2026-08-06；格挡、闪避、治疗、状态、护甲、打断和清除 Debuff 已迁移到独立执行器，BattleService 仅保留兼容调度和未迁移的伤害/反击/召唤/决斗分支。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。

## 5. 命中与伤害阶段

### [x] ARCH-07｜抽取 HitContext 和目标/命中流程

- 依赖：ARCH-05。
- 目标：建立一次命中的上下文和统一命中入口。
- 文件范围：`hit/hit_context.gd`、`hit/hit_resolution_module.gd`、命中测试和文档。
- 禁止：不改变伤害数值，不处理状态触发。
- 针对性测试：`hit_resolution_test.gd`，覆盖单目标、多段、目标死亡和目标被召唤/移除。
- 完成标准：所有伤害效果使用同一个 HitContext 创建入口。
- 结果：已完成于 2026-08-06；新增 `HitResolutionModule`、ActionContext 到 BattleHitContext 的转换和 BattleService 兼容入口，命中模块只解析目标并构造上下文，不修改伤害状态。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。

### [x] ARCH-08｜抽取闪避模块

- 依赖：ARCH-07。
- 目标：将闪避判定、躲避层消耗和 `dodge` 时机从伤害实现中分离。
- 文件范围：`hit/dodge_resolution_module.gd`、`hit/hit_result.gd`、闪避测试和文档。
- 禁止：不修改护甲、格挡和 HP 计算。
- 针对性测试：`dodge_resolution_test.gd`，覆盖闪避成功、躲避层消耗、无层数、敌方闪避和 `on_dodge`。
- 完成标准：闪避成功不会进入 damage apply；命中但零伤害仍可进入命中事件。
- 结果：已完成于 2026-08-06；新增 `DodgeResolutionModule`，接入 BattleFlow 和兼容 `deal_damage_to_target()` 路径，闪避层只在正伤害命中前消耗。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。

### [x] ARCH-09｜抽取伤害结算模块

- 依赖：ARCH-08。
- 目标：将原始伤害、充能、暴击、护甲、格挡、抗性、生命和击杀结果集中到 `DamageResolutionModule`。
- 文件范围：`hit/damage_resolution_module.gd`、`modifier_pipeline.gd` 的适配、`battle_service.gd` 的兼容转发、伤害测试和文档。
- 禁止：不改变已有数值和日志文案；不修改 AI 权重。
- 针对性测试：`damage_resolution_test.gd`，覆盖嘲讽、闪避、暴击、护甲、格挡、真实伤害、击杀和决斗清理。
- 完成标准：`PlaySession` 和 `BattleService` 不再存在第二套伤害主体。
- 结果：已完成于 2026-08-06；新增 `DamageResolutionModule`，处理状态修正、抗性、护甲、格挡、生命、暗影护甲反伤和裂变，`BattleService.deal_damage_to_target()` 已降为兼容转发。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。

### [x] ARCH-10｜建立命中触发与嵌套行动队列

- 依赖：ARCH-09。
- 目标：让 `TriggerService` 负责筛选条件，由统一队列提交额外伤害、反击、反伤和计数器动作。
- 文件范围：`trigger/trigger_dispatch_module.gd`、`battle_action_queue.gd`、`trigger_service.gd` 的适配、触发测试和文档。
- 禁止：不新增触发事件语义，不改变现有触发顺序。
- 针对性测试：`trigger_chain_test.gd`，覆盖额外伤害、反伤、反击、嵌套来源、父链 ID 和递归保护。
- 完成标准：`TriggerService` 不直接修改 HP，不直接绕过 `BattleFlow` 的命中流程。
- 结果：已完成于 2026-08-07；新增 `BattleActionQueue`（父链深度与最大 10 层递归保护）和 `TriggerDispatchModule`（触发动作统一执行器），`TriggerService` 降级为纯筛选器，伤害类触发动作经嵌套行动队列调用 `session.deal_damage()` 进入统一命中流程。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。

## 6. 回合与战斗结果阶段

### [x] ARCH-11｜抽取回合生命周期和行动顺序

- 依赖：ARCH-03、ARCH-10。
- 目标：将回合开始/结束、冷却、状态 tick、资源重置、先手和行动顺序从 `PlaySession` 迁入模块。
- 文件范围：`lifecycle/round_lifecycle_module.gd`、`turn_order_module.gd`、`play_session.gd` 的薄适配、回合测试和文档。
- 禁止：不迁移奖励、存档、楼层推进。
- 针对性测试：`round_lifecycle_test.gd`，覆盖教程/正式战斗、冷却、状态到期、先手、死亡单位和回合结束。
- 完成标准：`PlaySession` 不再直接实现战斗回合时机。
- 结果：已完成于 2026-08-07；新增 `TurnOrderModule`（行动顺序计算/玩家定位/调试文本）和 `RoundLifecycleModule`（回合开始、冷却、状态 tick、每回合效果、回合收尾、状态 Buff 抽取与先手判定），`PlaySession._begin_player_turn()` 降为一行薄适配，`BattleService` 的回合收尾段改调 `round_lifecycle.end_round()`。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。

### [x] ARCH-12｜抽取战斗结果和 Run 层回调

- 依赖：ARCH-11。
- 目标：战斗流程只返回 `BattleResult`，由 Run 层处理奖励、解锁、存档和下一场。
- 文件范围：`lifecycle/battle_result_module.gd`、`battle_result.gd`、`play_session.gd` 的回调适配、胜负测试和文档。
- 禁止：不改变奖励池、楼层或教程规则。
- 针对性测试：`battle_result_boundary_test.gd`，覆盖胜利、失败、玩家死亡、敌人全灭、奖励回调和重复结算。
- 完成标准：`BattleFlow` 不直接调用 `RewardService`、`SaveProfile` 或 UI。
- 结果：已完成于 2026-08-07；新增 `BattleResult` 纯数据类（outcome/reason/回合/楼层/战斗序号/教程标记/玩家血量/存活敌人/扩展数据）和 `BattleResultModule.judge()`（玩家死亡→defeat、敌人全灭→victory、未结束→null），`PlaySession._on_victory()/_on_defeat()` 改经 `battle_result.build_*` 生成结果后传给 `RunProgressService.on_victory/on_defeat`（新增可选 result 参数，行为不变），奖励、存档和下一场仍由 Run 层处理，`BattleFlow` 未新增对 `RewardService`、`SaveProfile` 或 UI 的直接调用。新增 `battle_result_boundary_test.gd` 覆盖胜利/失败判定、未结束返回 null、正式与教程失败、重复结算幂等和快照不变性。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。

## 7. 内容与运行时边界阶段

### [x] ARCH-13｜建立 RuntimeCatalog 查询门面

- 依赖：ARCH-00；不依赖战斗拆分，可独立实施。
- 目标：统一 `DataCatalog`、`DataRepository`、`CatalogMigrationService` 和 Mod 注册表的查询出口。
- 文件范围：`GameProject/scripts/core/runtime_catalog.gd`、内容适配器、数据测试和架构文档。
- 禁止：不切换未完成 parity 的外部表，不删除 `DataCatalog`。
- 针对性测试：`runtime_catalog_test.gd`，覆盖原版、完整外部表、部分表 fallback、Mod 命名空间和缺失 ID。
- 完成标准：调用方只通过 `RuntimeCatalog` 查询规范化数据，且 fallback 结果与当前实现一致。
- 结果：已完成于 2026-08-07；新增 `ContentTableAdapter`（表名 → DataCatalog 运行时表：state_cards/classes/skills/weapons/monsters/items，怪物数组和装备+消耗品已字典化）和 `RuntimeCatalog` 查询门面（`entry/has/table/resolved_table/runtime_table/external_table/table_status/can_use_external/parity_report/mod_content_table/load_mods/register_mod/active_mod_ids`）。查询优先级为 Mod 内容 > 已迁移的完整外部表 > 运行时表；`state_cards` 走外部表，`classes`/`skills` 因 parity 未完整继续 fallback 运行时表，行为与现状一致。新增 `runtime_catalog_test.gd` 覆盖原版查询、完整外部表、部分表 fallback、Mod 命名空间（fixture.good）和缺失 ID。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。调用方迁移（Combatant/Encounter/Reward/Encyclopedia）由 ARCH-14 负责。

### [x] ARCH-14｜建立内容引用与注册边界

- 依赖：ARCH-13。
- 目标：让 `Combatant`、Encounter、Reward、Encyclopedia 使用统一注册内容，并明确 Schema/Mod/图鉴的引用关系。
- 文件范围：`combatant.gd`、`encounter_service.gd`、`reward_service.gd`、`encyclopedia_index_service.gd` 的适配、parity 测试和领域文档。
- 禁止：不改变内容数值和解锁规则。
- 针对性测试：`content_registry_integration_test.gd`，覆盖技能、装备、怪物、奖励、特性和图鉴一致性。
- 完成标准：同一稳定 ID 在运行时和图鉴中来自同一规范化入口。
- 结果：已完成于 2026-08-07；`ContentTableAdapter` 扩展 `equipment`/`consumables`/`passive_skills`/`innate_skills` 表，`RuntimeCatalog` 新增 `monster_units`/`monster_group*`/`get_floor_battle_type`/`tutorial_unlock_ids`/`skill_class_compatible`/`equipment_class_compatible`/`innate_skills_table`。`EncounterService`、`RewardService`、`EncyclopediaIndexService` 注入可选 `catalog_instance`（无参构造保持兼容），原版数据查询统一走 catalog：遭遇单位经 `monster_units(rank)`、塔内奖励经 `runtime_table(...)`（Mod 内容不进塔内奖励池）、教程奖励经 `tutorial_unlock_ids()` 并加越界保护、图鉴索引经 `resolved_table(...)`。新增 `content_registry_integration_test.gd` 并接入默认入口，覆盖技能/装备/怪物一致性、遭遇生成、奖励引用和图鉴一致性；`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。`combatant.gd` 实际无内容表查询，本次未改动。

## 8. Run、存档与 UI 阶段

### [x] ARCH-15｜建立 RunContext 与存档快照边界

- 依赖：ARCH-12。
- 目标：将高塔/教程/奖励状态与战斗状态通过明确快照连接，保留旧存档迁移。
- 文件范围：`run_context.gd`、`run_state_snapshot.gd`、`run_state_serializer.gd`、`save_profile.gd` 的适配、存档测试和文档。
- 禁止：不迁移用户存档格式，不保存节点或对象引用。
- 针对性测试：`run_context_persistence_test.gd`，覆盖新建、保存、读取、旧字段迁移、缺失内容和中断恢复。
- 完成标准：Battle 层不直接读写 Profile，Run 层可以独立恢复快照。
- 结果：已完成于 2026-08-07；新增 `RunContext`（Run 层状态容器，`capture/capture_from_session/apply_data`，含旧存档迁移与楼层组历史恢复）与 `RunStateSnapshot`（run/battle 字段切分的纯数据快照，`to_dict/from_dict`，磁盘 active_run 格式与 version=4 不变）。`RunStateSerializer` 重写为委托 RunContext+RunStateSnapshot：save_data 输出保持扁平字段，load_save_data 保留版本检查、NPC 解锁副作用、战斗状态归一化与 charge 效果恢复；新增 `SaveProfile.read_active_run/write_active_run` 支持 Run 层独立读写 active_run（Profile 格式不变）。新增 `run_context_persistence_test.gd` 并接入默认入口，覆盖独立往返（不依赖 PlaySession）、run/battle 字段切分、旧存档迁移（legacy class_id、楼层组历史、tutorial 推断）、缺失默认值、中断恢复、SaveProfile 独立读写和 PlaySession 存档被 RunContext 独立恢复；`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。BattleService/BattleState 本就未直接读写 Profile，完成标准已满足。

### [x] ARCH-16｜建立成长与奖励协调边界

- 依赖：ARCH-15。
- 目标：明确遭遇、奖励、永久成长、NPC 解锁和战斗结果之间的单向调用关系。
- 文件范围：`run_progress_service.gd`、`encounter_service.gd`、`reward_service.gd`、`reward_apply_service.gd`、Run 测试和文档。
- 禁止：不调整奖励数值和楼层规则。
- 针对性测试：`run_progress_boundary_test.gd`，覆盖战斗结果、奖励选择、附着目标、楼层推进和存档回写。
- 完成标准：成长服务不反向调用命中/技能私有方法。
- 结果：已完成于 2026-08-07；`RunProgressService` 重写为 Run 层协调边界：`on_victory/on_defeat/advance_after_reward/apply_limited_post_battle_recovery/post_reward_heal_amount` 作为权威路径，胜利侧不再调用 PlaySession 私有方法，改经公开服务端口（`reward_apply.build_reward_options` 构建奖励、`run_progress.advance_after_reward` 推进），图鉴、塔币、Boss NPC 解锁与塔通关记录迁移为本服务私有实现（与旧方法等价）。`RewardApplyService` 的 `choose_reward`/`choose_reward_target` 不再调用 `session._advance_after_reward()`，改调 `session.run_progress.advance_after_reward(session)`；新增静态 `target_label` 替代 `_target_label`。新增 `run_progress_boundary_test.gd` 并接入默认入口，覆盖胜利（普通/Boss/通关/教程）、失败（正式/教程）、奖励选择（附着/直接生效）、楼层推进、塔通关、教程收尾和私有 API 依赖扫描（源码不引用 `battle_service`/`play_session`/`combat_engine` 及命中/技能私有方法）。`sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。奖励数值与楼层规则未调整，PlaySession 旧私有方法保留兼容（ARCH-20 统一清理），完成标准已满足。

### [x] ARCH-17｜建立 UI Screen/Presenter/View 契约

- 依赖：ARCH-12、ARCH-15；可与 ARCH-13 并行。
- 目标：让 UI 从只读展示状态生成控件，并通过统一意图入口调用 Run/Battle 层。
- 文件范围：`main.gd`、`ui_helpers.gd`、相关 View、Presenter/意图适配器、UI 契约测试和 UI 文档。
- 禁止：不读取图片资源，不重做视觉样式，不在本项拆完所有大页面。
- 针对性测试：`ui_contract_test.gd`、`pre_run_ui_smoke_test.gd`、`ui_click_smoke_test.gd`。
- 完成标准：UI 不计算伤害、不选择 AI 行动、不直接读取 Mod 文件。
- 结果：已完成于 2026-08-07；新增 `UiIntent` 意图门面（`bind/is_bound`，攻击/防御/闪避/血瓶/结束回合/技能/充能/消耗品/奖励选择/附着目标共 10 个意图，全部转发到 session 公开方法，未绑定 session 时 no-op），`main.gd` 的 8 个战斗回调与 2 个奖励回调改经 `ui_intent` 派发、返回主菜单重建 session 后重新 bind；新增 `ui_contract_test.gd` 并接入默认入口，源码扫描 `main.gd` 与 `scripts/ui/*.gd` 断言不出现伤害结算私有模式（`deal_damage(` 等 6 个）、敌人 AI 决策模式（`_enemy_attack(` 等 4 个）与 Mod 文件直读模式（`mods/`、`ModLoader` 等 4 个），且 `main.gd` 不直接调用 session 战斗/奖励方法；FakeSession 验证 10 个意图转发，unbound no-op；`sh run_tests.sh` 连续 10 轮通过，输出 `ALL TESTS PASSED`；`pre_run_ui_smoke_test.gd` 与 `ui_click_smoke_test.gd` 保持通过。

## 9. 诊断、测试与收尾阶段

### [x] ARCH-18｜建立 BattleTrace 与结构化事件断言

- 依赖：ARCH-10、ARCH-12。
- 目标：统一记录时机、上下文 ID、行动者、目标、结果和错误，帮助定位模块顺序问题。
- 文件范围：`battle_trace.gd`、日志适配、测试基类和诊断文档。
- 禁止：Trace 不得改变业务状态或作为业务判断依据。
- 针对性测试：`battle_trace_test.gd`，覆盖事件顺序、嵌套链路、错误和关闭 Trace。
- 完成标准：测试可以用事件顺序断言流程，不依赖 UI 文案。
- 结果：已完成于 2026-08-07；新增 `BattleTrace` 纯事件记录器（`record` 事件含 seq/kind/timing/context_id/actor/target/result/error/error_code/parent_seq/depth，`begin_span/end_span` 维护嵌套链路，`update_result` 回填结果，`errors/by_kind/sequence_of_*` 查询辅助，`set_enabled(false)` 后全部 no-op）与 `BattleTraceLogger` 日志适配（绑定 `log(message)` sink，`flush` 整批输出，静态格式化）；`BattleFlow` 接入 `set_trace`，`dispatch_timing` 对每个时机记录进入与结果事件，嵌套行动队列以 span 记录链路；新增 `battle_trace_assert.gd` 测试基类（`assert_event_kinds/timings/field/parented`）与 `battle_trace_test.gd` 并接入默认入口，覆盖时机顺序、结果与错误字段、嵌套链路、关闭 trace、日志格式与 flush、禁用跳过 sink；新增诊断文档 `docs/architecture/logic/battle_trace.md`；`sh run_tests.sh` 连续 5 轮通过，输出 `ALL TESTS PASSED`。

### [ ] ARCH-19｜补齐架构契约测试入口和跨平台回归

- 依赖：ARCH-01 至 ARCH-18 中已完成的任务。
- 目标：将所有契约测试接入默认 headless 入口，保持 Windows/macOS 入口一致。
- 文件范围：`GameProject/scripts/tests/tutorial_and_floors_test.gd`、`run_tests.sh`、`run_tests.bat`、测试矩阵和维护文档。
- 禁止：不把 `playable_manual_test.gd` 伪装成默认全量测试。
- 针对性测试：逐个新测试脚本；完整 `sh run_tests.sh`；Windows 使用 `run_tests.bat`。
- 完成标准：两套入口测试集合和失败判定一致，脚本加载错误会失败。

### [ ] ARCH-20｜删除重复兼容逻辑并完成文档审计

- 依赖：ARCH-04 至 ARCH-19。
- 目标：删除已迁移的重复方法，更新所有当前实现/设计状态，确认无旧路径残留。
- 文件范围：已迁移的旧核心文件、`docs/system.index.md`、各领域 README/logic、实现审计和本 TODO。
- 禁止：不顺手改无关业务规则。
- 针对性测试：全量测试、架构边界搜索、旧入口引用搜索和文档链接检查。
- 完成标准：代码、文档、TODO 和 `docs/develop_list.md` 的状态一致。

## 10. 统一验收门槛

每个任务都必须满足：

- 有独立测试或独立测试新增项。
- 有明确的文件范围和不变规则。
- `sh run_tests.sh` 通过；Windows 入口保持等价。
- 相关 Markdown 已回写，未把设计预留写成已实现。
- 本任务单独提交，提交信息包含任务 ID。
- 用户收到“完成项、测试结果、提交哈希、下一项”的报告后，才进入下一任务。
