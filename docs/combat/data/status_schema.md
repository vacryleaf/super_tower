# Status Schema

状态：已实现 + 扩展规则待完善。

必填：`id`、`kind`、`stack`、`duration`。可选：`effects`、`conditional_effects`、`tick_effects`、`triggers`、`source_id`。

`stack` 至少支持 replace/add 等当前服务已支持语义；持续时间每回合由 StatusService 统一递减；状态 ID 必须唯一并可迁移。
