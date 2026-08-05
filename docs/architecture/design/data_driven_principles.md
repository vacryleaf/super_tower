# 数据驱动原则

状态：设计已确认待实现（原则已执行，通用内容注册仍需扩展）。

## 目标

所有技能、武器、物品、怪物、状态和触发器都以数据 ID 描述，运行时服务只解释统一字典。新增内容应通过新增数据文件完成，尽量不修改战斗流程代码。

## 分层

1. **定义层**：原版 `DataCatalog`、包含声明式状态定义的 `TraitCatalog`，外部 `catalog_v1.json`，未来 Mod 内容。
2. **规范化层**：校验字段、补默认值、解析命名空间和引用。
3. **状态转换层**：`Combatant` 将角色、装备、怪物和能力转换为运行时 status 字典。
4. **行为层**：`BattleService` 编排实时行动，`SkillActionService` 解释技能 `actions`，`ActionPipeline` 处理行动修正，`StatusService` 和 `TriggerService` 解释状态与事件。
5. **展示层**：图鉴和 UI 只读取规范化数据，不复制效果逻辑。

## 可插拔要求

- ID 稳定且带命名空间；引用只使用 ID，不直接保存对象。
- 效果用声明式 `actions/effects/conditional_effects/triggers` 表达。
- Trait 的 status、conditional_effects 和 triggers 由 `TraitCatalog` 提供；敌人行动选择、动态分裂/召唤和场地效果仍由 `EnemyActionRules`/`CombatRules` 负责。
- 未通过 Schema、引用、权限和版本检查的内容不得注册。
- 原版数据、Mod 数据和图鉴数据必须来自同一规范化结果。
