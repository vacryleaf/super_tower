# 当前系统功能总览

> 状态：已实现 + 设计已确认待实现的汇总。详细内容按领域拆分，开发时按 `system.index.md` 局部读取。

## 1. 已实现功能

- 单局高塔流程、3 场新手教程、正式楼层 10 场战斗结构。
- 统一角色、肾上腺素、四个运行时装备槽、技能背包和消耗栏。
- 实时战斗、玩家普通行动、技能行动、敌方行动、伤害/格挡/闪避、状态和触发器。
- 普通/精英/Boss 遭遇生成、群落能力、战斗奖励、状态卡、局内附着、永久 Profile 与单局存档。
- 营地、战斗、奖励、装备、技能、物品、图鉴等 UI 入口。
- Godot headless 测试入口：`run_tests.bat` 与 `run_tests.sh`。

## 2. 当前实现边界

- 代码使用 `DataCatalog` 内置静态表；`catalog_v1.json` 通过 `DataRepository` 提供外部表读取和 parity 校验入口。
- 自动模拟战斗相关脚本已经删除，不再作为运行时或开发测试路径。
- 当前没有完整 Mod Loader；Mod 包格式、校验和合并规则记录在架构领域，属于预留设计。
- 文档中的旧职业、旧装备部位、套装旧字段只作为迁移/历史资料，不可作为新功能依据。

## 3. 领域导航

- [架构](architecture/README.md)
- [战斗](combat/README.md)
- [技能](skills/README.md)
- [武器](weapons/README.md)
- [物品](items/README.md)
- [怪物](monsters/README.md)
- [成长与高塔](progression/README.md)
- [UI](ui/README.md)
- [测试与维护](testing/README.md)
