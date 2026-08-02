# Skill Schema

状态：设计已确认待实现；原版字段已在 `DataCatalog.SKILLS` 中使用。

```json
{
  "schema_version": 1,
  "id": "example.mod.skill.arc_burst",
  "name_key": "skill.arc_burst.name",
  "description_key": "skill.arc_burst.description",
  "slot": 1,
  "kind": "attack",
  "energy_cost": 10,
  "cooldown": 0,
  "targets": "selected",
  "actions": [{"type": "damage", "target": "selected", "multiplier": 2.0, "hits": 1, "damage_type": "physical"}],
  "tags": ["weapon_skill"]
}
```

`actions` 是权威效果；旧的 `multiplier` 等顶层快捷字段仅为兼容和图鉴摘要，不能与 actions 产生矛盾。
