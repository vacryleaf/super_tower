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

ARCH-14 已完成调用方迁移：`EncounterService`、`RewardService`、`EncyclopediaIndexService` 均注入可选 `catalog_instance`（无参构造保持兼容），原版数据查询统一改走 RuntimeCatalog——遭遇单位经 `monster_units(rank)`、怪物组经 `monster_group*` 系列、塔内奖励经 `runtime_table(...)`（Mod 内容不进塔内奖励池）、教程解锁经 `tutorial_unlock_ids()`（带越界保护）、图鉴索引经 `resolved_table(...)`。`ContentTableAdapter` 扩展 `equipment`/`consumables`/`passive_skills`/`innate_skills` 表，并新增 `get_floor_battle_type`/`skill_class_compatible`/`equipment_class_compatible`/`innate_skills_table` 等辅助查询。注册与引用边界由 `content_registry_integration_test.gd` 覆盖（技能/装备/怪物一致性、遭遇生成、奖励引用和图鉴一致性）。
