# 物品运行逻辑

状态：已实现。

- 角色/战斗产生或消耗肾上腺素。
- 玩家拥有一瓶血瓶和 3 个消耗栏；消耗品在战斗或营地按使用规则执行。
- `RewardService` 生成奖励，`RewardApplyService` 与 `CharacterService` 将奖励附着到技能/装备/玩家。
- `EquipmentService` 只处理装备；物品图鉴不参与装备或战斗结算。
