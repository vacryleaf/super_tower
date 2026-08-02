# 内容文件通用规则

状态：设计已确认待实现。

- 字符串 ID 稳定、大小写敏感、不得含平台路径分隔符。
- 显示文本使用 `name_key`/`description_key`，本地化文件不参与逻辑判断。
- 数值使用明确单位；百分比统一为小数或统一为整数，不能混用。
- 行动使用 `type`、`target`、参数和可选条件；未知 action 直接报错。
- 条件使用已有 condition evaluator；不在 JSON 中执行脚本表达式。
- 图鉴字段允许 `tags`、`rarity`、`lore_key`、`icon_key`，但不能替代运行时核心字段。
