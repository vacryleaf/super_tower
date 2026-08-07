# 开发修复清单

状态：持续维护。

- [x] 移除自动模拟战斗路径，保留实时 BattleService。
- [x] 固定新角色前三场教程，教程不消耗正式第 1 层。
- [x] 固定正式楼层 10 场编排，正式第 1 层不是教程层。
- [x] 统一运行时角色和四个装备槽。
- [x] 将战斗状态、触发器和技能动作统一到现有服务。
- [x] 建立领域化三级 Markdown 文档结构。
- [x] 建立技能、武器、物品、怪物图鉴 Schema 与实体条目入口。
- [x] 预留 Mod manifest、内容 Schema 和加载管线文档。
- [x] 实现 Mod Loader 的发现、校验、依赖、注册和禁用接口。
- [x] 增加 Mod 内容加载与图鉴索引的自动化测试。
- [x] 将原版静态表推进到受保护的外部规范化注册表读取；未完成 parity 的表保持运行时 fallback。
- [x] 为当前图鉴实体补齐本地化键、描述和解锁条件。
- [x] 建立模块化架构优化基线与实施 TODO；详见 `docs/architecture/logic/modular_architecture_optimization_todo.md` 的 `ARCH-00`。
- [~] 按 ARCH-01 ～ ARCH-20 逐项完成流程、内容、Run、存档、UI、测试和收尾迁移；当前进行 ARCH-11。

每完成一项，运行 `run_tests.bat` 或 `run_tests.sh`，并在本文件记录日期、命令和结果。

## 2026-08-03 验收记录

- `HOME=/tmp/super_tower_test_home sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`，包含核心 headless、准备页 UI 冒烟和战斗点击 UI 冒烟。
- UI 冒烟只检查节点、文本和交互状态，不读取或生成图片资源。

## 2026-08-06 架构优化基线验收

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已建立模块化架构方案、需求和 ARCH TODO；后续任务必须逐项测试、文档回写和单独提交。

### ARCH-01

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已建立 BattleContext、BattleActionContext、BattleHitContext、BattleStepResult 和契约测试；根目录旧 `ActionContext` 保持兼容。

### ARCH-02

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已建立 BattleTiming、BattleModule、BattleModuleRegistry 和注册顺序/停止语义测试。

### ARCH-03

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已建立 BattleFlow 空流程、时机串联测试和 BattleService 兼容转发入口；真实战斗路径未改变。

### ARCH-04

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已建立 BattleActionIntent、PlayerActionModule、EnemyDecisionModule 和 TargetResolutionModule；未执行 action 或修改战斗状态。

### ARCH-05

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已建立 EffectExecutor、EffectDispatcher 和 SkillEffectModule；条件、未知 action 和停止语义均有测试覆盖。

### ARCH-06

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已迁移格挡、闪避、治疗、状态、护甲、打断和清除 Debuff 执行器，并覆盖玩家/敌方 action 入口。

### ARCH-07

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已建立 HitResolutionModule、BattleHitContext 转换和命中上下文测试；本项未改变闪避或伤害结算。

### ARCH-08

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已建立 DodgeResolutionModule，覆盖 BattleFlow 闪避时机、躲避层消耗和兼容伤害入口。

### ARCH-09

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已建立 DamageResolutionModule，覆盖护甲、格挡、真实伤害、抗性和暗影护甲反伤；BattleService 伤害主体已转发。

### ARCH-10

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已建立 TriggerDispatchModule 与 BattleActionQueue；TriggerService 降级为纯筛选器，伤害类触发动作经嵌套行动队列进入统一命中流程，并带父链深度与递归保护。

### ARCH-11

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已建立 TurnOrderModule 与 RoundLifecycleModule；回合开始、冷却、状态 tick、每回合效果、回合收尾、状态 Buff 抽取和先手判定迁入模块，PlaySession 回合入口降为薄适配；新增 `round_lifecycle_test.gd`。

### ARCH-12

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已建立 BattleResult 数据类与 BattleResultModule 胜负判定；PlaySession 胜负回调改经模块生成结果后传给 RunProgressService（新增可选 result 参数，行为不变）；新增 `battle_result_boundary_test.gd`，覆盖胜利/失败判定、未结束返回 null、正式/教程失败、重复结算幂等和快照不变性。

### ARCH-13

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已建立 ContentTableAdapter 与 RuntimeCatalog 查询门面（Mod 内容 > 完整外部表 > 运行时表，parity 未完整继续 fallback）；`state_cards` 走外部表，`classes`/`skills` 保持运行时表；新增 `runtime_catalog_test.gd`，覆盖原版、外部表、fallback、Mod 命名空间和缺失 ID。

### ARCH-14

- `sh run_tests.sh`：通过，输出 `ALL TESTS PASSED`。
- 已扩展 ContentTableAdapter（`equipment`/`consumables`/`passive_skills`/`innate_skills`）与 RuntimeCatalog 系列内容查询接口；EncounterService/RewardService/EncyclopediaIndexService 注入可选 `catalog_instance`（无参构造兼容），遭遇单位、塔内奖励（仅运行时表，Mod 不进塔内奖励池）、教程解锁（带越界保护）和图鉴索引统一走 catalog；新增 `content_registry_integration_test.gd` 并接入默认入口，覆盖技能/装备/怪物一致性、遭遇生成、奖励引用和图鉴一致性。
