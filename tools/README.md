# SQLite 可视化数据浏览器

可以直接双击启动：

- Windows：双击 `tools/catalog_browser.bat`
- macOS：双击 `tools/catalog_browser.command`

如果 macOS 第一次运行被系统拦截，请在 Finder 中右键该文件并选择“打开”，确认后即可运行。启动入口会自动定位仓库根目录，再打开同目录下的 `catalog_browser.py`。

也可以手动启动：

```text
python tools/catalog_browser.py
```

窗口布局：

- 左侧显示所有 SQLite table，括号内是记录数。
- 右侧以表格显示当前选中 table 的记录。
- 数组和嵌套对象会以紧凑 JSON 显示。
- 数据源 JSON 更新后，启动或点击“重新载入”会自动重建 SQLite 数据库。

数据库文件为 `GameProject/data/catalog_v1.sqlite`，数据源为 `GameProject/data/catalog_v1.json`。工具只提供可视化浏览界面，不提供命令行查询命令。
