#!/usr/bin/env python3
import json
import os
import sqlite3
import sys
from pathlib import Path
from typing import Optional, Set


HOME = Path.home()
CLAUDE_ICON = os.environ.get("LLM_COUNT_CLAUDE_ICON", "✻")
CODEX_ICON = os.environ.get("LLM_COUNT_CODEX_ICON", "󰚩")


def git_root(cwd: str) -> Optional[str]:
    path = Path(cwd).resolve()
    for candidate in (path, *path.parents):
        if (candidate / ".git").exists():
            return str(candidate)
    return None


def claude_project_name(path: str) -> str:
    return path.replace("/", "-").replace(".", "-")


def count_claude(paths: Set[str]) -> int:
    projects_dir = HOME / ".claude" / "projects"
    count = 0

    for path in paths:
        project_dir = projects_dir / claude_project_name(path)
        if project_dir.is_dir():
            count += sum(1 for _ in project_dir.glob("*.jsonl"))

    return count


def count_codex(paths: Set[str]) -> int:
    db = HOME / ".codex" / "state_5.sqlite"
    if db.is_file():
        try:
            placeholders = ",".join("?" for _ in paths)
            with sqlite3.connect(f"file:{db}?mode=ro", uri=True, timeout=0.1) as conn:
                row = conn.execute(
                    f"select count(distinct id) from threads where cwd in ({placeholders})",
                    tuple(paths),
                ).fetchone()
            return int(row[0] or 0)
        except sqlite3.Error:
            pass

    return count_codex_session_files(paths)


def count_codex_session_files(paths: Set[str]) -> int:
    sessions_dir = HOME / ".codex" / "sessions"
    if not sessions_dir.is_dir():
        return 0

    count = 0
    for session_file in sessions_dir.rglob("*.jsonl"):
        try:
            with session_file.open("r", encoding="utf-8") as handle:
                first_line = handle.readline()
            meta = json.loads(first_line)
        except (OSError, json.JSONDecodeError):
            continue

        payload = meta.get("payload") or {}
        if payload.get("cwd") in paths:
            count += 1

    return count


def main() -> None:
    cwd = os.getcwd()
    paths = {cwd}
    root = git_root(cwd)
    if root:
        paths.add(root)

    claude_count = count_claude(paths)
    codex_count = count_codex(paths)
    parts = []
    if claude_count:
        parts.append(f"{CLAUDE_ICON} {claude_count}")
    if codex_count:
        parts.append(f"{CODEX_ICON} {codex_count}")

    if parts:
        print(" ".join(parts))
    else:
        sys.exit(1)


if __name__ == "__main__":
    main()
