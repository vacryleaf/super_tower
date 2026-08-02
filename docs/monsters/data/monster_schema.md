# Monster Schema

状态：设计已确认待实现；原版数据在 `DataCatalog.NORMAL_UNITS / ELITE_UNITS / BOSS_UNITS`。

```json
{
  "schema_version": 1,
  "id": "example.mod.monster.custom_rat",
  "name_key": "monster.custom_rat.name",
  "rank": "normal",
  "group_id": "rat",
  "stats": {"hp": 20, "attack": 6, "defense": 1, "block_power": 2, "agility": 9},
  "passive_skills": ["swarm"],
  "skills": ["enemy_bite"],
  "behavior_weights": {"innate_attack_1": 50, "enemy_bite": 30}
}
```

`passive_skills`、`skills` 必须引用已注册能力；行为权重必须是非负数，至少保留合法 fallback。
