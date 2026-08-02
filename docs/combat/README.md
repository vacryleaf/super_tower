# 战斗领域

状态：已实现。

## 二级目录

- `design/`：战斗设计目标、回合顺序和状态/触发原则。
- `logic/`：实时战斗流程、行动管线、回合详述。
- `data/`：行动、状态、触发器数据契约。

唯一实时路径：`PlaySession -> BattleService -> ActionPipeline / StatusService / TriggerService`。
