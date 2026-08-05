# 图鉴展示数据

状态：已实现自动索引 + 扩展待实现。

图鉴索引统一字段：`id`、`kind`、`name_key`、`description_key`、`tags`、`rarity`、`unlock_state`、`source`、`schema_version`。效果部分引用规范化 actions/status 摘要，不保存第二份可执行逻辑。

`EncyclopediaIndexService` 从 `DataCatalog`、`TraitCatalog` 和可选 Mod 内容生成上述字段；缺少本地化字段时按稳定 ID 生成 fallback key。怪物默认使用 `unlock_state.type=bestiary`，其他原版实体默认公开；索引只保存展示元数据，不复制可执行效果。
