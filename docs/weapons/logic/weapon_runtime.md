# 武器运行逻辑

状态：已实现。

`EquipmentService` 负责装备和槽位规范化；`DataCatalog.weapon_profile_for_item()` 解析物品到武器档案；`Combatant`/`CombatRules` 使用攻击、敏捷、暴击和技能绑定参与战斗；UI 读取同一档案显示图鉴。

普通攻击和主动攻击会按当前武器的 `critical_weight` 进行暴击判定；暴击伤害为基础伤害的 2 倍，并在命中上下文中触发 `ON_CRITICAL`，供数据驱动特性继续处理。

当前装备槽固定为 `weapon`、`armor`、`accessory`、`offhand`。旧部位字段只在存档迁移时清理。
