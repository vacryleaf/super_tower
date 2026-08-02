# 教程与楼层流程

状态：已实现。

1. 新角色检测教程完成标记。
2. 未完成时进入固定 3 场教程；教程结束只更新教程状态。
3. 完成后从正式第 1 层第 1 场开始，不消耗正式楼层。
4. 正式每层按照 `DataCatalog.BATTLE_TYPES` 生成 10 场：normal、normal、elite、normal、normal、elite、normal、normal、normal、boss。
5. 每场胜利后结算奖励；第 10 场结束进入下一层或完成单局。
