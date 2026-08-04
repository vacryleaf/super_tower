# 项目顾问 Ghost

状态：已实现。

本目录保存 Super Tower 的项目架构顾问 Ghost 的行为契约、项目知识地图和可迁移模板。它服务于需求分析和架构理解，不直接替代开发者修改游戏代码。

## 适用请求

- 新功能还比较模糊，需要先细化成需求和开发任务。
- 想快速了解某个功能的入口、调用链、数据来源和当前状态。
- 想从架构角度拆分模块、识别依赖和扩展边界。
- 想把项目中稳定的做法沉淀成其他项目可复用的 Skill 或工程知识。

## 当前资产

- `project-architecture-consultant/SKILL.md`：Ghost 的角色、工作流和输出契约。
- `project-architecture-consultant/references/project-architecture.md`：Super Tower 当前架构地图。
- `project-architecture-consultant/references/requirements-template.md`：需求文档模板。
- `project-architecture-consultant/references/knowledge-extraction-template.md`：知识技能提炼模板。
- `reusable/project-architecture-consultant/`：不绑定本项目文件名和数值的通用 Skill，可安装到其他项目或全局 Skill 目录。
- `requirements/README.md`：需求文档保存约定。

## 使用方式

项目根目录的 `AGENTS.md` 已注册本 Ghost 的工作方式。直接提出以下请求即可触发对应模式：

```text
帮我把“战斗中加入可叠加中毒”细化成需求文档，先不要写代码。

快速解释敌人的行为选择从哪里开始，状态和技能如何参与。

把当前战斗系统抽象成可复用模块，并指出哪些内容值得沉淀成 Skill。
```

涉及新功能时，默认先产出需求草案；明确要求保存后，文件放在 `docs/assistant/requirements/`。涉及当前项目事实时，先查 `docs/system.index.md` 和相关代码，不以本目录的静态地图替代实时验证。

## 可迁移性

这个目录可以作为其他项目的顾问 Skill 起点。迁移时保留 `SKILL.md` 和两个模板，再替换 `project-architecture.md` 中的项目入口、层次、测试命令和硬约束。
