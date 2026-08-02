# Schema 注册表

状态：设计已确认待实现。

| Schema | 主要字段 | 运行时解释器 |
| --- | --- | --- |
| `skill.v1` | id、slot、cost、cooldown、targets、actions | SkillActionService / ActionPipeline |
| `weapon.v1` | id、slot、agility、attack_damage、critical_weight、skill_1/2 | DataCatalog / Combatant |
| `item.v1` | id、kind、stack、consumable、effects、图鉴字段 | Item/Reward 服务 |
| `monster.v1` | id、rank、stats、passive_skills、skills、behavior_weights | EncounterService / Combatant / EnemyActionRules |
| `status.v1` | id、kind、stack、duration、effects、conditional_effects、triggers | StatusService / TriggerService |
| `mod_manifest.v1` | id、version、api_version、dependencies、content | Mod Loader |

所有 Schema 都必须定义必填字段、默认值、枚举、范围、引用规则和迁移策略；具体字段见各领域 `data/*_schema.md`。
