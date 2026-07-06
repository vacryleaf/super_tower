# 代码架构与后续开发约束

## 目标

本项目当前处于可玩原型阶段，但后续会继续增加职业、套装、敌人、技能、奖励和移动端界面。为了避免功能继续堆进单个脚本，后续开发必须遵守本文件的模块边界。

核心原则：**UI 只展示和收集输入，Session 只推进当前爬塔状态，Service 负责独立规则，Catalog 只放静态数据。**

## 当前代码边界

| 模块 | 文件 | 职责 |
| --- | --- | --- |
| UI 入口 | `GameProject/scripts/main.gd` | 编排菜单、战斗页、奖励页、装备弹层、按钮回调和动画反馈。不得新增战斗规则、奖励规则、存档规则，也不得继续直接构建大型 UI 区块。 |
| 单局状态机 | `GameProject/scripts/core/play_session.gd` | 管理当前派遣的一局爬塔：楼层、战斗编号、敌人列表、行动力、阶段切换、调用服务。不得继续承载大块可独立服务。 |
| 奖励服务 | `GameProject/scripts/core/reward_service.gd` | 生成普通/精英/Boss 奖励池、Boss 永久装备分支、技能/塔内技能分支，判断奖励是否需要附着，处理奖励短标签和楼层奖励数值。 |
| 存档 Profile | `GameProject/scripts/core/save_profile.gd` | 读写 `user://savegame.json`，维护 profile 版本、队伍 roster、当前 active run 和旧存档兼容。 |
| 单局状态序列化 | `GameProject/scripts/core/run_state_serializer.gd` | 维护 active run 的保存/读取字段、载入后敌人标准化和局内状态恢复。新增局内存档字段必须优先改这里，`PlaySession` 只保留委托入口。 |
| 战斗服务 | `GameProject/scripts/core/battle_service.gd` | 承载玩家基础行动、技能释放、敌人回合、敌人行动和多段攻击等战斗流程。 |
| 共享战斗规则 | `GameProject/scripts/core/combat_rules.gd` | 承载真实战斗和自动模拟都必须共用的纯规则：敌人构建、存活统计、嘲讽目标、目标修正、敌人格挡/嘲讽清理、玩家/技能基础数值解析、敌人攻击段修正。新增可复用战斗规则应优先放到这里或 `Combatant`。 |
| 敌人行动规则 | `GameProject/scripts/core/enemy_action_rules.gd` | 统一真实战斗和自动模拟中的敌人意图、先手判断和多段攻击规则。 |
| 充能服务 | `GameProject/scripts/core/charge_service.gd` | 收集装备/技能上的充能附着，处理每回合随机充能、一次性使用、绑定技能触发、攻击/防御倍率和追加结算。 |
| 状态 Buff 服务 | `GameProject/scripts/core/state_buff_service.gd` | 承载每回合状态 Buff 抽取、行动数值修正和一次性强关联 Buff 消耗。 |
| 单局推进服务 | `GameProject/scripts/core/run_progress_service.gd` | 承载胜利/失败、奖励后进入下一战、楼层推进、新手保护和战后有限恢复。 |
| 奖励应用服务 | `GameProject/scripts/core/reward_apply_service.gd` | 承载奖励选择、附着目标选择、新手固定解锁、Boss 技能分支和奖励选项构建。 |
| 角色服务 | `GameProject/scripts/core/character_service.gd` | 承载角色创建、装备/技能解锁、奖励附着、附着目标选择、套装激活和属性重算。 |
| 模拟奖励策略 | `GameProject/scripts/core/simulation_reward_policy.gd` | 承载自动模拟使用的教程解锁、普通/精英/Boss 奖励应用和战后恢复策略。 |
| 遭遇服务 | `GameProject/scripts/core/encounter_service.gd` | 承载普通/精英/Boss 遭遇生成、敌人编队和每层战斗压力曲线。 |
| 战斗结算实体 | `GameProject/scripts/core/combatant.gd` | 玩家和敌人的统一伤害结算、护甲、格挡、闪避、敌人标准化。 |
| 自动战斗模拟 | `GameProject/scripts/core/combat_engine.gd` | 用于测试和数值估算的自动战斗逻辑。不得自建与真实战斗不同的目标、敌人构建、嘲讽、格挡清理等规则；必须优先调用 `CombatRules` / `EnemyActionRules` / `Combatant`。 |
| 原型模拟器 | `GameProject/scripts/core/run_simulator.gd` | 创建角色、生成遭遇、自动跑新手引导和楼层，用于数值验证。 |
| 静态数据 | `GameProject/scripts/core/data_catalog.gd` | 职业、技能、基础装备、敌人模板、状态卡等原型静态表。后续内容量扩大后迁移到 JSON 或 Resource。 |
| 数据资源加载 | `GameProject/scripts/core/data_repository.gd` / `GameProject/data/catalog_v1.json` | 第一版外部数据资源入口。已包含状态卡、职业、技能、套装清单、装备清单和敌人清单；运行时权威数据在完整迁移和测试前仍以 `DataCatalog` 常量为准。 |
| 特性目录 | `GameProject/scripts/core/trait_catalog.gd` | 承载敌人特性名称和悬浮说明，UI 只查询展示文本。 |
| UI View | `GameProject/scripts/ui/*.gd` | 营地页、顶部 HUD、战斗页部件、行动栏、战斗日志、奖励页、装备页、装备遮罩和结束页的界面构建。`main.gd` 只编排页面、连接回调和播放动画反馈。 |

## 强制约束

1. 新增奖励类型时，优先修改 `RewardService`，`PlaySession` 只负责接收选择并推进阶段。
2. 新增存档字段时，优先修改 `SaveProfile` 的 profile 读写边界和 `RunStateSerializer` 的 active run 字段；`PlaySession._save_data()` / `_load_save_data()` 只能保留委托入口。
3. 新增伤害、护甲、格挡、闪避规则时，优先修改 `Combatant`；新增目标选择、存活统计、敌人构建、通用战斗数值解析时，优先修改 `CombatRules`，避免真实战斗和模拟器各写一套结算。
4. 新增充能、状态 Buff 或奖励附着规则时，优先修改 `ChargeService`、`StateBuffService`、`RewardApplyService`，不要回填到 `PlaySession`。
5. 新增胜负、楼层推进、战后恢复或新手保护时，优先修改 `RunProgressService`。
6. 新增敌人意图、先手和多段攻击时，优先修改 `EnemyActionRules`，保证真实 UI 战斗和自动模拟共用规则；如果该规则还会影响数值修正或目标选择，则在 `CombatRules` 暴露统一入口。
7. 新增 UI 页面时，不要继续扩大 `main.gd`；应拆成 `scripts/ui/` 下的独立 View 或 Panel 脚本，再由 `main.gd` 进行页面编排。
8. 新增模拟奖励、自动跑层策略或角色成长逻辑时，优先修改 `SimulationRewardPolicy`、`CharacterService` 或 `CombatEngine`，不要回填到 `RunSimulator`。
9. 新增职业、技能、套装和敌人内容时，先写入数据表或数据资源，不要把内容硬编码到流程函数里。处于迁移期的 `catalog_v1.json` 字段必须与运行时 `DataCatalog` 保持一致；新增迁移字段必须补 parity 测试。
10. 新增套装效果时，基础属性和套装计数进 `CharacterService`；战斗开局类效果由 `PlaySession` 读取 `active_set_effects` 后调用已有战斗接口，不直接绕过战斗结算。
11. 每次重构或新增玩法后，至少运行三类测试：新手引导与前 10 层、手动战斗基准、真实 UI 按钮冒烟。

## 后续拆分顺序

1. 核心规则已经拆到当前原型的第一层边界：`PlaySession` 仍是局内状态机，但新增规则不能直接堆进去；应优先进入服务层。
2. 新增战斗规则必须进 `BattleService`、`CombatRules`、`Combatant`、`EnemyActionRules` 或对应服务，不能直接写入 `PlaySession`。
3. 新增 UI 必须进 `scripts/ui/`，不能直接写入 `main.gd` 的渲染函数。
4. 继续数据资源化：装备、套装、敌人、教程遭遇后续迁入 `GameProject/data/catalog_v1.json` 或拆分 JSON/Resource，并通过 `DataCatalog` 暴露索引入口；迁移一张表必须配套测试，不能一次性切换未验证运行时来源。

## 不允许的开发方式

- 不允许把新的战斗规则直接写进 `main.gd`。
- 不允许把新的奖励池、奖励权重、奖励数值直接写进 `PlaySession`。
- 不允许绕过 `Combatant.apply_damage()` 自行扣血，除非是明确的特殊机制并配套测试。
- 不允许新增只能被 UI 使用、测试和模拟器无法复用的核心规则。
- 不允许在 `CombatEngine` 中新增一套与真实战斗不同的敌人构建、目标选择、嘲讽、格挡、闪避规则。
- 不允许修改 `catalog_v1.json` 中已迁移字段而不同步 `DataCatalog`，除非同一提交完成运行时切换和 parity 测试更新。
- 不允许提交没有测试覆盖的核心规则变更。
