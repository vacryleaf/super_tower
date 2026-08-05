# 架构领域

状态：已实现基础 Mod/Schema/迁移能力 + 扩展待实现。

本领域定义所有内容如何从静态数据进入运行时，以及未来如何以 Mod 形式插拔。

## 二级目录

- `design/`：数据驱动原则、扩展边界、Mod 包设计。
- `logic/`：运行时数据管线、内容校验、Mod 载入流程。
- `data/`：Schema 注册表、字段规则、Mod manifest。

## 当前代码映射

`DataCatalog` 是原版数据查询门面；`DataRepository` 读取 `catalog_v1.json`；战斗层只消费规范化字典，不应直接依赖 Mod 文件路径。
