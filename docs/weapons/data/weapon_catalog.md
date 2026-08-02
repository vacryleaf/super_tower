# 武器图鉴目录

状态：已实现（原版）+ 设计已确认待实现（Mod 注册表）。

当前 `DataCatalog.WEAPON_PROFILES`：

| ID | 名称 | 敏捷 | 攻击伤害 | 暴击权重 | 技能 1 | 技能 2 |
| --- | --- | ---: | ---: | ---: | --- | --- |
| unarmed | 空手 | 15 | 2 | 20 | po_jun | explosive_strike |
| short_sword | 匕首 | 13 | 4 | 30 | weak_point_break | backstab |
| long_sword | 剑 | 11 | 7 | 10 | tiao_zhan | shattering_blow |
| short_bow | 弓 | 11 | 6 | 15 | precise_shot | quick_shot |
| hand_crossbow | 弩 | 9 | 10 | 0 | quick_strike | backstab |
| hand_axe | 斧 | 8 | 10 | 0 | zhong_kan | vacuum_slash |
| one_hand_hammer | 锤 | 7 | 12 | 0 | weak_point_break | backstab |
| whip | 鞭子 | 13 | 6 | 15 | quick_strike | hunter_mark |

物品到档案映射由 `WEAPON_ITEM_PROFILES` 管理。具体图鉴条目见 `../encyclopedia/entries/`。
