#!/usr/bin/env python3
"""Visual browser for the project's external catalog SQLite database."""

from __future__ import annotations

import json
import sqlite3
import tkinter as tk
from pathlib import Path
from tkinter import messagebox, ttk
from typing import Any, Iterable


PROJECT_ROOT = Path(__file__).resolve().parents[1]
SOURCE_PATH = PROJECT_ROOT / "GameProject" / "data" / "catalog_v1.json"
DATABASE_PATH = PROJECT_ROOT / "GameProject" / "data" / "catalog_v1.sqlite"

SCHEMA = """
PRAGMA foreign_keys = ON;
CREATE TABLE IF NOT EXISTS catalog_metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS catalog_tables (
    table_name TEXT PRIMARY KEY,
    entry_count INTEGER NOT NULL,
    source_path TEXT NOT NULL
);
CREATE TABLE IF NOT EXISTS catalog_entries (
    table_name TEXT NOT NULL,
    entry_id TEXT NOT NULL,
    value_type TEXT NOT NULL,
    value_json TEXT NOT NULL,
    PRIMARY KEY (table_name, entry_id),
    FOREIGN KEY (table_name) REFERENCES catalog_tables(table_name) ON DELETE CASCADE
);
CREATE TABLE IF NOT EXISTS catalog_fields (
    table_name TEXT NOT NULL,
    entry_id TEXT NOT NULL,
    field_name TEXT NOT NULL,
    value_type TEXT NOT NULL,
    value_json TEXT NOT NULL,
    PRIMARY KEY (table_name, entry_id, field_name),
    FOREIGN KEY (table_name, entry_id)
        REFERENCES catalog_entries(table_name, entry_id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_catalog_fields_name ON catalog_fields(field_name);
CREATE INDEX IF NOT EXISTS idx_catalog_fields_value ON catalog_fields(value_json);
"""


def json_type(value: Any) -> str:
    if isinstance(value, bool):
        return "boolean"
    if isinstance(value, (int, float)):
        return "number"
    if isinstance(value, str):
        return "string"
    if isinstance(value, list):
        return "array"
    if isinstance(value, dict):
        return "object"
    if value is None:
        return "null"
    return type(value).__name__


def encode(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def load_catalog() -> dict[str, Any]:
    try:
        catalog = json.loads(SOURCE_PATH.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError) as error:
        raise RuntimeError(f"无法读取数据源：{SOURCE_PATH}\n{error}") from error
    if not isinstance(catalog, dict) or not isinstance(catalog.get("tables"), dict):
        raise RuntimeError("数据源格式错误：缺少 tables 对象")
    return catalog


def iter_entries(table: Any) -> Iterable[tuple[str, Any]]:
    if isinstance(table, dict):
        return ((str(entry_id), value) for entry_id, value in table.items())
    return (("__root__", table),)


def rebuild_database() -> None:
    catalog = load_catalog()
    with sqlite3.connect(DATABASE_PATH) as connection:
        connection.executescript(SCHEMA)
        connection.execute("DELETE FROM catalog_fields")
        connection.execute("DELETE FROM catalog_entries")
        connection.execute("DELETE FROM catalog_tables")
        connection.execute("DELETE FROM catalog_metadata")
        connection.executemany(
            "INSERT INTO catalog_metadata(key, value) VALUES (?, ?)",
            [
                ("catalog_version", str(catalog.get("version", 0))),
                ("source_file", SOURCE_PATH.name),
                ("source_format", "catalog_v1"),
            ],
        )
        for table_name, table in catalog["tables"].items():
            entries = list(iter_entries(table))
            table_name_text = str(table_name)
            connection.execute(
                "INSERT INTO catalog_tables(table_name, entry_count, source_path) VALUES (?, ?, ?)",
                (table_name_text, len(entries), SOURCE_PATH.as_posix()),
            )
            for entry_id, value in entries:
                connection.execute(
                    "INSERT INTO catalog_entries(table_name, entry_id, value_type, value_json) VALUES (?, ?, ?, ?)",
                    (table_name_text, entry_id, json_type(value), encode(value)),
                )
                if isinstance(value, dict):
                    connection.executemany(
                        "INSERT INTO catalog_fields(table_name, entry_id, field_name, value_type, value_json) VALUES (?, ?, ?, ?, ?)",
                        [
                            (table_name_text, entry_id, str(field_name), json_type(field_value), encode(field_value))
                            for field_name, field_value in value.items()
                        ],
                    )
        connection.commit()


def database_is_stale() -> bool:
    return not DATABASE_PATH.exists() or SOURCE_PATH.stat().st_mtime > DATABASE_PATH.stat().st_mtime


class CatalogBrowser:
    def __init__(self, root: tk.Tk) -> None:
        self.root = root
        self.connection: sqlite3.Connection | None = None
        self.table_tree: ttk.Treeview
        self.data_tree: ttk.Treeview
        self.status = tk.StringVar(value="正在加载数据…")
        self._build_window()
        self._load_database()

    def _build_window(self) -> None:
        self.root.title("Super Tower 数据浏览器")
        self.root.geometry("1180x700")
        self.root.minsize(800, 480)

        toolbar = ttk.Frame(self.root, padding=(8, 8, 8, 4))
        toolbar.pack(fill=tk.X)
        ttk.Label(toolbar, text="SQLite 数据浏览器", font=("TkDefaultFont", 12, "bold")).pack(side=tk.LEFT)
        ttk.Button(toolbar, text="重新载入", command=self._reload).pack(side=tk.RIGHT)

        separator = ttk.Separator(self.root, orient=tk.HORIZONTAL)
        separator.pack(fill=tk.X)

        pane = ttk.PanedWindow(self.root, orient=tk.HORIZONTAL)
        pane.pack(fill=tk.BOTH, expand=True, padx=8, pady=8)

        left = ttk.Frame(pane, width=230)
        right = ttk.Frame(pane)
        pane.add(left, weight=0)
        pane.add(right, weight=1)

        ttk.Label(left, text="Tables", padding=(4, 4)).pack(anchor=tk.W)
        table_frame = ttk.Frame(left)
        table_frame.pack(fill=tk.BOTH, expand=True)
        self.table_tree = ttk.Treeview(table_frame, show="tree", selectmode="browse")
        table_scroll = ttk.Scrollbar(table_frame, orient=tk.VERTICAL, command=self.table_tree.yview)
        self.table_tree.configure(yscrollcommand=table_scroll.set)
        self.table_tree.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)
        table_scroll.pack(side=tk.RIGHT, fill=tk.Y)
        self.table_tree.bind("<<TreeviewSelect>>", self._on_table_selected)

        ttk.Label(right, text="Records", padding=(4, 4)).pack(anchor=tk.W)
        data_frame = ttk.Frame(right)
        data_frame.pack(fill=tk.BOTH, expand=True)
        self.data_tree = ttk.Treeview(data_frame, show="headings")
        vertical_scroll = ttk.Scrollbar(data_frame, orient=tk.VERTICAL, command=self.data_tree.yview)
        horizontal_scroll = ttk.Scrollbar(data_frame, orient=tk.HORIZONTAL, command=self.data_tree.xview)
        self.data_tree.configure(yscrollcommand=vertical_scroll.set, xscrollcommand=horizontal_scroll.set)
        self.data_tree.grid(row=0, column=0, sticky="nsew")
        vertical_scroll.grid(row=0, column=1, sticky="ns")
        horizontal_scroll.grid(row=1, column=0, sticky="ew")
        data_frame.rowconfigure(0, weight=1)
        data_frame.columnconfigure(0, weight=1)

        ttk.Label(self.root, textvariable=self.status, anchor=tk.W, padding=(8, 4)).pack(fill=tk.X)

    def _load_database(self) -> None:
        try:
            if database_is_stale():
                rebuild_database()
            if self.connection is not None:
                self.connection.close()
            self.connection = sqlite3.connect(DATABASE_PATH)
            self._populate_tables()
            self.status.set(f"数据源：{SOURCE_PATH.name}    数据库：{DATABASE_PATH.name}")
        except (OSError, RuntimeError, sqlite3.Error) as error:
            messagebox.showerror("加载失败", str(error), parent=self.root)
            self.status.set("加载失败")

    def _populate_tables(self) -> None:
        self.table_tree.delete(*self.table_tree.get_children())
        assert self.connection is not None
        rows = self.connection.execute(
            "SELECT table_name, entry_count FROM catalog_tables ORDER BY table_name"
        ).fetchall()
        for table_name, entry_count in rows:
            self.table_tree.insert("", tk.END, iid=table_name, text=f"{table_name}  ({entry_count})")
        if rows:
            self.table_tree.selection_set(rows[0][0])
            self.table_tree.focus(rows[0][0])

    def _on_table_selected(self, _event: tk.Event) -> None:
        selection = self.table_tree.selection()
        if selection:
            self._show_table(selection[0])

    def _show_table(self, table_name: str) -> None:
        assert self.connection is not None
        rows = self.connection.execute(
            "SELECT entry_id, value_json FROM catalog_entries WHERE table_name = ? ORDER BY entry_id",
            (table_name,),
        ).fetchall()
        records = [(entry_id, json.loads(value_json)) for entry_id, value_json in rows]
        field_names = sorted({field for _, value in records if isinstance(value, dict) for field in value})
        columns = ["entry_id", *field_names]
        self.data_tree.delete(*self.data_tree.get_children())
        self.data_tree.configure(columns=columns)
        for column in columns:
            self.data_tree.heading(column, text="ID" if column == "entry_id" else column)
            self.data_tree.column(column, width=150 if column == "entry_id" else 180, anchor=tk.W, stretch=True)
        for entry_id, value in records:
            values = [entry_id]
            for field_name in field_names:
                field_value = value.get(field_name, "") if isinstance(value, dict) else ""
                values.append(self._display_value(field_value))
            self.data_tree.insert("", tk.END, values=values)
        self.status.set(f"当前表：{table_name}    共 {len(records)} 条记录")

    @staticmethod
    def _display_value(value: Any) -> str:
        if isinstance(value, (dict, list)):
            return json.dumps(value, ensure_ascii=False, separators=(",", ":"))
        if value is None:
            return ""
        return str(value)

    def _reload(self) -> None:
        self._load_database()


def main() -> None:
    root = tk.Tk()
    CatalogBrowser(root)
    root.mainloop()


if __name__ == "__main__":
    main()
