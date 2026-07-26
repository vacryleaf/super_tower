# 14 敌人设计

本文已同步为当前实现版。远期“50 种敌人单位”不再作为当前设计事实；当前代码以 `DataCatalog` 中的 5 个怪物群落和现有单位池为准。

## 当前敌人池

当前实现包含：

- 5 个怪物群落：老鼠群落、骷髅群落、暗影群落、术士群落、异变群落。
- 9 个普通单位。
- 6 个精英单位。
- 5 个 Boss 单位。

每层固定 10 场战斗，节奏为 7 场普通、2 场精英、1 场 Boss。每层会选定一个怪物群落，同一层的普通、精英和 Boss 都来自同一群落。

## 怪物群落

| 群落 ID | 名称 | 普通单位 | 精英单位 | Boss |
| --- | --- | --- | --- | --- |
| `rat` | 老鼠群落 | 腐鼠、尖牙鼠、狩猎鼠 | 使用普通鼠单位精英化 | 鼠王 |
| `guard` | 骷髅群落 | 刀盾骷髅、长矛骷髅、铁甲骷髅 | 刀盾骷髅、长矛骷髅、铁甲骷髅 | 骷髅典狱长 |
| `shadow` | 暗影群落 | 盗贼、暗弩手 | 暗影猎长 | 暗影公爵 |
| `caster` | 术士群落 | 学徒术士 | 深塔祭司 | 深渊先知 |
| `mutant` | 异变群落 | 晶刺兽 | 裂塔巨兽 | 裂塔核心 |

## 楼层数值公式

普通非固定数值单位会随楼层成长。当前公式由 `Combatant.from_enemy_unit()` 和相关战斗构建逻辑应用。

固定数值单位带有 `fixed_stats = true`，主要用于鼠群和骷髅基准单位。固定数值单位仍会按普通、精英、Boss rank 和楼层进行必要缩放，但不会走完全相同的随机系数设计。

当前 rank 技能倍率：

| Rank | 技能倍率 |
| --- | ---: |
| normal | 1.00 |
| elite | 1.20 |
| boss | 1.45 |

## 编队规则

战斗由 `EncounterService` 生成。普通、精英和 Boss 遭遇都可以包含多个单位。编队规则必须满足：

- 击败该场全部敌人才算胜利。
- 多敌人战斗仍只发放一次战斗胜利奖励。
- 召唤或裂变产生的新单位不额外发放奖励。
- 新召唤/裂变单位通过 `available_round` 控制，避免当回合立即行动。

## 当前被动特性

当前敌人和套装使用的主要被动包括：

| 特性 | 当前效果 |
| --- | --- |
| `swarm` | 群袭单位普通攻击命中流程后，其他存活群袭同伴对同一目标各协攻一次；协攻不再触发群袭。 |
| `corruption` | 命中后施加腐败，玩家回合开始结算持续伤害。 |
| `fang` | 命中后施加尖牙减甲 debuff。 |
| `thick_skin` | 以防御/护甲为基础提高战斗耐久。 |
| `break_armor` | 攻击时降低目标护甲有效性。 |
| `guard` | 存活时保护其他友军，使其受到伤害降低。 |
| `tank` | 作为前排保护后排单位。 |
| `taunt` | 嘲讽目标选择。 |
| `first_strike` | 战斗开始时先于玩家行动一次。 |
| `hidden` | 有可见敌人存活时，隐藏单位不能作为常规目标。 |
| `backline` | 有前排存活时，后排单位受到保护。 |
| `mark` | 通过触发器提高目标受伤。 |
| `cunning` | UI 中隐藏真实意图。 |
| `curse` | 命中或触发时施加诅咒类 debuff。 |
| `abyss_communication` | 术士群落协同特性。 |
| `spell_shield` | 法术/技能防护特性。 |
| `toxic_mist` | 场地效果，每 3 回合对玩家和盟友造成基于持有者攻击的伤害。 |
| `evade` | 闪避相关特性。 |
| `revive` | 复活/韧性相关特性。 |
| `charge` | 充能后强化后续行动。 |
| `split` | 低血量触发裂变，生成延后一回合行动的分身。 |
| `blood_moon` | 场地效果，提高攻击和治疗。 |
| `enrage` | 低生命时提高攻击，同时提高受到伤害。 |

## 当前普通单位

| ID | 名称 | 群落 | 被动 | 技能 |
| --- | --- | --- | --- | --- |
| `normal_rat_01` | 腐鼠 | rat | `swarm`, `corruption` | - |
| `normal_rat_02` | 尖牙鼠 | rat | `swarm`, `fang` | - |
| `normal_rat_03` | 狩猎鼠 | rat | `swarm` | `enemy_pursuit` |
| `normal_skeleton_01` | 刀盾骷髅 | guard | `thick_skin` | `enemy_skeleton_taunt` |
| `normal_skeleton_02` | 长矛骷髅 | guard | `break_armor` | `enemy_skeleton_heavy_strike` |
| `normal_skeleton_03` | 铁甲骷髅 | guard | `thick_skin`, `guard`, `tank`, `taunt` | `enemy_skeleton_fortify`, `enemy_skeleton_taunt` |
| `normal_shadow_01` | 盗贼 | shadow | `first_strike` | `enemy_quick_evade`, `enemy_rend` |
| `normal_shadow_02` | 暗弩手 | shadow | `mark`, `hidden` | `enemy_dark_bolt`, `enemy_weaken` |
| `normal_caster_01` | 学徒术士 | caster | `curse`, `backline` | `enemy_weaken`, `enemy_dark_bolt` |
| `normal_mutant_02` | 晶刺兽 | mutant | `break_armor` | `enemy_rend`, `enemy_enrage` |

## 当前精英单位

| ID | 名称 | 群落 | 被动 | 技能 |
| --- | --- | --- | --- | --- |
| `elite_skeleton_01` | 刀盾骷髅 | guard | `thick_skin` | `enemy_skeleton_taunt` |
| `elite_skeleton_02` | 长矛骷髅 | guard | `break_armor` | `enemy_skeleton_heavy_strike` |
| `elite_skeleton_03` | 铁甲骷髅 | guard | `thick_skin`, `guard` | `enemy_skeleton_fortify`, `enemy_skeleton_taunt` |
| `elite_shadow_01` | 暗影猎长 | shadow | `mark`, `cunning` | `enemy_dark_bolt`, `enemy_quick_evade` |
| `elite_caster_01` | 深塔祭司 | caster | `curse`, `abyss_communication` | `enemy_weaken`, `enemy_shadow_armor` |
| `elite_mutant_01` | 裂塔巨兽 | mutant | `revive` | `enemy_heavy_strike`, `enemy_enrage` |

## 当前 Boss

| ID | 名称 | 群落 | 被动 | 技能 |
| --- | --- | --- | --- | --- |
| `boss_rat_king` | 鼠王 | rat | `swarm`, `corruption` | `enemy_pursuit`, `enemy_call_rat_pack`, `enemy_bite` |
| `boss_skeleton_warden` | 骷髅典狱长 | guard | `thick_skin`, `enrage` | `enemy_skeleton_fortify`, `enemy_skeleton_heavy_strike` |
| `boss_shadow_duke` | 暗影公爵 | shadow | `first_strike`, `evade`, `mark`, `cunning` | `enemy_dark_bolt`, `enemy_quick_evade`, `enemy_weaken` |
| `boss_deep_oracle` | 深渊先知 | caster | `curse`, `spell_shield`, `toxic_mist` | `enemy_weaken`, `enemy_dark_bolt`, `enemy_shadow_armor` |
| `boss_tower_core` | 裂塔核心 | mutant | `revive`, `charge`, `split`, `blood_moon` | `enemy_heavy_strike`, `enemy_enrage`, `enemy_rend` |

## 开发约束

- 新敌人必须先进入 `DataCatalog` 或外部 catalog，再由 `EncounterService` 引用。
- 每个敌人的 `passive_skills` 保持 4 个槽位。
- 新敌人技能必须在 `DataCatalog.SKILLS` 或 `DataCatalog.INNATE_SKILLS` 中存在。
- 新行为决策优先放入 `EnemyActionRules`，不要写进战斗引擎主循环。
- 新特性优先使用 status/trigger、`CombatRules`、`StatusService` 或 `TriggerService`，不要在 `BattleService` 和 `CombatEngine` 各写一套。
