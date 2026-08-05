# 物品：飞镖

状态：已实现（具体数值以 `DataCatalog.CONSUMABLES["throwing_dart"]` 为准）。

- ID：`throwing_dart`
- 类型：塔内充能物品
- 效果：下一次攻击额外造成 `5` 点伤害
- 使用规则：每场战斗默认可发动 `1` 次；发动后进入下一次攻击的全局充能效果。
- 获取方式：由塔内物品奖励池提供，不属于 `STARTER_CONSUMABLES`。
- 权威数据：`GameProject/scripts/core/data_catalog.gd`

图鉴只引用规范化效果，不复制一份使用逻辑。
