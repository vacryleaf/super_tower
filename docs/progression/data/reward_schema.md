# 奖励数据

状态：已实现（Schema v1）+ 扩展待实现。

运行时奖励统一包含以下字段：

- `schema_version`：当前为 `1`。
- `kind`：兼容现有应用分支的奖励类型。
- `source`：`tutorial`、`floor_reward:<rank>`、`tower_reward`、`npc_blacksmith` 等来源标识。
- `target_type`：`attachment`、`player`、`player_unlock`、`tower_equipment`、`tower_consumable`、`tower_skill`、`tower_passive_skill` 或 `permanent_equipment`。
- `effect`：规范化效果参数，例如 `{ "stat": "attack", "value": 3 }`、`{ "item_id": "..." }` 或 `{ "skill_id": "..." }`。

`label`、`value`、`item_id` 和 `skill_id` 继续保留为旧 UI、应用逻辑和存档的兼容字段。读取旧存档时由 `RewardService.normalize_reward()` 补齐 Schema v1 字段。附着奖励与即时资源奖励分开，目标选择由 `RewardApplyService` 和 `CharacterService` 完成，UI 只提交玩家选择。
