# Weapon Schema

状态：设计已确认待实现；原版定义已在 `DataCatalog.WEAPON_PROFILES` / `WEAPON_ITEM_PROFILES` 中使用。

```json
{
  "schema_version": 1,
  "id": "example.mod.weapon.custom_sword",
  "item_id": "example.mod.item.custom_sword",
  "name_key": "weapon.custom_sword.name",
  "slot": "weapon",
  "agility": 12,
  "attack_damage": 8,
  "critical_weight": 15,
  "skill_1": "example.mod.skill.arc_burst",
  "skill_2": "example.mod.skill.guard_break",
  "tags": ["sword"]
}
```

必填引用必须存在；`skill_1/2` 只能引用允许的武器技能；数值范围和命名空间由通用校验规则约束。
