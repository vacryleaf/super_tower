# 物品运行逻辑

状态：已实现。

- 角色/战斗产生或消耗肾上腺素。
- 玩家拥有一瓶血瓶和 3 个消耗栏；血瓶每次消耗一次行动并恢复最大生命值的 `30% + 等级 × 5%`，营地中也可对已保存角色使用。
- `RewardService` 生成奖励，`RewardApplyService` 与 `CharacterService` 将奖励附着到技能/装备/玩家。
- `EquipmentService` 只处理装备；物品图鉴不参与装备或战斗结算。
