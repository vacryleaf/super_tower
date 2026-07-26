# 无限爬塔卡牌游戏手册

## 项目定位

本项目当前是一款面向 Windows 与 macOS 开发环境的 2D 回合制构筑 Roguelite 爬塔原型。玩家创建角色并选择职业，进入无限高塔后通过战斗、奖励选择、装备构筑、技能配置和局内附着不断强化角色，尝试挑战更高层数。卡牌是重要构筑与附加能力来源，但战斗主轴不是纯抽牌打牌，而是围绕普通攻击、防御、躲避和 4 个职业技能展开。

当前已实现职业包含战士和弓箭手。角色拥有装备栏、消耗品、永久技能、局内奖励附着和套装效果。当前实现的套装包括清辉流霜、斯巴达、拳击手、马戏团、丛林和游侠；远期更多套装矩阵不再作为当前实现描述。每个角色最多装备 4 个技能。塔内每层固定需要完成 10 场战斗，当前敌人来自 5 个怪物群落。每个新角色首次进入高塔时会进入新手引导层，固定解锁基础装备和第 1 个技能；引导完成后进入正式奖励循环。

## 核心循环

1. 创建角色，选择职业。
2. 配置初始装备、初始技能与通用状态卡抽取配置。
3. 进入高塔第 1 层。
4. 每层依次完成 10 场战斗。
5. 新角色首次游玩时，第 1 层新手引导依次解锁头部、上身、腰部、下身、手部、护腿、脚部、武器、副手装备，并在 Boss 战后解锁第 1 个技能。
6. 第 2 层开始，每次普通战斗胜利后从 3 个局内奖励中选择 1 个，精英怪为 4 选 1，Boss 当前提供 3 个局内奖励并额外加入 1 个永久装备分支；战斗内抽取的状态卡主要提供行动倍率、确定暴击、强化躲避、强化防御和紧急回撤修饰。
7. 装备卡只在 Boss 关卡的永久装备分支中出现；Boss 技能奖励和塔内技能池仍是后续设计，不按当前实现验收。
8. 将局内数值奖励附着到已装备装备或已装备技能上；基础行动附着和完整塔内附着卡池仍是后续设计。
9. 完成当前层第 10 场战斗后进入下一层。
10. 角色死亡、主动退出或重新开始时，清空局内奖励附着。

## 推荐引擎

当前项目使用 **Godot 4.5 Stable + GDScript** 开发原型。

选择理由：

- 本项目主要由 2D UI、行动按钮、状态卡、数据表和回合制逻辑组成，Godot 的 Control UI 系统、Resource 数据资源和信号机制适合快速迭代。
- Godot 免费开源，采用 MIT 许可，适合独立项目和长期商业化。
- 当前开发与验证优先覆盖 Windows 和 macOS；Godot 后续仍可导出其他平台，但移动端不是当前实现验收口径。
- GDScript 与 Godot 编辑器集成度高，适合先做玩法闭环，再逐步抽象数据和工具链。

Unity 也可以完成该项目，尤其适合已有 Unity 团队或需要大量第三方商业插件的情况。但对本项目的首版而言，Godot 的授权成本、工程复杂度和 2D UI 开发负担更低。

参考：

- [Godot 官方导出文档](https://docs.godotengine.org/en/stable/tutorials/export/index.html)
- [Godot 许可说明](https://godotengine.org/license/)
- [Unity 平台开发文档](https://docs.unity3d.com/Manual/PlatformSpecific.html)

## 文档目录

- [01_core_loop.md](01_core_loop.md)：核心流程、单局结构、继承边界。
- [02_classes.md](02_classes.md)：战士、弓箭手、职业技能与 4 技能槽规则。
- [03_cards.md](03_cards.md)：装备卡、技能卡、局内奖励附着、状态卡。
- [04_equipment.md](04_equipment.md)：完整装备栏与装备卡设计。
- [05_tower_rewards.md](05_tower_rewards.md)：塔层结构、怪物节奏、奖励池。
- [06_fusion_system.md](06_fusion_system.md)：当前局内奖励附着规则，以及未实现融合设计边界。
- [07_combat.md](07_combat.md)：回合制战斗、基础行动、状态卡、行动力、状态。
- [08_progression_balance.md](08_progression_balance.md)：成长边界、数值曲线、奖励生成。
- [09_v1_content_tables.md](09_v1_content_tables.md)：首版内容表。
- [10_ui_ux.md](10_ui_ux.md)：当前 1280x720 横屏界面方案和后续移动适配注意事项。
- [11_technical_recommendation.md](11_technical_recommendation.md)：Godot 4.5 技术落地建议。
- [12_equipment_generation.md](12_equipment_generation.md)：首版基础装备与套装生成表。
- [13_set_equipment_items.md](13_set_equipment_items.md)：套装装备逐件明细与基础属性。
- [14_enemy_design.md](14_enemy_design.md)：当前敌人群落、单位、特性、技能和楼层数值规则。
- [15_development_task_breakdown.md](15_development_task_breakdown.md)：无美术首版原型的开发任务拆解。
- [16_tutorial_design.md](16_tutorial_design.md)：新手引导层、固定战斗、固定解锁和失败保护。
- [17_code_architecture.md](17_code_architecture.md)：当前代码结构、模块职责和后续开发约束，后续开发不得偏离该整体框架。
- [18_current_implementation.md](18_current_implementation.md)：当前真实代码实现总览、运行入口、服务职责、测试、存档和跨平台约束。
- [../战斗回合详述.md](../战斗回合详述.md)：当前真实战斗与模拟战斗的完整回合链路。
