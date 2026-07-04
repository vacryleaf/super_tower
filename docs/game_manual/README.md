# 无限爬塔卡牌游戏手册

## 项目定位

本项目是一款面向 PC 与移动端的 2D 回合制卡牌 Roguelite 爬塔游戏。玩家创建角色并选择职业，进入无限高塔后通过战斗、奖励选择、装备构筑、技能配置和局内融合不断强化角色，尝试挑战更高层数。

首版职业包含战士和弓箭手。角色拥有完整装备栏，装备本身也是卡牌。每个职业拥有多张专属技能卡，但单个角色在一局游戏中只能装备 4 个技能。塔内每层固定需要击败 10 只怪物，每击败 1 只怪物都提供奖励选择。

## 核心循环

1. 创建角色，选择职业。
2. 配置初始装备、初始技能与基础卡组。
3. 进入高塔第 1 层。
4. 每层依次击败 10 只怪物。
5. 每次战斗胜利后选择奖励：装备卡、技能卡、增强卡、Buff 卡、金币或治疗。
6. 将奖励用于替换装备、调整技能，或融合附着到装备和技能上。
7. 击败当前层第 10 只怪物后进入下一层。
8. 角色死亡、主动退出或重新开始时，清空塔内临时增强、融合和 Buff。

## 推荐引擎

推荐使用 **Godot 4.x Stable + GDScript** 开发首版原型。

选择理由：

- 本项目主要由 2D UI、卡牌拖拽、数据表和回合制逻辑组成，Godot 的 Control UI 系统、Resource 数据资源和信号机制适合快速迭代。
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
- [03_cards.md](03_cards.md)：装备卡、技能卡、增强卡、Buff 卡。
- [04_equipment.md](04_equipment.md)：完整装备栏与装备卡设计。
- [05_tower_rewards.md](05_tower_rewards.md)：塔层结构、怪物节奏、奖励池。
- [06_fusion_system.md](06_fusion_system.md)：局内融合附着规则。
- [07_combat.md](07_combat.md)：回合制战斗、抽牌、能量、状态。
- [08_progression_balance.md](08_progression_balance.md)：成长边界、数值曲线、奖励权重。
- [09_v1_content_tables.md](09_v1_content_tables.md)：首版内容表。
- [10_ui_ux.md](10_ui_ux.md)：PC 与移动端界面方案。
- [11_technical_recommendation.md](11_technical_recommendation.md)：Godot 技术落地建议。

