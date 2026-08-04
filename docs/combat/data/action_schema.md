# Action Schema

状态：已实现。

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

当前执行器支持 `damage`、`modify_armor`、`apply_status`、`gain_block`、`gain_dodge`、`interrupt`、`heal`、`clear_debuffs`、`set_duel`、`set_deflect` 和 `summon`。`damage.ignore_armor` 使用 `0-1` 的忽略比例；条件不满足时跳过该动作，未知 action 会记录错误并提示当前战斗。
