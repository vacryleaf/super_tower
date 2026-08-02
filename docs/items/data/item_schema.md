# Item Schema

状态：设计已确认待实现；当前消耗品定义在 `DataCatalog.CONSUMABLES`。

```json
{
  "schema_version": 1,
  "id": "example.mod.item.custom_potion",
  "name_key": "item.custom_potion.name",
  "kind": "consumable",
  "stack_limit": 1,
  "use_context": ["camp", "battle"],
  "actions": [{"type": "heal", "target": "self", "amount": 20}],
  "tags": ["potion"]
}
```

资源、消耗品、装备和奖励应使用不同 `kind`；不允许仅依靠名称判断用途。
