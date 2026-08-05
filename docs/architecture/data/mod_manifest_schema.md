# Mod Manifest Schema

状态：已实现基础校验 + 扩展待实现。

```json
{
  "schema_version": 1,
  "id": "example.mod",
  "version": "1.0.0",
  "api_version": 1,
  "name_key": "mod.example.name",
  "author": "Author",
  "dependencies": [],
  "content": {
    "skills": ["skills/skill_x.json"],
    "weapons": ["weapons/weapon_custom_sword.json"],
    "monsters": ["monsters/monster_custom_rat.json"],
    "items": ["items/item_custom_potion.json"]
  }
}
```

规则：`id` 全局唯一；路径必须是包内相对路径；只允许列出受支持的领域；版本使用可比较格式；缺失 `content`、非法路径或未知领域都拒绝加载。

当前 `ModLoader.validate_manifest()` 已实现上述字段、版本、API、依赖、领域和路径校验；完整领域 Schema、跨领域引用和本地化校验由后续任务负责。
