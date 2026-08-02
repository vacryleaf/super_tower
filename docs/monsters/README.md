# 怪物领域

状态：已实现 + 设计已确认待实现。

怪物由群落、单位等级、被动能力、主动技能和行为权重组成。单位数据进入 `Combatant` 后才生成运行时状态；行为选择由 `enemy_action_rules.gd` 负责。

- 设计：[design/monster_design.md](design/monster_design.md)
- 逻辑：[logic/monster_runtime.md](logic/monster_runtime.md)
- Schema：[data/monster_schema.md](data/monster_schema.md)
- 图鉴目录：[data/monster_catalog.md](data/monster_catalog.md)
- 图鉴目录：[encyclopedia/README.md](encyclopedia/README.md)；具体条目：[encyclopedia/entries/](encyclopedia/entries/)
