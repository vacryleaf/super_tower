# 需求文档：战斗结算下沉与 BattleService 契约化

> 功能名称：battle-settlement-downsizing（战斗结算下沉）
> 状态：已确认（待开发）
> 提出背景：`play_session.gd`（1,618 行 / ~130 函数）内联战斗结算规则，`battle_service.gd` 与 `trigger_service.gd` 共 12 处反向调用 `session.deal_damage`，依赖方向倒置，服务无法独立测试
> 关联领域：战斗、架构
> 相关文档：`docs/architecture-optimization-directions.md`、`docs/combat/`、`docs/system.index.md`

## 1. 背景与目标

### 背景

已代码验证的事实基线：

| 事实 | 证据 |
| --- | --- |
| 结算入口 `deal_damage()` 位于 `play_session.gd:774`，主体约 60 行结算规则 | 读代码确认 |
| 被 `battle_service.gd` 反向调用 9 处（154/166/192/201/216/245/592/891/1027） | grep 确认 |
| 被 `trigger_service.gd` 反向调用 3 处（107/114/127） | grep 确认 |
| `battle_service.gd` 对 `session.*` 隐式访问 310 处（player 56、battle_log 54、status_service 44、enemies 38、last_events 32…） | grep 确认 |
| 反击/反弹结算（`_trigger_counter_attack` 700、`_trigger_reflect_damage` 717）与嘲讽/决斗清理逻辑内联在 play_session | 读代码确认 |

### 目标

- [x] 战斗结算规则（`deal_damage` 主体）从 `play_session.gd` 迁入 `battle_service.gd`，`play_session` 仅保留同签名薄转发
- [x] `battle_service.gd` 可脱离完整 `PlaySession` 独立测试（服务级直测，模式参考 `combat_mechanics_test.gd` 已有先例）
- [x] 依赖方向统一为 `play_session → battle_service`、`trigger_service → session（转发）`，结算规则单一入口
- [x] **行为零变化**：迁移是纯代码移动，不修改任何数值、条件、日志文案或事件触发顺序
- [x] UI 与既有测试调用方式不变（`session.deal_damage(ctx)` 仍可用）

### 非目标

- 不新增战斗行为、不调整任何数值或规则
- 不重构 `trigger_service.gd` 对 session 的调用（本轮只处理结算入口位置）
- 不拆 `main.gd` / `pre_run_view.gd`（另立任务，见文末）
- 不引入新框架、新抽象类或场景层改动
- 不恢复模拟战斗路径（`CombatEngine` / `RunSimulator` / `SimulationRewardPolicy` / `ChargeSimulator`）

## 2. 用户流程与规则

本需求为纯结构迁移，无用户可见流程变化。

### 规则不变项（迁移时逐条对照，任何差异即失败）

| 规则 | 当前行为（`play_session.gd:774-830`） | 迁移后 | 依据 |
| --- | --- | --- | --- |
| 嘲讽重定向 | `ActionSource.is_interactive(source)` 且攻击方 side=player 时，`_active_taunt_target()` 重定向目标 | 不变 | 774-788 |
| 目标池 | `_opposing_units(source_actor)` 决定目标数组 | 不变 | 790 |
| 闪避分支 | dodged → 日志 + `last_events` dodge + `ON_DODGE` 触发，立即返回 | 不变 | 796-800 |
| 命中日志 | "命中/暴击命中：护甲减免 X，格挡吸收 Y，造成 Z 点伤害" | 不变 | 802-808 |
| 暴击 | `is_critical` 标记进 last_events；交互源触发 `ON_CRITICAL` | 不变 | 802-823 |
| 触发链 | 交互源：`ON_HIT_DEALT` / `ON_HIT_RECEIVED`；击杀：`ON_KILL` | 不变 | 811-826 |
| 决斗清理 | `duel_target_index` 匹配击杀目标时置 -1 并记日志 | 不变 | 828-830 |
| 玩家状态同步 | 目标侧为 player 且 index==0 时 `_sync_player_combatant(target)` | 不变 | 794-795 |

## 3. 架构归属

### 结论

- 首要架构层：战斗流程层（`battle_service.gd` 结算入口）
- 次要架构层：会话编排层（`play_session.gd` 薄转发保留）
- 现有可复用入口：`battle_service.deal_damage_to_target()`（结算执行）、`play_session._enemy_turn` → `battle_service.enemy_turn`（既有薄转发模式）
- 不应修改的层：行为决策（`enemy_action_rules.gd`）、状态与触发（`status_service.gd`）、数据定义

### 模块影响表

| 层次 | 文件 | 方法、Schema 或数据入口 | 变更类型 | 职责 |
| --- | --- | --- | --- | --- |
| 战斗流程 | `GameProject/scripts/core/battle_service.gd` | **新增** `deal_damage(session: RefCounted, ctx: Dictionary) -> void` | 新增 | 唯一伤害结算入口：嘲讽重定向、目标池选择、闪避/命中分支、日志与 last_events、触发链、决斗清理、玩家状态同步 |
| 战斗流程 | `GameProject/scripts/core/play_session.gd` | `deal_damage(ctx)` 主体替换为一行 `battle_service.deal_damage(self, ctx)` | 修改 | 对外 API 兼容转发 |
| 战斗流程 | `GameProject/scripts/core/play_session.gd` | `_trigger_counter_attack` / `_trigger_reflect_damage` 中构造 ctx 后调用转发入口（调用点不变） | 不变 | 调用方无需改动 |
| 事件与触发 | `GameProject/scripts/core/trigger_service.gd` | 3 处 `session.deal_damage(extra_ctx)` | 不变 | 调用链不变（经 session 转发） |
| 测试与文档 | `GameProject/scripts/tests/battle_service_test.gd` | **新增**：服务级独立单测 | 新增 | 验证结算规则不经 play_session 可执行 |
| 测试与文档 | `run_tests.sh` / `run_tests.bat` | 如需将新测试接入总入口 | 修改（可选） | 跨平台验收入口 |

## 4. 数据契约

- 无新增字段、无存档结构变化、无 Schema 变化。
- `ctx` 字典契约保持不变，键：`source`（ActionSource 常量）、`target_index`、`final_damage`、`damage_type`（默认 "physical"）、`source_actor`（可选，缺省为 session.player）、`armor_multiplier`（默认 -1.0）、`is_critical`（可选）。
- 引用关系：`ActionSource.is_interactive()` 语义不变（交互源：active_attack / counter_attack / enemy_attack；非交互源：trigger_effect / dot / direct）。

## 5. 调用链与状态流

迁移前（现状，依赖倒置）：

```text
battle_service / trigger_service ──session.deal_damage(ctx)──▶ play_session.deal_damage（结算规则内联在此）
                                                            │
                                                            └─▶ battle_service.deal_damage_to_target（纯伤害执行）
```

迁移后（目标）：

```text
battle_service ──────────────────────────┐
trigger_service ──session.deal_damage(ctx)─▶ play_session.deal_damage（一行转发）
                                          │
                                          └─▶ battle_service.deal_damage(session, ctx)（唯一结算规则实现）
                                                  │
                                                  └─▶ deal_damage_to_target（纯伤害执行，不变）
```

`deal_damage(session, ctx)` 主体内部访问的 session 成员清单（迁移时逐项核对，全部沿用 battle_service 既有 `session.*` 访问模式）：

- `session.player`、`session.enemies`、`session.allies`（目标池）
- `session.battle_log`、`session.last_events`（日志与事件）
- `session.status_service`（触发）
- `session.duel_target_index`（决斗清理）
- `session._active_taunt_target()`、`session._opposing_units()`、`session._sync_player_combatant()`（辅助，均已在 battle_service 使用同模式）

## 6. UI 影响

- 无。UI 全部通过 `session.deal_damage` / `battle_service` 公共方法交互，调用方式不变。

## 7. 持久化与兼容性

- 无存档/Profile 变化。
- Windows/macOS：不改路径、不改命令、无大小写敏感文件变更。

## 8. 边界条件与风险

- [x] **self 语义**：`deal_damage` 主体中所有原 `self.` 访问必须改为显式 `session.` 参数访问；`play_session.deal_damage` 转发时传 `self`。这是最大风险点，逐行核对。
- [x] **duel_target_index 比较**：828 行 `target_pool == enemies` 判断在迁移后需保持（`_opposing_units` 返回值与 `session.enemies` 的引用/内容比较语义不变）。
- [x] **触发上下文**：`fire_trigger` 的 context 中 `"session": self` 需改为 `"session": session`，键名与内容不变。
- [x] 日志文案一字不改（测试依赖文案断言的可能性：`combat_mechanics_test` 中 `assert_equal` 部分断言文本，需确认无涉及 deal_damage 日志文案的断言；如有，保持原样即可）。
- [x] 闪避分支提前 return 的路径顺序不变。
- [x] 回调顺序（ON_CRITICAL → ON_HIT_DEALT → ON_HIT_RECEIVED → ON_KILL）不变。

## 9. 测试矩阵

| 层次 | 测试场景 | 预期结果 | 测试文件或新增位置 |
| --- | --- | --- | --- |
| 回归 | 全量现有测试 | 全绿，零行为差异 | `run_tests.sh` / `run_tests.bat`（headless 运行 `tutorial_and_floors_test.gd`） |
| 战斗规则 | 服务级直测：构造最小桩 session（player/enemies/allies/battle_log/status_service），直接调 `battle_service.deal_damage(session, ctx)` | 嘲讽重定向、闪避分支、命中日志、ON_KILL 与决斗清理均按规则执行 | **新增** `GameProject/scripts/tests/battle_service_test.gd`（extends test_base.gd，参考 combat_mechanics_test 直测模式） |
| 战斗规则 | 服务级直测：`battle_service.execute_skill` / `enemy_turn` 在桩 session 上执行完整敌人回合 | 与经 play_session 结果一致 | 同上 |
| 编译检查 | 全部脚本加载无错误 | 无 SCRIPT ERROR / Failed to load | `run_tests.sh` / `run_tests.bat` |

### 桩 session 最小契约（battle_service_test.gd 需提供）

`player`、`enemies`、`allies`、`battle_log`、`last_events`、`status_service`、`duel_target_index`、`round_index`、`_active_taunt_target()`、`_opposing_units()`、`_sync_player_combatant()`、`deal_damage()`（转发）。

## 10. 验收标准

- [ ] `grep -n "func deal_damage" GameProject/scripts/core/play_session.gd`：函数体仅剩一行转发（`battle_service.deal_damage(self, ctx)`）
- [ ] `grep -n "deal_damage" GameProject/scripts/core/battle_service.gd`：存在完整结算实现且包含全部原规则分支（嘲讽/闪避/暴击/触发/决斗清理）
- [ ] `run_tests.sh`（macOS）与 `run_tests.bat`（Windows）全绿
- [ ] 新增 `battle_service_test.gd` 通过（含嘲讽重定向 + 决斗清理两个针对性用例）
- [ ] git diff 中无 `trigger_service.gd` 与 `enemy_action_rules.gd` 的改动
- [ ] git diff 中无行为性改动（数值、文案、条件），仅位置移动

## 11. 实现顺序（子线程执行步骤）

> 交接说明：以下步骤可由单个子线程顺序完成；每步后运行测试再进入下一步。全部为代码移动，禁止顺手修改其他逻辑。

1. **读代码建立上下文**：读 `play_session.gd:774-830`（deal_damage 主体）、`battle_service.gd:1-60`（既有 `session: RefCounted` 风格）、`battle_service.gd:645-675`（deal_damage_to_target 签名）、`action_source.gd` 全文。
2. **在 battle_service.gd 新增 `deal_damage(session, ctx)`**：将 play_session 774-830 主体逐行迁移；`self` → `session`；`fire_trigger` 上下文 `"session": self` → `"session": session`；`player` 引用 → `session.player`（ctx.source_actor 缺省逻辑保留）。
3. **替换 play_session.deal_damage 为薄转发**：函数体替换为 `battle_service.deal_damage(self, ctx)`（保留签名、注释说明转发语义）。
4. **运行回归**：`bash run_tests.sh`（macOS）；确认全绿后再继续。
5. **新增 battle_service_test.gd**：extends `test_base.gd`；构造桩 session（见 §9 契约）；用例 A：嘲讽重定向（交互源攻击时目标被重定向）；用例 B：决斗清理（击杀决斗目标后 `duel_target_index` 置 -1）；用例 C：闪避分支（dodged 时无伤害事件）；用例 D：非交互源（`trigger_effect`）不受嘲讽影响。
6. **验证无行为漂移**：`git diff` 人工核对仅位置移动；`grep -c "session\." battle_service.gd` 记录新基线。
7. **文档回写**：更新 `docs/combat/` 中描述结算入口位置的文档（如有）；本文件状态改为"已实现"。
8. **（可选，子线程自主判断）** 将 `battle_service_test.gd` 加入总入口运行链（若 `tutorial_and_floors_test.gd` 已有串联其他测试的模式则沿用）。

## 12. 待确认问题

| 问题 | 影响 | 默认假设 | 决策人 | 状态 |
| --- | --- | --- | --- | --- |
| `combat_mechanics_test.gd` 是否断言 deal_damage 相关日志文案？ | 若有，迁移后文案必须逐字保留 | 无文案断言，仍按"一字不改"执行 | 开发子线程 | 执行时确认 |
| `tutorial_and_floors_test.gd` 是否已串联全部测试脚本？ | 决定新测试接入方式 | 以现有串联模式为准 | 开发子线程 | 执行时确认 |
| `docs/combat/` 是否有描述结算入口在 play_session 的文档？ | 需同步回写 | 有则更新，无则跳过 | 开发子线程 | 执行时确认 |

## 13. 后续任务（不在本次范围）

- **方向 D：性能护栏**（可选，半小时工作量）：新增 `tests/performance_guard_test.gd`，headless 下循环 1,000 回合纯逻辑战斗（不创建 UI），断言总耗时上限（建议初值 5 秒，以本机实测为基准）并打印耗时基线。注意：测试内模拟 ≠ 恢复运行时模拟战斗路径，注释中必须写明。
- **方向 C：UI 拆分**：`main.gd`（1,086 行）与 `pre_run_view.gd`（920 行）渐进拆分，控件构建统一走 `ui_helpers.gd`。跟随新页面需求执行，不做单独大重构。另行立项。
- **方向 E：battle_state 边界**：需先读 `battle_state.gd` 与 `docs/combat/` 确认设计意图，再定是否将散落战斗状态（`duel_target_index`、`ai_turn_stage`、`counter_stance_charges` 等）集中。待确认。
