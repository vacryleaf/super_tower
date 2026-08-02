# 运行时数据管线

状态：已实现（原版/外部表）+ 设计已确认待实现（Mod 接入）。

1. `DataCatalog` 提供原版静态常量和查询方法。
2. `DataRepository` 从 `res://data/catalog_v1.json` 惰性读取外部表。
3. 领域服务按 ID 取得定义并补齐运行时默认值。
4. `Combatant` 将玩家、装备、怪物和能力转换为运行时字典。
5. `BattleService` 接收规范化行动，交给 `ActionPipeline`。
6. `StatusService` 解析状态、持续时间和条件效果；`TriggerService` 按事件触发动作。
7. UI/图鉴从同一数据源读取可展示字段。

禁止 UI 直接读 Mod 原始文件；禁止战斗服务根据文件名猜测内容类型。
