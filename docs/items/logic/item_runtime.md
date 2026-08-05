# 物品运行逻辑

状态：已实现。

- 角色/战斗产生或消耗 `adrenaline`，UI 统一显示为“肾上腺素”。资源名称由 `DataCatalog.resource_label()` 提供，不能在页面中用“非 rage 即专注”的分支推断。
- 玩家拥有一瓶血瓶和 3 个消耗栏；血瓶每次消耗一次行动并恢复最大生命值的 `30% + 等级 × 5%`，营地中也可对已保存角色使用。
- 战斗操作栏会显示已配置的普通消耗品；使用普通消耗品会消耗本局该槽位和一次行动。`heal` 恢复固定生命，`armor`/`attack` 在本场战斗提供对应属性加成，`dodge`/`block` 立即提供闪避层/格挡，`skill` 恢复能量。
- `charge_` 开头的物品仍按充能规则处理，不占用普通消耗品的使用路径。
- `throwing_dart` 属于 `charge_bonus_damage` 物品，发动后将 `5` 点额外伤害写入下一次攻击的全局充能桶，每场战斗默认只能使用一次。
- `RewardService` 生成奖励，`RewardApplyService` 与 `CharacterService` 将奖励附着到技能/装备/玩家。
- `EquipmentService` 只处理装备；物品图鉴不参与装备或战斗结算。
