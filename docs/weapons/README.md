# 武器领域

状态：已实现 + 设计已确认待实现。

武器是可插拔内容：武器数据定义属性、普攻参数和技能 ID；运行时通过 `DataCatalog.weapon_profile_for_item()` 转换，不把武器逻辑写死在 UI。未来 Mod 武器必须使用同一 Schema。

- 设计：[design/weapon_design.md](design/weapon_design.md)
- 逻辑：[logic/weapon_runtime.md](logic/weapon_runtime.md)
- Schema：[data/weapon_schema.md](data/weapon_schema.md)
- 图鉴目录：[data/weapon_catalog.md](data/weapon_catalog.md)
- 图鉴目录：[encyclopedia/README.md](encyclopedia/README.md)；具体条目：[encyclopedia/entries/](encyclopedia/entries/)
