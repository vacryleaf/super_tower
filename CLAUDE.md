# Project Architecture Rules

## 重要：不要读取图片，不要读取读片，不要读取图片

## 核心原则：严格遵循现有架构设计

所有功能实现必须遵循项目已有的架构模式和设计约定，不得自行发明新的架构范式。

**实现新功能前，必须先确认架构方案：**
- 拒绝硬编码，任何功能都应在现有架构层次中找到正确的位置
- 先分析功能属于哪个架构层次（数据定义/状态转换/行为决策/战斗流程/状态服务），再决定在哪实现
- 在开始编码前，明确回答"这个功能应该放在哪个文件、哪个方法中，为什么"
- 如果功能跨越多个层次，必须梳理清楚每层的职责边界

### 架构层次

本项目采用数据驱动的战斗系统，层次如下：

1. **数据定义层** (`data_catalog.gd`, `trait_catalog.gd`) — 定义所有静态数据
2. **状态转换层** (`combatant.gd`) — 将特性/装备等数据转换为运行时 status 字典
3. **行为决策层** (`enemy_action_rules.gd`) — 根据特性和状态决定敌人行为
4. **战斗流程层** (`combat_engine.gd` 模拟 / `battle_service.gd` 实时) — 战斗主循环
5. **状态服务层** (`status_service.gd`, `trigger_service.gd`) — 通用状态解析和触发器

### 实现新特性的规则

- 优先使用现有的 **status/trigger 系统**（effects、conditional_effects、triggers）而非硬编码
- 需要行为修改的特性在 `enemy_action_rules.gd` 中实现，而非在战斗引擎中分散处理
- `combat_engine.gd`（模拟）和 `battle_service.gd`（实时）必须保持行为一致
- 所有特性效果通过 `_apply_trait_statuses()` 或 `_apply_end_round_traits()` 统一入口

### 代码风格

- 写注释说明代码意图和逻辑
- 不引入不必要的抽象
- Godot 4.7 类型系统：`:=` 必须能从右侧直接推断类型，否则使用显式类型标注
