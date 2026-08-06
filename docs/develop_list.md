# Super Tower 开发清单

状态：持续维护。

## 执行规则

1. 按任务顺序执行，不跳过未完成任务。
2. 每个任务必须同时完成代码/数据、测试和对应 Markdown 文档回写。
3. 每完成一个任务，运行 `sh run_tests.sh`；Windows 使用等价的 `run_tests.bat`。
4. 测试通过后将任务改为 `[x]`，记录日期、测试命令和结果，并单独提交该任务的变更。
5. 不覆盖已有用户改动；提交时只暂存当前任务相关文件。
6. `run_tests.sh` 与 `run_tests.bat` 必须保持同一组测试入口和失败判定。

## 当前任务

### 模块化架构优化

> 总体方案：`docs/architecture/design/modular_architecture_optimization.md`；细分 TODO：`docs/architecture/logic/modular_architecture_optimization_todo.md`。后续必须按 ARCH 编号顺序执行；每项均需独立测试、文档回写和单独提交。

- [x] 任务 13｜建立模块化架构优化基线
  - 对应 `ARCH-00`：固化需求、目标模块边界、时机接口、迁移策略和执行协议。
  - 未修改运行时代码；Markdown 链接检查和 `sh run_tests.sh` 均已通过。

- [~] 任务 14｜拆分实时战斗流程与效果执行
  - 对应 `ARCH-01` ～ `ARCH-12`：先建立上下文、时机、模块注册和空流程，再按行动、技能、命中、闪避、伤害、触发、回合和结果逐项迁移。
  - 每个 ARCH 子项必须保持当前数值和流程兼容，并有单独的服务级或契约测试。
  - 已完成 `ARCH-01` ～ `ARCH-09`；下一个子项为 `ARCH-10`，建立命中触发与嵌套行动队列。

- [ ] 任务 15｜统一内容运行时注册边界
  - 对应 `ARCH-13` ～ `ARCH-14`：建立 `RuntimeCatalog`，统一原版、外部表、Mod 和图鉴的规范化查询。
  - 未完成 parity 的外部表必须继续 fallback，禁止改变原版内容权威。

- [ ] 任务 16｜分离 Run、成长与存档边界
  - 对应 `ARCH-15` ～ `ARCH-16`：建立 RunContext/快照边界，保持教程、楼层、奖励、NPC 和旧存档规则不变。

- [ ] 任务 17｜建立 UI 展示与意图边界
  - 对应 `ARCH-17`：渐进建立 Screen/Presenter/View 契约；UI 仅展示状态和派发意图。

- [ ] 任务 18｜完成架构诊断、跨平台回归与收尾审计
  - 对应 `ARCH-18` ～ `ARCH-20`：补齐结构化 Trace、默认测试入口、文档和旧路径审计。

### 数据契约与迁移

- [x] 任务 1｜修正外部怪物清单并补双向 parity
  - 对齐 `catalog_v1.json.enemy_unit_manifest` 与 `DataCatalog.NORMAL_UNITS`、`ELITE_UNITS`、`BOSS_UNITS` 的完整 ID 集合。
  - 增加外部有而运行时无、运行时有而外部无的失败断言。
  - 回写运行时数据管线和迁移说明。

- [x] 任务 2｜明确外部技能表的部分迁移状态
  - 将 `catalog_v1.json` 中技能表标记为“部分迁移/校验用表”，不得误称为完整迁移。
  - 测试外部表的字段兼容性，并明确完整技能表仍以 `DataCatalog.SKILLS` 为权威。
  - 同步技能目录和运行时数据管线文档。

- [x] 任务 3｜统一职业字段语义
  - 明确运行时职业 `unified` 与 `warrior`/`archer` 内容分类标签的边界。
  - 更新技能、装备 Schema 与兼容函数，避免将历史标签误当作运行时职业。
  - 增加统一职业过滤、旧存档迁移和 Mod 校验测试。

### 成长与战斗数据

- [x] 任务 4｜落地奖励运行时 Schema
  - 为奖励建立统一的 `source`、`target_type`、`effect`/效果参数字段，同时保留旧存档兼容读取。
  - 更新 `RewardService`、`RewardApplyService`、保存迁移和奖励测试。
  - 将文档状态从“目标字段”更新为当前真实契约。

- [x] 任务 5｜将可声明 Trait 迁移到数据目录
  - 在 `TraitCatalog` 中登记特性效果、状态和触发器定义。
  - 让 `Combatant` 通过统一入口加载数据，行为决策仍保留在 `EnemyActionRules`。
  - 增加 Trait 注册、状态生成和未知 Trait 校验测试。

### UI、图鉴与验收

- [x] 任务 6｜统一资源名称与职业头像映射
  - 将 `adrenaline` 在营地和百科显示为“肾上腺素”。
  - 明确 `unified` 头像的资源映射和无资源 fallback，不在 UI 中使用隐式“其他即专注”。
  - 增加 UI 文本冒烟断言并同步物品/技能文档。

- [x] 任务 7｜补齐 `throwing_dart` 图鉴与使用测试
  - 更新物品目录、增加稳定 ID 图鉴条目。
  - 覆盖生成、装备/消耗和效果路径；若暂不开放，明确数据可用状态。

- [x] 任务 8｜整理可玩手工测试入口
  - 将 `playable_manual_test.gd` 改为当前 `unified` 职业模型。
  - 明确它是长时手工回归还是默认自动测试；测试矩阵不得把未执行脚本称为全量通过。

### 扩展能力

- [x] 任务 9｜实现 Mod Loader 基础能力
  - 实现发现、manifest 解析、版本/依赖校验、注册、禁用和错误查询接口。
  - 保持稳定 ID、命名空间和跨平台路径规则。
  - 增加最小 Mod fixture 与 headless 测试。

- [x] 任务 10｜实现 Schema 注册与内容校验基础能力
  - 注册技能、状态、触发器、特性和奖励 Schema。
  - 校验必填字段、类型、引用、未知 action 和命名空间冲突。
  - 将现有 `data_validation_test.gd` 接入统一校验入口。

- [x] 任务 11｜推进原版外部规范化注册表
  - 建立迁移协调器；已完成 parity 的 `state_cards/classes` 支持受保护的外部读取。
  - `skills` 等部分迁移表强制回退运行时，所有表均有状态和 parity 报告。

- [x] 任务 12｜实现图鉴自动索引与本地化字段
  - 为技能、武器、物品、怪物和特性补齐 `name_key`、`description_key`、标签、稀有度和解锁条件。
  - 从规范化注册表生成图鉴索引，避免手工维护第二份效果逻辑。
  - 增加缺失条目和本地化键的自动化测试。

## 已完成历史

- [x] 移除自动模拟战斗路径，保留实时 `BattleService`。
- [x] 固定新角色前三场教程，教程不消耗正式第 1 层。
- [x] 固定正式楼层 10 场编排，正式第 1 层不是教程层。
- [x] 统一运行时角色和四个装备槽。
- [x] 将战斗状态、触发器和技能动作统一到现有服务。
- [x] 建立领域化三级 Markdown 文档结构。
- [x] 建立技能、武器、物品、怪物图鉴 Schema 与实体条目入口。
- [x] 完成结算主体迁移和 `BattleService` 服务级测试。
- [x] 完成 2026-08-05 首轮实现与文档一致性审计，报告见 `docs/testing/logic/implementation_audit.md`。

## 验收记录

### 2026-08-05

- 首轮审计基线：提交 `9d4102f`。
- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已确认旧问题中，计数器、技能费用、条件兼容、统一职业准备页和核心/UI 测试入口已经实现。
- 审计报告记录了当前外部清单、奖励 Schema、Trait、UI 资源、物品图鉴和手工测试入口差异。

### 2026-08-05 任务 1

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 外部 normal/elite/boss 怪物 manifest 已与运行时 ID 完全对齐，并加入双向 parity 测试。

### 2026-08-05 任务 2

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 外部技能表已标记为部分迁移，完整 parity 与子集兼容校验已明确分离。

### 2026-08-05 任务 3

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 运行时职业、内容分类和旧职业迁移已通过 `DataCatalog` 统一入口区分，并补充统一职业语义测试。

### 2026-08-05 任务 4

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 奖励已统一写入 Schema v1 字段，并对旧奖励和 active run 增加归一化兼容；补充奖励字段测试。

### 2026-08-05 任务 5

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 可声明 Trait 的 status、conditional_effects 和 triggers 已迁移到 `TraitCatalog`，并补充未知 ID 与运行时状态生成测试。

### 2026-08-05 任务 6

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 资源名称、统一职业头像兼容映射和缺失资源 fallback 已集中到数据/辅助层，并补充 UI 元数据测试。

### 2026-08-05 任务 7

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- `throwing_dart` 已补入物品目录和图鉴，并覆盖充能发现、消耗和下一次攻击加伤测试。

### 2026-08-05 任务 8

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 额外运行 `playable_manual_test.gd`：使用 `unified` 职业完成长时回归；该脚本继续作为非默认测试入口。

### 2026-08-05 任务 9

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- `ModLoader` 已实现发现、manifest 校验、依赖解析、内容注册/禁用、冲突保护和结构化错误；新增 fixture 与 `mod_loader_test.gd`。

### 2026-08-05 任务 10

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- `SchemaRegistry` 与 `ContentValidator` 已接入 Mod 内容加载和原版数据校验，覆盖必填字段、类型、命名空间、action/trigger 白名单和旧字段兼容。

### 2026-08-05 任务 11

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- `CatalogMigrationService` 已提供表状态、parity 报告、外部读取开关和运行时 fallback；当前仅完整 parity 表允许切换。

### 2026-08-05 任务 12

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- `EncyclopediaIndexService` 已生成稳定 ID、本地化键、标签、稀有度、解锁状态和来源字段；百科技能/特性列表改用自动索引，并补充缺失字段测试。

### 2026-08-06 任务 13

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已新增模块化架构优化方案、需求文档和 ARCH-00 ～ ARCH-20 TODO；方案覆盖内容注册、实时战斗、Run/存档、UI、测试和跨平台边界。

### 2026-08-06 ARCH-01

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已新增不依赖完整 `PlaySession` 的 Battle/Action/Hit 上下文和流程结果契约，并接入默认 headless 测试入口。

### 2026-08-06 ARCH-02

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已新增稳定 BattleTiming、BattleModule 接口和按优先级/注册顺序执行的 BattleModuleRegistry，并覆盖停止语义。

### 2026-08-06 ARCH-03

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已新增只负责时机串联的 BattleFlow，并为 BattleService 增加兼容转发入口；本项没有迁移现有技能或伤害逻辑。

### 2026-08-06 ARCH-04

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已新增统一 BattleActionIntent、玩家/敌人意图适配和目标解析模块；嘲讽、死亡目标回退和目标模式均通过契约测试。

### 2026-08-06 ARCH-05

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已新增 EffectExecutor、EffectDispatcher 和 SkillEffectModule，覆盖 action 路由、条件跳过、未知 action 和执行器停止结果；未迁移真实效果。

### 2026-08-06 ARCH-06

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已将非伤害 action 迁移到独立执行器，并删除 BattleService 中对应的重复实现；新增玩家/敌方真实入口回归测试。

### 2026-08-06 ARCH-07

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已新增统一 HitResolutionModule 和 BattleHitContext 转换入口，覆盖玩家/敌方目标、嘲讽、盟友索引和空目标错误。

### 2026-08-06 ARCH-08

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已将闪避判定和躲避层消耗迁移到 DodgeResolutionModule，并接入 BattleFlow 与兼容伤害入口；护甲、格挡和 HP 结算保持独立。

### 2026-08-06 ARCH-09

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已将状态修正、抗性、护甲、格挡、生命、反伤和裂变结算迁入 DamageResolutionModule；BattleService 仅保留兼容转发。
