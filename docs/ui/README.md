# UI 领域

状态：已实现。

UI 只负责展示状态和派发用户意图，不在 UI 中计算伤害、选择敌方行为或定义图鉴数据。图鉴页面读取各领域的规范化数据索引。

ARCH-17（2026-08-07）已落地意图门面 `GameProject/scripts/ui/ui_intent.gd`：战斗与奖励回调统一经 `ui_intent` 派发到 session 公开方法，未绑定 session 时 no-op；`ui_contract_test.gd` 源码扫描保证 UI 不计算伤害、不选择敌人 AI 行动、不直接读取 Mod 文件。
