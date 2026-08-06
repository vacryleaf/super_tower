# 测试矩阵

状态：已实现 + 持续维护。

| 范围 | 入口 |
| --- | --- |
| 数据字段/parity | `data_validation_test.gd` |
| 实时战斗机制 | `combat_mechanics_test.gd` |
| 战斗上下文/流程结果契约 | `battle_context_contract_test.gd` |
| 战斗时机/模块注册契约 | `battle_module_registry_test.gd` |
| BattleFlow 流程契约 | `battle_flow_contract_test.gd` |
| ActionIntent/目标解析契约 | `action_intent_test.gd` |
| 技能 action 分发/条件契约 | `effect_dispatcher_test.gd` |
| 非伤害效果执行器 | `non_damage_effect_test.gd` |
| 命中上下文/目标解析契约 | `hit_resolution_test.gd` |
| 闪避解析契约 | `dodge_resolution_test.gd` |
| 教程/楼层/活动 | `campaign_test.gd` |
| 奖励和附着 | `reward_system_test.gd` |
| 存档迁移与序列化 | `persistence_test.gd` |
| UI 点击冒烟 | `ui_click_smoke_test.gd` |
| 长时可玩回归（非默认） | `playable_manual_test.gd` |
| Mod manifest/注册 | `mod_loader_test.gd` |
| 全量 | `run_tests.bat` / `run_tests.sh` |

当前验收要求：不得依赖模拟战斗；跨平台核心断言使用 Godot headless；Windows pywinauto 只做桌面 UI 补充验收。`playable_manual_test.gd` 是长时可玩回归脚本，默认入口不执行它，不能将未运行该脚本称为包含长时回归的全量通过。

模块化架构优化处于设计已确认待实现状态。实施中的新增契约测试、服务测试和集成测试必须按 `docs/architecture/logic/modular_architecture_optimization_todo.md` 中的 ARCH 子项逐项接入；在代码和默认入口落地前，不得将计划中的测试写成已执行。
