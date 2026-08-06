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
- [~] 按 ARCH-01 ～ ARCH-20 逐项完成流程、内容、Run、存档、UI、测试和收尾迁移；当前进行 ARCH-10。

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
