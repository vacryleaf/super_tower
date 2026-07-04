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
    enemies/
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
  "rarity": "common",
  "tags": ["armor"],
  "stats": { "max_hp": 10 },
  "effects": []
}
```

融合附着字段建议：

```json
{
  "source_card_id": "fusion_sharp",
  "source_type": "enhancement",
  "rarity": "common",
  "tags": ["attack"],
  "effects": [
    { "kind": "modify_damage", "amount": 3 }
  ],
  "run_id": "current_run"
}
```

## 存档边界

永久存档保存：

- 角色列表。
- 职业解锁。
- 基础卡牌和装备解锁。
- 最高层数。
- 设置。

单局存档保存：

- 当前层数。
- 当前战斗序号。
- 当前生命。
- 当前装备实例。
- 当前 4 个技能槽。
- 当前局内融合附着。
- 当前局内 Buff。
- 当前卡组、抽牌堆、弃牌堆和消耗区。

新游戏或死亡时必须清空单局存档中的融合、增强和临时 Buff。

## 核心模块

建议先实现以下模块：

| 模块 | 职责 |
| --- | --- |
| RunState | 管理当前爬塔局状态。 |
| CharacterState | 管理角色属性、职业资源、装备和技能。 |
| CombatController | 管理回合流程、抽牌、能量、胜负。 |
| CardResolver | 解释卡牌效果。 |
| EquipmentSystem | 管理装备栏、装备效果和主动触发。 |
| FusionSystem | 管理融合目标、附着上限和效果合并。 |
| RewardGenerator | 根据职业、构筑和层数生成奖励。 |
| SaveService | 区分永久存档和单局存档。 |

## 原型开发顺序

1. 实现单场战斗：抽牌、能量、打牌、怪物意图、胜负。
2. 实现战士和弓箭手基础属性与职业资源。
3. 实现 4 技能槽与技能使用。
4. 实现 11 个装备栏与装备卡。
5. 实现每层 10 怪的高塔循环。
6. 实现胜利奖励三选一。
7. 实现增强卡、技能卡、Buff 卡融合到装备和技能。
8. 实现永久存档和单局存档分离。
9. 扩充首版内容表。
10. 做 PC 与移动端 UI 适配。

## 风险点

- 融合效果过多会导致规则解释复杂，应先限制效果类型。
- 装备栏很多，移动端 UI 需要分页，不能强行塞进一屏。
- 永久存档和单局存档必须分离，否则会破坏新游戏不继承塔内增强的设计。
- 奖励生成如果完全随机，玩家难以形成构筑；如果过度定向，会降低惊喜感。

