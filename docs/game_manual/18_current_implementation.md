# 18 当前实现总览

本文记录当前代码真实状态，用于接手项目、排查问题和规划后续开发。设计类文档说明“应该是什么”，本文说明“现在代码怎么运行”。

## 项目与运行环境

- Godot 版本：Godot 4.5。
- 主项目目录：`GameProject/`。
- 主场景：`GameProject/scenes/main.tscn`。
- 主入口脚本：`GameProject/scripts/main.gd`。
- Windows 启动脚本：`start_game.bat`。
- 测试脚本：`run_tests.bat`、`run_tests.sh`。
- 目标开发环境：Windows 与 macOS 都必须可运行。新增路径、脚本和命令时不得只兼容单一系统。

测试脚本使用 Godot 的 `--headless --quiet --no-header`，避免启动噪音。成功时脚本输出 `ALL TESTS PASSED`；失败时 Godot error 仍会输出。

## 运行入口

### UI 入口

`main.gd` 负责界面编排和用户交互入口，包括：

- 标题菜单、存档槽、职业选择、剧情/教程入口。
- 战斗页、奖励页、装备页、技能管理页、图鉴/设置等 UI 切换。
- 把按钮操作转发给 `PlaySession`。

`main.gd` 不应该新增战斗规则、奖励规则或存档规则。新增 UI 区块时优先放到 `scripts/ui/*_view.gd`。

### 会话入口

`PlaySession` 是运行时会话门面，持有并委托核心服务：

- `BattleState`：当前战斗/单局状态。
- `BattleService`：真实交互战斗流程。
- `RunSimulator`：自动模拟教程、正式层和战役基线。
- `RewardService` / `RewardApplyService`：奖励生成与应用。
- `ChargeService`：充能附着收集、充能、使用和结算。
- `SaveProfile` / `RunStateSerializer`：永久 profile 与 active run 存档。
- `StatusService` / `TriggerService`：状态解析和触发器。
- `SetEffectService`：套装战斗开始效果。

`PlaySession` 允许保留轻量委托入口，但不应继续回填大段规则逻辑。

## 核心模块职责

| 模块 | 当前职责 |
| --- | --- |
| `data_catalog.gd` | 内置数据表：职业、技能、装备、消耗品、套装、教程战斗、敌人单位。 |
| `data_repository.gd` | 读取外部 JSON 数据并提供数据表接口。 |
| `combatant.gd` | 将玩家/敌人数据标准化为战斗单位，处理伤害、护甲、格挡、闪避、嘲讽、格挡同步。 |
| `combat_rules.gd` | 共享战斗规则：目标合法性、敌人构建、数值计算、鼠类命中特性、裂变、召唤、场地效果、回合末特性。 |
| `battle_service.gd` | 真实战斗中的玩家行动、敌人行动、技能执行、伤害和触发器调用。 |
| `combat_engine.gd` | 自动模拟完整战斗，用于教程/战役模拟和测试。必须尽量复用 `CombatRules`。 |
| `enemy_action_rules.gd` | 敌人行动决策、技能选择和意图文本。 |
| `status_service.gd` | 状态添加/移除、buff/debuff 清理、持续时间递减、属性解析、条件判断入口。 |
| `trigger_service.gd` | 执行 status trigger，包括 DOT、HOT、反伤、吸血、格挡、闪避、状态施加、额外伤害、计数器。 |
| `action_pipeline.gd` | 计算单次行动上下文中的最终伤害。 |
| `modifier_pipeline.gd` | 汇总并解析装备套装、状态卡、技能和动态倍率。 |
| `skill_action_service.gd` | 解析新版 `actions` 技能结构。 |
| `charge_service.gd` | 真实战斗中的充能附着列表、随机充能、使用次数和攻击/防御修饰。 |
| `charge_simulator.gd` | 模拟战斗中的充能状态和重复结算。 |
| `set_effect_service.gd` | 战斗开始时套装效果应用。 |
| `character_service.gd` | 创建角色、装备/技能解锁、属性重算、装备/附着统计。 |
| `equipment_service.gd` | 装备、卸装、技能槽维护。 |
| `reward_service.gd` | 奖励候选生成和奖励种类判断。 |
| `reward_apply_service.gd` | 奖励应用到当前 `PlaySession`。 |
| `simulation_reward_policy.gd` | 模拟战役自动选择和应用奖励。 |
| `encounter_service.gd` | 怪物族群、楼层编队、普通/精英/Boss 战生成。 |
| `run_progress_service.gd` | 战斗胜利后的层数推进、教程完成、失败保护和恢复。 |
| `run_simulator.gd` | 自动跑教程、正式层和 campaign。内部 seed 固定，用于稳定测试。 |
| `battle_state.gd` | 单局/战斗运行时字段集合。 |
| `run_state_serializer.gd` | active run 的保存/读取和载入标准化。 |
| `save_profile.gd` | `user://savegame.json` 读写、多存档槽、旧格式兼容。 |
| `app_settings.gd` | 应用设置读写。 |
| `debug_logger.gd` | 调试日志。 |

## 真实战斗与模拟战斗

当前仍存在两套战斗流程：

- 真实交互战斗：`PlaySession` -> `BattleService`。
- 自动模拟战斗：`RunSimulator` -> `CombatEngine`。

二者不是完全重复。通用规则正在下沉到 `CombatRules`、`Combatant`、`StatusService`、`TriggerService`、`EnemyActionRules` 等共享层。新增规则时必须优先放入共享层，并同时检查真实和模拟调用点。

已经共享的典型规则：

- 敌人构建：`CombatRules.build_enemies()`。
- 目标合法性：`CombatRules.valid_target()`。
- 敌方攻击段数：`CombatRules.enemy_attack_segments()`。
- 鼠类命中效果：`CombatRules.apply_rat_on_hit()`。
- 腐败结算：`CombatRules.resolve_corruption()`。
- 裂变/召唤/场地效果/回合末特性：`CombatRules`。
- 单位伤害与同步：`Combatant`。

仍需重点防漂移的区域：

- `BattleService.execute_skill()` 与 `CombatEngine` 中模拟玩家技能逻辑。
- `BattleService.enemy_attack()` 与 `CombatEngine._apply_enemy_attack()`。
- 真实战斗 `ChargeService` 与模拟战斗 `ChargeSimulator`。

## 状态与触发器

状态结构主要使用字典字段：

- `id`：唯一标识。
- `name`：展示名。
- `kind`：`buff` 或 `debuff`。
- `stack`：`replace` 或 `stack`。
- `effects`：静态属性修饰。
- `conditional_effects`：带条件的属性修饰。
- `tick_effects`：回合 tick。
- `triggers`：事件触发动作。
- `duration`：持续回合，`-1` 表示整场。

`StatusService` 持有 `TriggerService`，`TriggerService` 通过弱引用访问 `StatusService`，避免 `RefCounted` 循环引用导致 Godot 退出泄漏。

常用 trigger 事件定义在 `trigger_events.gd`，触发点包括：

- `on_battle_start`
- `on_turn_start`
- `on_turn_end`
- `on_hit_dealt`
- `on_hit_received`
- `on_kill`
- `on_dodge`
- `on_attack_complete`

## 存档结构

项目区分永久 profile 和单局 active run。

永久 profile 保存：

- 队伍 roster。
- 角色永久装备、永久技能、教程完成状态。
- 塔币。
- 当前 active run 快照。

active run 保存：

- 当前职业、楼层、战斗序号、阶段。
- 玩家、敌人、盟友、当前遭遇。
- 能量、冷却、格挡、闪避、状态卡、充能、套装计数器。
- 战斗日志、奖励候选、当前消息等。

新增永久字段优先改 `SaveProfile` 和 `CharacterService`。新增单局字段优先改 `BattleState` 和 `RunStateSerializer`。

## 数据来源

当前数据有两类来源：

- `data_catalog.gd`：运行时代码内置表。
- `GameProject/data/catalog_v1.json`：外部表，部分测试会验证它与运行时表字段一致。

新增内容时要注意：

- 运行时必须能从 `DataCatalog` 查到。
- 外部表若参与 parity 测试，字段必须同步。
- 技能 id、装备 id、敌人 id 一旦进入存档，要考虑旧存档兼容。

## UI 结构

UI 组件集中在 `GameProject/scripts/ui/`。当前主要视图包括：

- `title_menu_view.gd`
- `save_slot_view.gd`
- `class_select_view.gd`
- `camp_view.gd`
- `battle_view.gd`
- `action_bar_view.gd`
- `reward_view.gd`
- `equipment_view.gd`
- `skill_manage_view.gd`
- `settings_view.gd`
- `bestiary_view.gd`

新增 UI 时应保持 `main.gd` 只编排，不承载复杂控件构建。视图层不写战斗、奖励、存档规则。

## 测试

测试入口：

- Windows：`run_tests.bat`
- macOS/Linux：`run_tests.sh`
- Godot 入口：`res://scripts/tests/tutorial_and_floors_test.gd`

测试 suite：

- `data_validation_test.gd`
- `combat_mechanics_test.gd`
- `reward_system_test.gd`
- `persistence_test.gd`
- `campaign_test.gd`

`RunSimulator` 与 `CombatEngine` 支持固定 seed，保证 campaign baseline 测试稳定。

## 跨平台约束

项目同时在 Windows 和 macOS 开发。新增或修改内容必须注意：

- 文件名大小写必须一致，不能依赖 Windows 大小写不敏感行为。
- 路径拼接优先使用 Godot 的 `res://`、`user://`、`path_join()` 或脚本内平台分支。
- Shell 脚本要有 Windows/macOS 对应方案，或使用跨平台解释器并明确依赖。
- 不要把 `C:\...`、`/Applications/...` 等本机路径写进核心逻辑。
- 测试命令优先通过 `run_tests.bat` / `run_tests.sh`。

## 接手阅读顺序

1. `docs/game_manual/README.md`
2. `docs/game_manual/01_core_loop.md`
3. `docs/game_manual/07_combat.md`
4. `docs/战斗回合详述.md`
5. `docs/game_manual/17_code_architecture.md`
6. 本文
7. `GameProject/scripts/core/play_session.gd`
8. `GameProject/scripts/core/battle_service.gd`
9. `GameProject/scripts/core/combat_engine.gd`
10. `GameProject/scripts/core/combat_rules.gd`
11. `GameProject/scripts/tests/tutorial_and_floors_test.gd`
