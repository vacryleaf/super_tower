# Mod 载入流程

状态：设计已确认待实现。

```text
扫描启用包
  -> 读取 mod.json
  -> 校验 api_version / 依赖 / ID
  -> 读取领域文件
  -> Schema 校验
  -> 解析跨领域引用
  -> 合并注册表（禁止覆盖）
  -> 生成图鉴索引
  -> 提供 DataCatalog 查询
```

生命周期接口预留：`discover_mods()`、`validate_manifest()`、`load_content()`、`register_content()`、`disable_mod()`、`content_errors()`。接口返回规范化字典，不让调用方依赖磁盘布局。
