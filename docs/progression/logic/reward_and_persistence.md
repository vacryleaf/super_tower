# 奖励与存档逻辑

状态：已实现。

- `RewardService` 生成奖励；`RewardApplyService` 应用奖励。
- `SaveProfile` 保存永久队伍、装备、技能、教程完成、塔币、血瓶等级、种子和 NPC 解锁。
- `RunStateSerializer` 保存 active run：楼层、战斗序号、群落历史、玩家/敌人状态、资源、冷却、状态卡、背包、装备和技能。
- 存档保存稳定 ID，不保存 Mod 绝对路径；未来 Mod 缺失时由迁移/兼容策略处理。
