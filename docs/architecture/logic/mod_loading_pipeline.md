# Mod 载入流程

状态：基础流程已实现 + 完整校验待实现。

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

当前实现入口为 `GameProject/scripts/core/mod_loader.gd`；默认 Mod 根目录为 `user://mods`，测试使用 `res://data/test_mods` fixture。注册表与 `DataCatalog` 保持隔离，尚未切换原版运行时权威。
