# 技能图鉴目录

状态：已实现（原版部分）+ 设计已确认待实现（统一注册表）。

当前原版技能定义权威来源：`DataCatalog.SKILLS`；外部 `catalog_v1.json` 只覆盖部分旧/校验字段。技能条目按 ID 拆在 `../encyclopedia/entries/`，图鉴展示应从规范化注册表生成。

| 类别 | 条目 |
| --- | --- |
| 武器槽位 1/2 | 见 `data/entries/skill_*.md`，绑定关系见 `weapons/data/weapon_catalog.md` |
| 通用槽位 3 | 防御、架势、战吼等数据条目 |
| 通用槽位 4 | 冷却型翻滚、战术后撤等数据条目 |
| 敌人技能/被动 | 由怪物图鉴引用，运行时仍走同一 action/status 解释器 |

具体数值不要在此重复；此文件只做索引。
