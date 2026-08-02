# 奖励数据

状态：已实现 + 扩展待实现。

奖励必须带 `kind`、来源、目标类型和效果参数；附着奖励与即时资源奖励分开。目标选择由 `CharacterService.preferred_attachment_target()` 等服务完成，UI 只提交玩家选择。
