# 测试矩阵

状态：已实现 + 持续维护。

| 范围 | 入口 |
| --- | --- |
| 数据字段/parity | `data_validation_test.gd` |
| 实时战斗机制 | `combat_mechanics_test.gd` |
| 教程/楼层/活动 | `campaign_test.gd` |
| 奖励和附着 | `reward_system_test.gd` |
| 存档迁移与序列化 | `persistence_test.gd` |
| UI 点击冒烟 | `ui_click_smoke_test.gd` |
| 全量 | `run_tests.bat` / `run_tests.sh` |

当前验收要求：不得依赖模拟战斗；跨平台核心断言使用 Godot headless；Windows pywinauto 只做桌面 UI 补充验收。
