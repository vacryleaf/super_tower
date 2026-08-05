# 运行时数据管线

状态：已实现（原版/外部表与清单 parity）+ 设计已确认待实现（Mod 接入）。

1. `DataCatalog` 提供原版静态常量和查询方法。
2. `DataRepository` 从 `res://data/catalog_v1.json` 惰性读取外部表。
3. 领域服务按 ID 取得定义并补齐运行时默认值。
4. `Combatant` 将玩家、装备、怪物和能力转换为运行时字典。
5. `BattleService` 编排行动，并由 `SkillActionService` 按技能 `actions` 字段分发动作。
6. `ActionPipeline` 处理行动上下文中的通用修正；`StatusService` 解析状态、持续时间和条件效果；`TriggerService` 按事件触发动作。
7. UI/图鉴从同一数据源读取可展示字段。
8. `data_validation_test.gd` 对外部怪物 manifest 与运行时 normal/elite/boss ID 做双向 parity 校验；通过前不得切换运行时权威。

禁止 UI 直接读 Mod 原始文件；禁止战斗服务根据文件名猜测内容类型。
