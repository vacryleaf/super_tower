# 无限爬塔卡牌游戏手册

## 项目定位

本项目是一款面向 PC 与移动端的 2D 回合制构筑 Roguelite 爬塔游戏。玩家创建角色并选择职业，进入无限高塔后通过战斗、奖励选择、装备构筑、技能配置和局内融合不断强化角色，尝试挑战更高层数。卡牌是重要构筑与附加能力来源，但战斗主轴不是纯抽牌打牌，而是围绕普通攻击、防御、躲避和 4 个职业技能展开。

首版职业包含战士和弓箭手。角色拥有完整装备栏，装备本身也是卡牌。装备不按强弱稀有度划分，只分普通装备与套装：普通装备提供更高基础数值，每个职业各自拥有 4 个 2 件套、4 个 3 件套、3 个 4 件套、3 个 5 件套和 2 个 6 件套，其中 6 件套包含 2/4/6 三档能力；同时提供不限职业的通用套装，包括 7 个 2 件套、5 个 3 件套和 4 个 4 件套。每个职业拥有多张专属技能卡，但单个角色在一局游戏中只能装备 4 个技能。塔内每层固定需要完成 10 场战斗，部分战斗会出现多名敌人。第 1 层是新手引导层，固定解锁基础装备和第 1 个技能；后续层数进入正式奖励循环。

## 核心循环

1. 创建角色，选择职业。
2. 配置初始装备、初始技能与通用状态卡抽取配置。
3. 进入高塔第 1 层。
4. 每层依次完成 10 场战斗。
5. 第 1 层新手引导依次解锁头部、上身、腰部、下身、手部、护腿、脚部、武器、副手装备，并在 Boss 战后解锁第 1 个技能。
6. 第 2 层开始，每次普通战斗胜利后从 3 个非装备卡奖励中选择 1 个，精英怪为 4 选 1，Boss 的非装备卡奖励为 5 选 1；战斗内抽取的状态卡主要提供行动倍率、确定暴击、强化躲避、强化防御和紧急回撤修饰。
7. 装备卡只在 Boss 关卡的永久装备分支中出现；技能不会重复获取，职业永久技能全解锁后改为固定提供塔内技能，首版塔内技能池优先使用通用塔内技能。
8. 将奖励用于替换装备、调整技能，或把塔内附着卡融合附着到装备、已装备技能和基础行动上。
9. 完成当前层第 10 场战斗后进入下一层。
10. 角色死亡、主动退出或重新开始时，清空塔内附着卡和融合附着。

## 推荐引擎

推荐使用 **Godot 4.x Stable + GDScript** 开发首版原型。

选择理由：

- 本项目主要由 2D UI、行动按钮、状态卡、数据表和回合制逻辑组成，Godot 的 Control UI 系统、Resource 数据资源和信号机制适合快速迭代。
- Godot 免费开源，采用 MIT 许可，适合独立项目和长期商业化。
- Godot 支持导出 Windows、macOS、Linux、Android、iOS 和 Web，符合 PC+移动端目标。
- GDScript 与 Godot 编辑器集成度高，适合先做玩法闭环，再逐步抽象数据和工具链。

Unity 也可以完成该项目，尤其适合已有 Unity 团队或需要大量第三方商业插件的情况。但对本项目的首版而言，Godot 的授权成本、工程复杂度和 2D UI 开发负担更低。

参考：

- [Godot 官方导出文档](https://docs.godotengine.org/en/stable/tutorials/export/index.html)
- [Godot 许可说明](https://godotengine.org/license/)
- [Unity 平台开发文档](https://docs.unity3d.com/Manual/PlatformSpecific.html)

## 文档目录

- [01_core_loop.md](01_core_loop.md)：核心流程、单局结构、继承边界。
- [02_classes.md](02_classes.md)：战士、弓箭手、职业技能与 4 技能槽规则。
- [03_cards.md](03_cards.md)：装备卡、技能卡、塔内附着卡、状态卡。
- [04_equipment.md](04_equipment.md)：完整装备栏与装备卡设计。
- [05_tower_rewards.md](05_tower_rewards.md)：塔层结构、怪物节奏、奖励池。
- [06_fusion_system.md](06_fusion_system.md)：局内融合附着规则。
- [07_combat.md](07_combat.md)：回合制战斗、基础行动、状态卡、行动力、状态。
- [08_progression_balance.md](08_progression_balance.md)：成长边界、数值曲线、奖励生成。
- [09_v1_content_tables.md](09_v1_content_tables.md)：首版内容表。
- [10_ui_ux.md](10_ui_ux.md)：PC 与移动端界面方案。
- [11_technical_recommendation.md](11_technical_recommendation.md)：Godot 技术落地建议。
- [12_equipment_generation.md](12_equipment_generation.md)：首版基础装备与套装生成表。
- [13_set_equipment_items.md](13_set_equipment_items.md)：套装装备逐件明细与基础属性。
- [14_enemy_design.md](14_enemy_design.md)：50 种敌人单位、战斗编队、特性、技能和楼层数值公式。
- [15_development_task_breakdown.md](15_development_task_breakdown.md)：无美术首版原型的开发任务拆解。
