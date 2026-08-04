架构优化：
阅读 architecture-optimization-directions.md —— 按项目需求模板结构，覆盖方向 A（结算下沉）+ B（契约化直测）。

任务单核心内容（子线程可直接执行）

- [x] 任务 1｜结算主体迁移（纯代码移动，行为零变化）
battle_service.gd 新增 deal_damage(session: RefCounted, ctx: Dictionary)，将 play_session.gd:774-830 主体逐行迁入
三个关键转换点已写明：self → session 显式化；触发上下文 "session": self → "session": session；日志文案一字不改
play_session.deal_damage(ctx) 替换为一行薄转发

- [x] 任务 2｜服务级独立测试
新增 tests/battle_service_test.gd，桩 session 直测 4 个针对性用例：嘲讽重定向、决斗清理、闪避分支、非交互源忽略嘲讽
模式参考 combat_mechanics_test.gd 已有先例，无需新框架

- [x] 任务 3｜验证与回写
run_tests.sh / run_tests.bat 全绿 + git diff 人工核对仅位置移动
文档回写 docs/combat/（若有结算入口描述）

验收结果：`run_tests.sh` 与 `run_tests.bat` 的同一套入口已串联核心测试、UI 冒烟和 `battle_service_test.gd`；`PlaySession.deal_damage()` 仅保留一行兼容转发，`BattleService` 内部不再反向调用 `session.deal_damage()`，结算入口已回写 `docs/combat/logic/battle_round_detail.md`。

关键数字（迁移前后对照）
当前保留 3 个 `TriggerService` 兼容调用；`BattleService` 内部 9 个结算调用已改为直接调用 `deal_damage(session, ctx)`，`PlaySession` 对外 API 保持不变。
验收红线：play_session 中 deal_damage 仅剩一行转发；本次迁移未修改 `trigger_service.gd` 与 `enemy_action_rules.gd` 的调用逻辑。

3 个执行时确认点
combat_mechanics_test.gd 是否有 deal_damage 日志文案断言（默认按"一字不改"执行）
tutorial_and_floors_test.gd 是否已串联全部测试（决定新测试接入方式）
docs/combat/ 是否有需同步的结算入口文档
