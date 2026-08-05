# Item Schema

状态：设计已确认待实现；当前消耗品定义在 `DataCatalog.CONSUMABLES`。

```json
{
  "schema_version": 1,
	"id": "example.mod.item.custom_potion",
	"name_key": "item.custom_potion.name",
	"runtime_class": "unified",
	"content_class": "common",
	"kind": "consumable",
  "stack_limit": 1,
  "use_context": ["camp", "battle"],
  "actions": [{"type": "heal", "target": "self", "amount": 20}],
  "tags": ["potion"]
}
```

资源、消耗品、装备和奖励应使用不同 `kind`；不允许仅依靠名称判断用途。

`runtime_class` 表示规范化运行时职业；`content_class` 表示原版内容分类。旧版 `class` 字段只作为 `content_class` 的兼容输入。
