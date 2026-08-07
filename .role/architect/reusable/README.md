# 可迁移顾问资产

状态：持续维护。

本目录保存**不绑定本项目**的通用顾问资产，供其他项目安装或作为新项目的 Skill 起点，**不作为本项目的运行依据**。

## 与本项目的关系

- 本项目运行时依据：`.role/`（角色体系）与 `.role/architect/SKILL.md`（architect 完整权威）。
- 本目录是上述资产的**脱敏可迁移版**：移除了本项目文件名、ID 和数值，保留可复用的工作流与模板。
- 本项目的架构判断、角色路由、需求流程一律以项目内权威来源为准，不读取本目录做项目决策。

## 资产

- `project-architecture-consultant/SKILL.md`：通用架构顾问 Skill（脱敏版）。
- `project-architecture-consultant/references/requirements-template.md`：需求文档模板。
- `project-architecture-consultant/references/knowledge-extraction-template.md`：知识技能提炼模板。
- `project-architecture-consultant/agents/openai.yaml`：顾问接口定义。

## 迁移使用

1. 复制 `project-architecture-consultant/` 到目标项目的 Skill 目录。
2. 按目标项目替换 `SKILL.md` 中的项目入口、层次、测试命令和硬约束。
3. 迁移前后注意与源版本（`.role/architect/references/` 与 `docs/architecture/project-architecture.md`）保持同步。
