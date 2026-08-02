# Trigger Schema

状态：已实现。

触发器由事件名、条件和 actions 组成：

```json
{"event": "on_hit_received", "conditions": [{"stat": "hp", "operator": "lt", "value": 20}], "actions": [{"type": "gain_block", "target": "self", "amount": 4}]}
```

事件常量由 `trigger_events.gd` 维护；`TriggerService` 负责筛选和执行，禁止在 UI 中监听后自行改战斗状态。
