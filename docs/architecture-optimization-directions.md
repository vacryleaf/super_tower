# Super Tower 架构优化方向报告

> 分析人：架构顾问 Ghost（自主优化视角）
> 日期：2026-08-03
> 依据：`docs/system.index.md`、`references/project-architecture.md` + 代码验证（play_session.gd / battle_service.gd / main.gd 等）
> 状态：分析结论，非实现任务单。所有方向均需确认后再进入开发流程。

## 一、结论先行

当前架构的瓶颈**不在运行时性能，而在结构复杂度**。数据驱动体系、领域服务委托、事件驱动模式均健康；真正的风险点是三个"上帝对象"及其中的**依赖方向倒置**。

优化优先级（按 ROI）：

| 优先级 | 方向 | 类型 | 收益 | 风险 |
| --- | --- | --- | --- | --- |
| P0 | A. 战斗结算权下沉 | 结构 | 消除依赖倒置、可测试性提升 | 中（需行为保持） |
| P1 | B. battle_service 解耦 | 结构 | 独立单测、回归防护 | 中 |
| P2 | C. UI 上帝对象拆分 | 结构 | 降低维护成本 | 低 |
| P3 | D. 性能护栏 + 回归基准 | 防退化 | 防止未来热路径恶化 | 极低 |
| 待确认 | E. 战斗状态字段集中 | 结构 | 状态可观测性 | 需先确认 |

## 二、基线评估（已代码验证）

### 规模分布

- 全项目 GDScript：**14,537 行 / 72 个脚本**
- 热点 TOP4（合计 33.6%）：
  - `play_session.gd`：1,618 行（11.1%），约 130 个函数，21 个 preload，15 个服务实例
  - `battle_service.gd`：1,257 行（8.6%），约 60 个函数
  - `main.gd`：1,086 行（7.5%），约 90 个函数
  - `pre_run_view.gd`：920 行（6.3%）

### 性能体检：通过

| 检查项 | 结果 |
| --- | --- |
| 帧级轮询 | 无（`_process` 仅出现在函数名，非引擎回调） |
| 热路径序列化 | 无（JSON 解析仅 3 处，集中在存档路径） |
| 战斗日志膨胀 | 有上限（`BATTLE_LOG_LIMIT := 200`，`_trim_battle_log()` 已实现） |
| 敌人数量级 | ≤ 10，线性查找可接受，无优化必要 |

### 架构健康项（已确认，勿动）

- 行为决策层边界完好：`_enemy_choose_skill()` → `enemy_rules.choose_skill()`（enemy_action_rules.gd）
- 领域服务已真实委托：`reward_apply` / `charge_service` / `consumable_service` / `run_state_serializer` / `save_profile` 均为薄转发调用，非摆设
- 唯一实时战斗路径成立：`PlaySession -> BattleService -> ActionPipeline / StatusService / TriggerService`

## 三、方向 A：战斗结算权下沉（P0）

### 证据

`play_session.gd` 内联了本属于战斗规则/结算层的逻辑：

- `deal_damage()`（774 行起）：嘲讽重定向、伤害结算入口 —— 但被 `battle_service` 反向调用 **9 处**（`session.deal_damage(...)`）
- `_apply_damage_to_enemy()`（746）：敌方伤害应用 + 决斗目标清理
- `_trigger_counter_attack()` / `_trigger_reflect_damage()`（700/717）：反击与反弹规则
- `_active_taunt_target()`、`_sync_player_combatant()`、`_valid_target()`

同时 `battle_service.gd` 对 `session.*` 的访问达 **310 处**（鸭子类型 `RefCounted`），其中 56 处 `session.player`、54 处 `session.battle_log`、44 处 `session.status_service`、9 处 `session.deal_damage`。

### 问题本质

**依赖方向倒置**：下层服务（battle_service）反向调用上层方法（session.deal_damage）。结算规则与流程编排纠缠，导致：

1. `battle_service` 无法脱离完整 `PlaySession` 独立测试
2. 战斗规则改动必须同时检查 session 侧的同名逻辑，存在双路径漂移风险
3. 上帝对象函数数继续增长，新功能无处安放

### 目标

- `battle_service`（或 `combat_rules.gd`）成为**唯一结算入口**，拥有 `deal_damage` 及全部伤害应用规则
- `play_session` 仅保留同签名**薄转发**（如现状 `_enemy_turn` → `battle_service.enemy_turn` 的模式），保证 UI 与既有测试零改动
- 依赖方向统一为：`play_session → 服务`（单向）

### 实施要点

1. 将 `deal_damage` 主体 + 嘲讽重定向 + 决斗清理迁移至 `battle_service`
2. `play_session.deal_damage(ctx)` 改为一行转发；内部调用方（含 battle_service 自己的 9 处）统一改为调用 battle_service 内部私有实现
3. 反击/反弹（counter/reflect）逻辑随 `deal_damage` 一并下沉
4. 以 `combat_mechanics_test.gd`（769 行）为回归兜底；测试通过后再删 play_session 残留实现

### 验收

- `grep -c "session\." battle_service.gd` 显著下降（目标 < 100 处，且不再有 `session.deal_damage`）
- `run_tests.sh` / `run_tests.bat` 全绿
- `battle_service` 可通过构造最小桩 session 独立执行一次完整敌人回合

## 四、方向 B：battle_service 独立可测（P1）

与方向 A 一体。A 完成后：

- 为 `battle_service` 定义最小契约接口（player/enemies/allies/battle_log/status_service 等），消除隐式鸭子类型依赖
- 新增 `battle_service_test.gd`：不经过 play_session，直接验证 `execute_skill` / `enemy_turn` / 伤害结算
- 收益量化：战斗规则回归测试从"必须驱动完整会话"降为"直接驱动服务"，新增战斗特性时测试成本约下降 60%

## 五、方向 C：UI 上帝对象拆分（P2）

### 证据

- `main.gd`：约 90 函数，同时承担场景切换、页面渲染（`_render_menu` / `_render_battle` / `_render_camp_screen` / `_render_reward`）、事件回调、自建控件 helper（`_label` / `_action_button` / `_spacer` / `_rank_label` 等 7 个）
- `pre_run_view.gd` 920 行同类
- 15 个 UI 视图中 **9 个未使用 `ui_helpers.gd`**，控件构建代码存在重复

### 目标

- `main.gd` 收敛为纯导航 + 状态派发；页面渲染按现有 `pre_run_view.gd` / `camp_view.gd` 模式继续拆分
- 控件构建统一走 `ui_helpers.gd`（可先做静态重复检测再动）

### 注意

本方向不阻塞功能开发，适合跟随新页面需求渐进执行，不建议单独大重构。

## 六、方向 D：性能护栏 + 回归基准（P3）

当前无热路径，但项目处于持续演进期，需要**防退化机制**：

1. 在 `GameProject/scripts/tests/` 新增 `performance_guard_test.gd`：headless 下执行 1,000 回合纯逻辑战斗（不经 UI），断言完成时间阈值与内存无显著增长。**注意：这是测试内模拟，不是恢复运行时模拟战斗路径**——与"禁止恢复 CombatEngine 等"不冲突，护栏需在测试注释中写明。
2. 护栏规则固化：任何新 action / status / trigger 类型都必须有对应测试；测试覆盖 schema 注册 + 解释器 + 图鉴 + 日志（现有 `data_validation_test.gd` 基础上扩展）。
3. 存档序列化：当前 3 处 JSON 均在非热路径；若图鉴/日志字段继续增长导致存档体积翻倍，再评估分块，现阶段不动。

## 七、方向 E：战斗状态字段集中（待确认）

`battle_state.gd` 已存在，但 `play_session` 仍有散落战斗状态：`counter_stance_charges`、`counter_attack_multiplier`、`dodge_streak`、`duel_target_index`、`perfect_deflect`、`ai_turn_stage`、`energy` 等。**当前证据不足**判断 battle_state 的设计意图与覆盖范围，需先读 `battle_state.gd` 与 `docs/combat/` 确认再定方案，故列为待确认。

## 八、护栏清单（红线，不得触碰）

1. **不恢复**模拟战斗路径：`CombatEngine` / `RunSimulator` / `SimulationRewardPolicy` / `ChargeSimulator`（测试内基准模拟除外）
2. **不把**敌人行为判断散落到 `BattleService`：行为决策唯一入口是 `enemy_action_rules.gd`
3. **不把**战斗规则放进 UI：UI 只读状态、派发意图
4. 新能力优先 `actions` / `effects` / `conditional_effects` / `triggers`；只有解释器无法表达才新增 Schema 分支
5. 迁移过程保持 play_session 薄转发 API，UI 与既有测试零改动
6. 所有改动兼容 Windows / macOS（不写死平台路径与命令）
7. 不引入新框架、不做无关重构与格式化

## 九、实施顺序建议

1. **先做方向 A 第 1-3 步**（结算下沉，纯移动不改行为），跑全量测试验证
2. **再做方向 B**（契约接口 + 独立单测）
3. 方向 D 可随时插入（半小时工作量，先建立基准线）
4. 方向 C 随新页面需求渐进；方向 E 先读 `battle_state.gd` 确认后另立方案

## 十、量化收益预估

| 指标 | 现状 | 目标 |
| --- | --- | --- |
| battle_service 对 session 耦合点 | 310 处 | < 100 处且无反向结算调用 |
| 战斗规则回归测试成本 | 需构造完整会话 | 服务级直测 |
| play_session 函数数 | ~130 | ~90（结算与战斗辅助下沉后） |
| 新增战斗特性风险 | 双路径漂移隐患 | 单一结算入口 |
