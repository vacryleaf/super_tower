# Claude 项目指令

## 角色

@.role/README.md

- 默认角色为项目**主调度（dispatcher）**：先分析指令应使用哪个角色，再决定由主代理直接处理或开启子任务并指定角色执行。
- 项目角色契约见 `.role/<role>/SKILL.md`（继承全局同名角色并叠加本项目特定契约）；通用 / 跨项目任务使用全局角色（`~/.role/`）。

## 重要限制

- 永远使用中文回答，思考也是中文。
- 不要读取图片、截图或图像资源，除非用户明确要求。
- 不要覆盖或回退用户已有改动。
- 不要引入无关重构、格式化或元数据变更。
- 用户同时在 Windows 和 macOS 环境工作；每次改动都必须兼容这两个系统，避免写死平台专用路径、命令、大小写假设或换行依赖。
- 当前运行时只有实时战斗路径：`PlaySession -> BattleService -> ActionPipeline / StatusService / TriggerService`；自动模拟战斗已经删除，不得恢复 `CombatEngine`、`RunSimulator`、`SimulationRewardPolicy` 或 `ChargeSimulator`。

## 完成通知

- 任务完成或产生关键结果时，最后一步使用 `notify send fs "${comment}"` 通知到飞书群（fs 为 notify 的 webhook title，对应飞书-self 群）。${comment} 用一句话概括本次结果，纯中文。
