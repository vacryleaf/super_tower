# Super Tower Markdown 文档索引

> **唯一开发依据：本目录下的 Markdown。** `docs/system.docx` 是由本索引及其链接内容生成的查看版，不作为开发时的主读取源。
>
> 文档版本：2026-08-02  
> 组织规范：一级为领域，二级为 `design / logic / data`，三级为具体 Schema、图鉴或实体条目；可展示图鉴集中在各领域的 `encyclopedia/`。

## 1. 局部读取规则

1. 先读取本文件，确定领域与权威文件。
2. 只读取当前任务对应领域的 `README.md`、相关二级文件和需要的三级条目；不要求读取整套文档。
3. `design/` 只记录目标、边界和确认过的设计；`logic/` 只记录运行流程和调用关系；`data/` 只记录 Schema、字段、校验规则和实际应用数据。
4. 每个文件开头必须标明 `状态`：`已实现`、`设计已确认待实现`、`待确认` 或 `历史归档`。
5. 若文档与代码冲突，以“当前实现”标记为准；发现冲突时先更新 `testing/logic/development_checklist.md`，再修代码或修文档。

## 2. 全局硬规则

- 运行时只有实时战斗路径：`PlaySession -> BattleService -> ActionPipeline / StatusService / TriggerService`。
- 自动模拟战斗已经删除，不得恢复 `CombatEngine`、`RunSimulator`、`SimulationRewardPolicy` 或 `ChargeSimulator`。
- 新角色首次进入正式高塔前固定进行 3 场教程；教程不消耗正式第 1 层。正式第 1 层不是教程层。
- 每个正式楼层固定 10 场：第 1～2、4～5、7～9 场普通，第 3、6 场精英，第 10 场 Boss。
- 当前运行时采用统一角色；旧职业字段只用于旧存档迁移。
- 运行时装备槽固定为：`weapon`、`armor`、`accessory`、`offhand`。
- 新能力优先使用 `actions`、`effects`、`conditional_effects`、`triggers` 和状态服务，不在流程层散落硬编码。
- 原版和 Mod 内容必须进入同一份规范化运行时数据；内容 ID 必须带命名空间，禁止覆盖原版 ID。

## 3. 领域入口

| 一级领域 | 入口 | 内容边界 |
| --- | --- | --- |
| 架构 | [architecture/README.md](architecture/README.md) | 数据驱动、运行时管线、Schema、Mod 加载器预留。 |
| 战斗 | [combat/README.md](combat/README.md) | 回合、行动、伤害、状态、触发和实时战斗流程。 |
| 技能 | [skills/README.md](skills/README.md) | 技能设计、技能执行和技能图鉴。 |
| 武器 | [weapons/README.md](weapons/README.md) | 武器属性、普攻、武器技能绑定和武器图鉴。 |
| 物品 | [items/README.md](items/README.md) | 资源、消耗品、物品栏和物品图鉴。 |
| 怪物 | [monsters/README.md](monsters/README.md) | 群落、单位、Boss、能力和遭遇数据。 |
| 成长与高塔 | [progression/README.md](progression/README.md) | 教程、高塔、奖励、永久进度和局内成长。 |
| UI | [ui/README.md](ui/README.md) | 界面职责、交互逻辑和图鉴展示。 |
| 测试与维护 | [testing/README.md](testing/README.md) | 验收、开发清单、文档同步和风险记录。 |

## 4. 汇总与查看版

- [system_overview.md](system_overview.md)：面向快速确认的功能总览。
- [system.docx](system.docx)：面向用户查看的 Word 汇总版；源内容仍以本索引链接的 Markdown 为准。
- [archive/legacy/README.md](archive/legacy/README.md)：旧文件迁移说明，不参与当前规则判断。

## 5. 代码权威入口

- 静态数据：`GameProject/scripts/core/data_catalog.gd`、`GameProject/scripts/core/trait_catalog.gd`
- 外部表：`GameProject/data/catalog_v1.json`、`GameProject/scripts/core/data_repository.gd`
- 状态转换：`GameProject/scripts/core/combatant.gd`
- 实时流程：`GameProject/scripts/core/play_session.gd`、`battle_service.gd`、`battle_state.gd`
- 通用效果：`action_pipeline.gd`、`status_service.gd`、`trigger_service.gd`
- 内容行为：`enemy_action_rules.gd`、`combat_rules.gd`

## 6. 文档状态

本次整理不删除历史内容；旧的散落文件已移动到 `archive/legacy/`，并从当前入口中移除。新内容若尚未有代码支持，必须明确写成“设计已确认待实现”，不得伪装成已实现功能。
