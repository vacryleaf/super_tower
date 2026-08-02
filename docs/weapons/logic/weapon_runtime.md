# 武器运行逻辑

状态：已实现。

`EquipmentService` 负责装备和槽位规范化；`DataCatalog.weapon_profile_for_item()` 解析物品到武器档案；`Combatant`/`CombatRules` 使用攻击、敏捷、暴击和技能绑定参与战斗；UI 读取同一档案显示图鉴。

当前装备槽固定为 `weapon`、`armor`、`accessory`、`offhand`。旧部位字段只在存档迁移时清理。
