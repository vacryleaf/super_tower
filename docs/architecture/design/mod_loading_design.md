# Mod 加载器设计

状态：设计已确认待实现；当前代码尚未实现完整 Mod Loader。

## Mod 包结构

```text
my_mod/
├── mod.json
├── skills/*.json
├── weapons/*.json
├── monsters/*.json
├── items/*.json
└── locales/zh_CN.json
```

## 设计原则

- 原版与 Mod 最终都转换成相同的领域 Schema。
- 内容 ID 必须是 `作者或包名.领域.实体`，例如 `example.mod.weapon.custom_sword`。
- 禁止覆盖原版 ID；冲突、缺失引用、循环依赖和版本不兼容都导致该内容包拒绝注册。
- 加载顺序固定：读取 manifest → 校验 manifest → 解析依赖 → 读取领域文件 → Schema 校验 → 引用解析 → 注册 → 生成图鉴索引。
- Mod 不允许执行任意脚本；第一阶段只允许声明式数据和已注册 action/trigger。
- 错误必须可定位到包 ID、相对文件、字段路径；失败包不得部分进入运行时。

## 当前实施范围

第一阶段仅预留接口、Schema 和文档；实际扫描目录、依赖解析、启用/禁用 UI 与运行时注册列入开发清单。
