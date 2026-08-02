# 技能运行逻辑

状态：已实现。

1. UI/PlaySession 提交技能 ID 和目标。
2. `CharacterService`/技能槽检查解锁、槽位、资源和冷却。
3. `SkillActionService` 取得技能动作；`ActionPipeline` 按顺序执行。
4. 命中、状态、资源和冷却通过 BattleService/StatusService/TriggerService 同步。
5. 日志记录技能 ID、动作结果和触发事件，战斗后保存到 active run。

开发测试直接构造实时 BattleService，不生成模拟战斗。
