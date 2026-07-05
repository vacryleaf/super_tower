# 11 技术建议

## 推荐技术栈

推荐使用：

- 引擎：Godot 4.x Stable。
- 语言：GDScript。
- 渲染：2D UI 为主，必要时使用简单粒子和动画。
- 数据：JSON 或 Godot Resource，首版推荐 JSON 数据表 + Resource 运行时包装。
- 平台：Windows、macOS、Linux、Android、iOS，后续可评估 Web。

## 项目结构建议

```text
GameProject/
  data/
    cards/
    classes/
    equipment/
    equipment_sets/
    enemies/
    enemy_traits/
    enemy_skills/
    rewards/
  scenes/
    boot/
    menu/
    combat/
    reward/
    inventory/
  scripts/
    core/
    data/
    combat/
    cards/
    equipment/
    ui/
    save/
  assets/
    art/
    audio/
    fonts/
  tests/
```

## 数据驱动格式

卡牌、装备、技能和怪物都应数据驱动。代码负责解释规则，内容由数据表配置。

卡牌字段建议：

```json
{
  "id": "warrior_heavy_slash",
  "name": "重劈",
  "type": "skill",
  "class": "warrior",
  "rarity": "common",
  "tags": ["attack", "rage"],
  "cost": 1,
  "effects": [
    { "kind": "damage", "amount": 12 },
    { "kind": "rage_bonus_damage", "rage_cost": 3, "amount": 8 }
  ]
}
```

装备字段建议：

```json
{
  "id": "iron_helm",
  "name": "铁盔",
  "type": "equipment",
  "slot": "head",
  "equipment_kind": "normal",
  "set_id": null,
  "tags": ["armor"],
  "stats": { "hp": 14, "attack": 0, "armor": 3 },
  "effects": []
}
```

套装装备字段建议：

```json
{
  "id": "iron_vanguard_helm",
  "name": "铁壁先锋头盔",
  "type": "equipment",
  "slot": "head",
  "equipment_kind": "set",
  "set_id": "iron_vanguard",
  "tags": ["armor", "counter"],
  "stats": { "hp": 4, "attack": 0, "armor": 1 },
  "effects": []
}
```

套装定义字段建议：

```json
{
  "id": "iron_vanguard",
  "name": "铁壁先锋",
  "bonus_thresholds": {
    "2": [{ "kind": "modify_defend_armor", "amount": 3 }],
    "4": [{ "kind": "gain_rage_on_first_unblocked_damage", "amount": 2 }],
    "6": [{ "kind": "double_first_counter_damage_each_turn" }]
  }
}
```

融合附着字段建议：

```json
{
  "source_card_id": "attachment_attack_flat",
  "source_type": "tower_attachment",
  "rarity": "common",
  "tags": ["attack"],
  "acquired_floor": 23,
  "power_tier": 2,
  "effects": [
    { "kind": "modify_attack_flat", "amount": 5, "scaled_field": "A", "locked_on_acquire": true }
  ],
  "run_id": "current_run"
}
```

## 存档边界

永久存档保存：

- 角色列表。
- 职业解锁。
- 基础卡牌和装备解锁。
- Boss 奖励获得的永久装备。
- Boss 奖励获得的职业永久技能。
- 最高层数。
- 设置。

单局存档保存：

- 当前层数。
- 当前战斗序号。
- 当前生命。
- 当前装备实例。
- 当前 4 个技能槽。
- 当前局内技能背包，包括职业塔内技能和通用塔内技能。
- 当前局内融合附着。
- 当前基础行动附着，包括普通攻击、防御、躲避。
- 当前战斗状态卡抽取配置、当前持有状态卡、已使用记录和消耗记录。

新游戏或死亡时必须清空单局存档中的塔内附着卡和所有融合附着。

## 核心模块

建议先实现以下模块：

| 模块 | 职责 |
| --- | --- |
| RunState | 管理当前爬塔局状态。 |
| CharacterState | 管理角色属性、职业资源、装备和技能。 |
| CombatController | 管理回合流程、行动力、基础行动、怪物意图和胜负。 |
| ActionResolver | 解释普通攻击、防御、躲避、技能和装备主动效果。 |
| CardResolver | 解释状态卡修饰效果。 |
| EnemySystem | 管理敌人数据、特性、技能、意图、先手和楼层数值成长。 |
| EquipmentSystem | 管理装备栏、普通装备、套装件数、2/3/4/5/6 套装能力和主动触发。 |
| FusionSystem | 管理装备、技能、基础行动的融合目标和效果合并；不设置附着数量上限。 |
| RewardGenerator | 根据职业、构筑、层数和怪物类型生成奖励；普通怪/精英怪排除装备卡，并处理技能去重。 |
| TutorialSystem | 管理新手引导固定战斗、固定解锁、提示高亮、失败保护和完成标记。 |
| SaveService | 区分永久存档和单局存档。 |

## 原型开发顺序

1. 实现单场战斗：行动力、普通攻击、防御、躲避、怪物意图、胜负。
2. 实现战士和弓箭手基础属性与职业资源。
3. 实现 4 技能槽与技能使用。
4. 实现 12 个装备位置与装备卡，其中包含 11 类装备栏和 2 个戒指位置。
5. 实现每层 10 场战斗的高塔循环，并支持单敌人与多敌人编队。
6. 实现第 1 层新手引导固定战斗、固定解锁、提示高亮、失败保护和完成标记。
7. 实现普通怪 3 选 1、精英怪 4 选 1、Boss 非装备卡 5 选 1，并确保普通怪和精英怪不出现装备卡。
8. 实现 Boss 永久装备与职业永久技能/塔内技能奖励，并保证职业永久技能和塔内技能都不重复获取。
9. 实现状态卡抽取，并限制为行动倍率、确定暴击、强化躲避、强化防御和紧急回撤等行动修饰。
10. 实现塔内附着卡和技能卡融合到装备、已装备技能和基础行动。
11. 实现永久存档和单局存档分离。
12. 实现敌人单位、战斗编队、特性、技能和普通/精英/Boss 数值成长。
13. 扩充首版内容表。
14. 做 PC 与移动端横屏 UI 适配。

## 风险点

- 融合效果过多会导致规则解释复杂，应先限制效果类型。
- 装备栏很多，移动端横屏 UI 仍需要分页，不能强行塞进一屏。
- 永久存档和单局存档必须分离，否则会破坏新游戏不继承塔内附着的设计。
- 奖励生成如果脱离玩家当前构筑，玩家难以形成流派；如果过度定向，会降低惊喜感。
