# 内容校验逻辑

状态：已实现基础校验 + 扩展待实现。

校验顺序：

1. JSON 根节点和 `schema_version` 类型。
2. `id`、`name_key`、`kind`、`version` 等必填字段。
3. ID 命名空间、唯一性和保留字。
4. 数值范围、枚举值、数组元素类型。
5. action/trigger/status 类型是否在注册表中。
6. 引用的技能、武器、物品、单位和本地化键是否存在。
7. 依赖和 API 版本是否满足。

失败项写入结构化错误日志；不自动降级为半有效内容。可选展示字段可以使用默认值，但不可为核心效果静默补值。

当前实现入口为 `GameProject/scripts/core/content_validator.gd`。Mod Loader 已在读取内容文件时调用它；原版 `data_validation_test.gd` 通过 `allow_legacy` 模式校验旧版 DataCatalog 字段，同时对新 Schema 内容执行严格 action/trigger 校验。
