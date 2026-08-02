# Action Schema

状态：设计已确认待实现（当前已有 actions 数据和执行路径）。

```json
{
  "type": "damage",
  "target": "selected",
  "multiplier": 2.0,
  "hits": 1,
  "damage_type": "physical",
  "conditions": []
}
```

核心字段：`type`、`target`、数值参数、`conditions`、可选 `repeat_with_charge`/`include_extra_hits`。目标枚举和参数由执行器登记，不接受任意脚本。
