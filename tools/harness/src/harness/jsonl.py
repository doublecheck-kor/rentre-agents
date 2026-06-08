"""Append-only local mirror at ~/.harness/state.jsonl."""

from __future__ import annotations

import fcntl
import json
from pathlib import Path
from typing import Any


def append(path: Path, record: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    line = json.dumps(record, ensure_ascii=False, default=str)
    with path.open("a", encoding="utf-8") as fh:
        fcntl.flock(fh.fileno(), fcntl.LOCK_EX)
        try:
            fh.write(line + "\n")
        finally:
            fcntl.flock(fh.fileno(), fcntl.LOCK_UN)
