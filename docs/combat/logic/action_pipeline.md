# 行动管线

状态：已实现。

`ActionPipeline` 接收规范化 action 数组，按顺序执行目标解析、条件判断、动态值解析、效果应用和事件发射。典型 action：`damage`、`gain_block`、`apply_status`、`modify_armor`、`interrupt`、`heal`、`summon`。

新增行动类型时必须同时更新：Schema 注册、执行器、日志事件、单元测试和图鉴描述；不能在某个技能中内联另一个行动解释器。
