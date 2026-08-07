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

ARCH-13 已新增 `GameProject/scripts/core/runtime_catalog.gd` 作为统一查询门面：调用方通过 `entry()/table()/has()` 查询规范化内容，优先级为 Mod 内容 > 已迁移的完整外部表 > 运行时表；`ContentTableAdapter` 负责表名到 DataCatalog 运行时表的适配。未完成 parity 的外部表继续 fallback，Mod 查询不暴露原始文件路径。调用方迁移（Combatant/Encounter/Reward/Encyclopedia）由 ARCH-14 完成。
