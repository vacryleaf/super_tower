# 状态与触发设计

状态：已实现。

状态结构至少包含 `id`、`name`、`kind`、`stack`、`duration`，以及 `effects`、`conditional_effects`、`tick_effects`、`triggers`。`-1` 表示整场持续。

事件包括 `on_battle_start`、`on_turn_start`、`on_turn_end`、`on_hit_dealt`、`on_hit_received`、`on_kill`、`on_dodge`、`on_attack_complete`。优先新增数据和注册 action，不在 BattleService 中复制特性分支。
