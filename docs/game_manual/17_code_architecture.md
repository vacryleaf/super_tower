# 代码架构与后续开发约束

## 目标

本项目当前处于可玩原型阶段，但后续会继续增加职业、套装、敌人、技能、奖励和移动端界面。为了避免功能继续堆进单个脚本，后续开发必须遵守本文件的模块边界。

核心原则：**UI 只展示和收集输入，Session 只推进当前爬塔状态，Service 负责独立规则，Catalog 只放静态数据。**

## 当前代码边界

| 模块 | 文件 | 职责 |
| --- | --- | --- |
| UI 入口 | `GameProject/scripts/main.gd` | 渲染菜单、战斗页、奖励页、装备弹层、按钮连接和动画反馈。不得新增战斗规则、奖励规则、存档规则。 |
| 单局状态机 | `GameProject/scripts/core/play_session.gd` | 管理当前派遣的一局爬塔：楼层、战斗编号、敌人列表、行动力、阶段切换、调用服务。不得继续承载大块可独立服务。 |
| 奖励服务 | `GameProject/scripts/core/reward_service.gd` | 生成普通/精英/Boss 奖励池，判断奖励是否需要附着，处理奖励短标签和楼层奖励数值。 |
| 存档 Profile | `GameProject/scripts/core/save_profile.gd` | 读写 `user://savegame.json`，维护 profile 版本、队伍 roster、当前 active run 和旧存档兼容。 |
| 战斗服务 | `GameProject/scripts/core/battle_service.gd` | 承载玩家基础行动、技能释放、敌人回合、敌人行动和多段攻击等战斗流程。 |
| 充能服务 | `GameProject/scripts/core/charge_service.gd` | 收集装备/技能上的充能附着，处理每回合随机充能、一次性使用、绑定技能触发、攻击/防御倍率和追加结算。 |
| 状态 Buff 服务 | `GameProject/scripts/core/state_buff_service.gd` | 承载每回合状态 Buff 抽取、行动数值修正和一次性强关联 Buff 消耗。 |
| 单局推进服务 | `GameProject/scripts/core/run_progress_service.gd` | 承载胜利/失败、奖励后进入下一战、楼层推进、新手保护和战后有限恢复。 |
| 奖励应用服务 | `GameProject/scripts/core/reward_apply_service.gd` | 承载奖励选择、附着目标选择、新手固定解锁、Boss 技能分支和奖励选项构建。 |
| 遭遇服务 | `GameProject/scripts/core/encounter_service.gd` | 承载普通/精英/Boss 遭遇生成、敌人编队和每层战斗压力曲线。 |
| 战斗结算实体 | `GameProject/scripts/core/combatant.gd` | 玩家和敌人的统一伤害结算、护甲、格挡、闪避、敌人标准化。 |
| 自动战斗模拟 | `GameProject/scripts/core/combat_engine.gd` | 用于测试和数值估算的自动战斗逻辑。后续应逐步与真实战斗共用更多规则。 |
| 原型模拟器 | `GameProject/scripts/core/run_simulator.gd` | 创建角色、生成遭遇、自动跑新手引导和楼层，用于数值验证。 |
| 静态数据 | `GameProject/scripts/core/data_catalog.gd` | 职业、技能、基础装备、敌人模板、状态卡等原型静态表。后续内容量扩大后迁移到 JSON 或 Resource。 |
| 数据资源加载 | `GameProject/scripts/core/data_repository.gd` / `GameProject/data/catalog_v1.json` | 第一版外部数据资源入口。首批包含状态卡、职业和技能，并记录后续迁移顺序；运行时权威数据在迁移完成前仍以 `DataCatalog` 常量为准。 |
| UI View | `GameProject/scripts/ui/*.gd` | 营地页、战斗页部件、行动栏、战斗日志、奖励页和装备遮罩的界面构建。`main.gd` 只编排页面、连接回调和播放动画反馈。 |

## 强制约束

1. 新增奖励类型时，优先修改 `RewardService`，`PlaySession` 只负责接收选择并推进阶段。
2. 新增存档字段时，优先修改 `SaveProfile` 的 profile 读写边界，并在 `PlaySession._save_data()` / `_load_save_data()` 中只维护当前 active run 字段。
3. 新增伤害、护甲、格挡、闪避规则时，优先修改 `Combatant`，避免玩家和敌人各写一套结算。
4. 新增充能、状态 Buff 或奖励附着规则时，优先修改 `ChargeService`、`StateBuffService`、`RewardApplyService`，不要回填到 `PlaySession`。
5. 新增胜负、楼层推进、战后恢复或新手保护时，优先修改 `RunProgressService`。
6. 新增敌人编队、楼层难度和模拟策略时，优先修改 `RunSimulator` / `CombatEngine`，并补测试确认真实 UI 战斗没有偏离。
7. 新增 UI 页面时，不要继续扩大 `main.gd`；应拆成 `scripts/ui/` 下的独立 View 或 Panel 脚本，再由 `main.gd` 进行页面编排。
8. 新增职业、技能、套装和敌人内容时，先写入数据表或数据资源，不要把内容硬编码到流程函数里。
9. 每次重构或新增玩法后，至少运行三类测试：新手引导与前 10 层、手动战斗基准、真实 UI 按钮冒烟。

## 后续拆分顺序

1. 继续削薄 `PlaySession`：新增战斗规则必须进 `BattleService`，`PlaySession` 只保留阶段推进和当前局状态字段。
2. 继续削薄 `main.gd`：新增界面必须进 `scripts/ui/`，`main.gd` 只编排页面与连接回调。
3. 继续迁移遭遇规则：新增敌人编队和楼层压力曲线必须进 `EncounterService`。
4. 继续数据资源化：装备、套装、敌人、教程遭遇后续迁入 `GameProject/data/catalog_v1.json` 或拆分 JSON/Resource，并通过 `DataCatalog` 暴露索引入口。

## 本次拆分后的后续完整拆分建议

1. 将装备弹层继续从 `main.gd` 中迁出为真正的 `EquipmentView`，让 `main.gd` 不再创建装备栏和背包布局。
2. 将顶部楼层栏、结束爬塔按钮、结束页抽成 `RunHudView` / `EndScreenView`，进一步削薄页面编排。
3. 将敌人特性名称和说明从 `main.gd` 迁入数据表或 `TraitCatalog`，避免 UI 文件维护规则文本。
4. 将 `RunSimulator` 中的角色成长、装备附着和自动奖励应用拆成 `CharacterBuilder`、`AttachmentService`、`SimulationRewardPolicy`。
5. 将 `CombatEngine` 与真实手动战斗共用同一套 `BattleService`/`Combatant` 行动结算，减少模拟测试与真实 UI 玩法的偏差。
6. 将 `DataCatalog` 常量逐表迁移到 JSON 或 Godot Resource：先装备和套装，再敌人/遭遇，最后奖励池和教程配置。

## 不允许的开发方式

- 不允许把新的战斗规则直接写进 `main.gd`。
- 不允许把新的奖励池、奖励权重、奖励数值直接写进 `PlaySession`。
- 不允许绕过 `Combatant.apply_damage()` 自行扣血，除非是明确的特殊机制并配套测试。
- 不允许新增只能被 UI 使用、测试和模拟器无法复用的核心规则。
- 不允许提交没有测试覆盖的核心规则变更。
