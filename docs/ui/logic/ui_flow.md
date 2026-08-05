# UI 交互逻辑

状态：已实现。

主菜单/存档 → 营地 → 进塔准备 → 战斗 → 奖励 → 下一场/下一层。装备、技能、物品和图鉴页面通过服务读写状态；战斗页面只向 BattleService/PlaySession 派发行动。

运行时装备页面只显示四个槽位和 4 格本局装备背包；不显示旧套装摘要或旧部位栏位。

职业头像通过 `DataCatalog.CLASSES[<class>].avatar_asset` 选择资源；统一职业当前使用兼容头像资源，资源缺失时显示职业名称 fallback。资源名称通过 `DataCatalog.resource_label()` 映射。
