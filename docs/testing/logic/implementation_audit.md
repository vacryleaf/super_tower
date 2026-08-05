# 实现与文档一致性审计

状态：已完成首轮审计，持续维护。

审计日期：2026-08-05。

审计基线：提交 `9d4102f`；工作区另有未提交的 `run_tests.sh` 和 `run_tests.bat` 测试隔离改动，本次未修改或回退。

## 验证结论

- `sh run_tests.sh` 通过，输出 `ALL TESTS PASSED`。
- 现有入口包含核心 headless 测试、准备页 UI 冒烟和战斗点击 UI 冒烟。
- 核心测试中的未知 action 日志是专门覆盖错误处理的用例，不代表测试失败。
- 不读取图片内容；UI 资源问题只根据文件名、脚本和测试判断。

## 已与当前实现对齐的项目

以下问题在当前提交中已经有实现，旧审计结论不再适用：

- `PlaySession.get_counter()` / `set_counter()` 已使用 `BattleState.counters` 保存触发器计数。
- `TriggerService` 和 `BattleService` 同时兼容单数 `condition` 与复数 `conditions`。
- 图鉴和营地技能列表通过 `UIHelpers.skill_energy_cost()` 读取 `energy_cost`。
- 准备页通过 `DataCatalog.CLASSES.keys()` 构建职业卡片，不再固定访问不存在的 `warrior` / `archer` 职业表。
- 根目录测试入口已经串联核心测试和两个 UI 冒烟测试。

## 当前定义不一致

### 1. 外部怪物清单与运行时 ID 不一致

外部 `enemy_unit_manifest` 在 `GameProject/data/catalog_v1.json` 中声明了 `normal_guard_01`、`normal_guard_03`、`elite_rat_01`、`elite_guard_01` 和 `boss_iron_warden`；运行时 `DataCatalog.NORMAL_UNITS`、`ELITE_UNITS`、`BOSS_UNITS` 使用的是 `normal_skeleton_*`、`elite_skeleton_*` 和 `boss_skeleton_warden` 等 ID。

影响：外部表的 `runtime_authority` 指向当前运行时，但按清单 ID 无法直接解析到运行时单位；未来切换到外部表会产生缺失怪物。现有 `data_validation_test.gd` 只检查表存在和 Boss 数量，没有做双向 ID parity。

涉及文件：

- `GameProject/data/catalog_v1.json`
- `GameProject/scripts/core/data_catalog.gd`
- `GameProject/scripts/tests/data_validation_test.gd`

验收条件：外部 normal/elite/boss ID 集合与运行时三张单位表完全一致，并增加“外部有而运行时无”和“运行时有而外部无”两类断言。

### 2. 外部技能表的迁移状态与文档表述不一致

`catalog_v1.json` 的 `migration_notes.migrated_tables` 将 `skills` 标为已迁移，但外部 `tables.skills` 只覆盖少量技能；完整运行时定义仍在 `DataCatalog.SKILLS`。`docs/skills/data/skill_catalog.md` 已说明外部表只覆盖部分字段，因此 JSON 迁移标记与领域文档不一致。

影响：读者会误以为技能表已经达到可切换运行时权威的完整 parity；当前测试也只做外部条目到运行时条目的单向检查。

涉及文件：

- `GameProject/data/catalog_v1.json`
- `docs/skills/data/skill_catalog.md`
- `GameProject/scripts/tests/data_validation_test.gd`

验收条件：要么补齐完整技能表并增加双向字段/ID parity，要么把迁移状态改为“部分迁移/校验用表”，并明确不得切换运行时权威。

### 3. 统一职业规则与内容分类字段仍混用

系统规则规定运行时只有 `unified`，旧职业只用于迁移；但 `DataCatalog.SKILLS` 和 `DataCatalog.EQUIPMENT` 仍大量使用 `warrior` / `archer` 作为 `class` 字段，运行时再通过 `skill_class_compatible()` 特判兼容。

当前不会导致准备页崩溃，但定义语义不一致：这些字段究竟是旧职业存档 ID，还是内容分类标签，没有在 Schema 中区分。若未来按 `class` 字段做注册、过滤或 Mod 校验，可能错误地把历史分类当成运行时职业。

涉及文件：

- `docs/system.index.md`
- `GameProject/scripts/core/data_catalog.gd`
- `GameProject/data/catalog_v1.json`
- `docs/skills/data/skill_schema.md`
- `docs/items/data/item_schema.md`

验收条件：明确 `class` 的语义并统一 Schema；推荐将运行时职业与内容分类拆成不同字段，或把所有可运行内容规范化为 `unified` 后保留旧标签作为迁移元数据。

### 4. 奖励 Schema 要求的字段尚未进入运行时奖励

`docs/progression/data/reward_schema.md` 要求奖励包含来源、目标类型和效果参数，但 `RewardService` 当前生成的奖励主要使用 `kind`、`label`、`value`，部分奖励再附带 `item_id` 或 `skill_id`；没有统一的 `source`、`target_type` 和规范化效果字段。

影响：文档中的“必须带”描述不是当前运行时契约，外部内容无法按该 Schema 直接接入。

涉及文件：

- `docs/progression/data/reward_schema.md`
- `GameProject/scripts/core/reward_service.gd`
- `GameProject/scripts/core/reward_apply_service.gd`

验收条件：明确区分“当前兼容格式”和“目标 Schema”；在奖励服务、应用服务、保存迁移和测试全部支持新字段后，再把目标字段改为必填。

### 5. Trait 数据驱动边界尚未完全落实

`docs/architecture/design/data_driven_principles.md` 要求效果通过统一数据声明；当前 `TraitCatalog` 主要提供名称和说明，`Combatant._apply_trait_statuses()` 仍直接按特性 ID 拼装 status、effects 和 triggers。

影响：新增或 Mod 特性仍需要修改运行时代码，无法仅通过数据注册；图鉴说明与实际状态结构也没有统一校验入口。

涉及文件：

- `docs/architecture/design/data_driven_principles.md`
- `GameProject/scripts/core/trait_catalog.gd`
- `GameProject/scripts/core/combatant.gd`

验收条件：将可声明的特性效果迁移到统一数据表，保留确实属于行为决策的特性在 `EnemyActionRules`；补充特性 ID、status、trigger 的注册和引用校验。

### 6. 资源名称和统一职业 UI 资源未完全对齐

`DataCatalog.CLASSES["unified"]["resource"]` 是 `adrenaline`，项目文档和技能条目也使用“肾上腺素”；但百科和营地 UI 只把 `rage` 显示为“怒气”，其他值统一显示为“专注”，因此当前统一职业会显示错误资源名称。

此外，`UIHelpers.avatar_for()` 会先尝试 `res://img/unified.png`，当前资源文件名中只有 `warrior.png` 和 `archer.png`。代码有文字面板 fallback，所以不会阻塞 headless 测试，但缺少与统一职业对应的正式头像资源映射。

涉及文件：

- `GameProject/scripts/core/data_catalog.gd`
- `GameProject/scripts/ui/encyclopedia_view.gd`
- `GameProject/scripts/ui/camp_view.gd`
- `GameProject/scripts/ui/ui_helpers.gd`
- `docs/items/logic/item_runtime.md`

验收条件：资源显示统一走资源 ID 到本地化名称的映射；统一职业头像明确采用新资源或兼容别名，不在 UI 中用 `rage`/“其他即专注”的隐式分支。

### 7. 物品目录与图鉴条目漏记 `throwing_dart`

`DataCatalog.CONSUMABLES` 已包含 `throwing_dart`，但 `docs/items/data/item_catalog.md` 只列出 7 个消耗品，`docs/items/encyclopedia/entries/` 没有对应条目。

影响：运行时可获得的物品不一定能在图鉴和文档中找到，违反“新增物品必须同时提供图鉴文本和测试”的规则。

涉及文件：

- `GameProject/scripts/core/data_catalog.gd`
- `docs/items/data/item_catalog.md`
- `docs/items/encyclopedia/entries/`

验收条件：补充目录、稳定 ID 条目、效果摘要和至少一个获得/使用测试；若该物品暂不对玩家开放，则在数据中明确可用状态并从随机奖励池排除。

### 8. 可玩手工测试仍使用旧职业并未纳入统一入口

`playable_manual_test.gd` 仍分别调用 `run_manual_campaign("warrior")` 和 `run_manual_campaign("archer")`。由于运行时会归一化为 `unified`，这两个用例不再代表两个独立职业；同时该脚本不在 `run_tests.sh` / `run_tests.bat` 入口中。

影响：测试名称和当前职业模型不一致，且“全量测试”不包含该脚本。它可以保留为人工回归脚本，但必须标注为历史兼容测试或改为统一职业场景。

涉及文件：

- `GameProject/scripts/tests/playable_manual_test.gd`
- `run_tests.sh`
- `run_tests.bat`
- `docs/testing/logic/test_matrix.md`

验收条件：明确该脚本是手工测试还是自动回归；若纳入自动入口，使用 `unified` 并隔离其长时运行成本，否则在测试矩阵中明确列为非默认手工测试。

## 文档已明确但代码尚未实现

以下不是隐藏缺陷，而是项目文档已经标记的设计预留：

- 完整 Mod Loader：发现、manifest 校验、依赖解析、注册、禁用和错误查询。
- Mod 内容加载、规范化合并、图鉴自动索引及对应自动化测试。
- 通用 Schema 注册表、完整内容校验、跨领域引用校验和命名空间冲突检查。
- 原版静态表完整迁移到统一外部规范化注册表；当前只存在 `DataRepository` 和部分外部校验表。
- 所有图鉴实体的 `name_key`、`description_key`、解锁条件、本地化和自动索引字段。

权威入口：

- `docs/develop_list.md`
- `docs/architecture/design/mod_loading_design.md`
- `docs/architecture/logic/mod_loading_pipeline.md`
- `docs/architecture/data/schema_registry.md`
- `docs/architecture/logic/content_validation.md`
- `docs/ui/data/encyclopedia_schema.md`

## 后续建议顺序

1. 修正外部怪物清单并补双向 parity 测试。
2. 统一外部技能表的迁移状态，避免“已迁移”与“部分覆盖”并存。
3. 先确定统一职业字段语义，再处理奖励 Schema 和 Trait 数据注册。
4. 修复资源名称显示、头像兼容映射和 `throwing_dart` 图鉴缺口。
5. 明确 `playable_manual_test.gd` 的定位，再决定是否接入默认测试入口。

