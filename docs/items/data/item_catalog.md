# 物品图鉴目录

状态：已实现（原版）+ 设计已确认待实现（统一注册表）。

当前第一版消耗品由 `DataCatalog.CONSUMABLES` 定义：`minor_heal`、`iron_skin`、`swift_step`、`rage_draught`、`focus_tea`、`emergency_kit`、`huangqi_juice`、`throwing_dart`。初始池由 `STARTER_CONSUMABLES` 定义，`throwing_dart` 不在初始池中，由塔内奖励获得。

血瓶由 `DataCatalog.BLOOD_POTION` 定义，使用次数保存在角色 Profile；技能商人等 NPC 由 `DataCatalog.NPCS` 定义。

更多资源、血瓶、种子和商人池的设计保留在具体条目和成长领域；新增物品必须同时提供 Schema、效果动作、图鉴文本和测试。
