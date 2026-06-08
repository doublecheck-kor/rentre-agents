"""Per-task debounce + hourly global rate limit. State at ~/.harness/alerts.json."""

from __future__ import annotations

import fcntl
import json
import time
from contextlib import contextmanager
from dataclasses import dataclass
from pathlib import Path
from typing import Iterator


@dataclass
class DebounceDecision:
    action: str  # "new" | "update" | "skip"
    message_refs: dict[str, str] | None
    repeat_count: int


class DebounceStore:
    def __init__(self, path: Path, window_secs: int, hourly_limit: int):
        self.path = path
        self.window_secs = window_secs
        self.hourly_limit = hourly_limit

    @contextmanager
    def _locked(self) -> Iterator[dict]:
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.path.touch(exist_ok=True)
        with self.path.open("r+", encoding="utf-8") as fh:
            fcntl.flock(fh.fileno(), fcntl.LOCK_EX)
            try:
                raw = fh.read().strip()
                state = json.loads(raw) if raw else {}
            except json.JSONDecodeError:
                state = {}
            try:
                yield state
            finally:
                fh.seek(0)
                fh.truncate()
                fh.write(json.dumps(state, ensure_ascii=False))
                fcntl.flock(fh.fileno(), fcntl.LOCK_UN)

    def decide(self, task: str, status: str) -> DebounceDecision:
        now = time.time()
        key = f"{task}:{status}"
        with self._locked() as state:
            entries = state.setdefault("entries", {})
            global_log: list[float] = state.setdefault("global", [])
            global_log[:] = [t for t in global_log if now - t < 3600]
            if len(global_log) >= self.hourly_limit:
                return DebounceDecision(action="skip", message_refs=None, repeat_count=0)

            current = entries.get(key)
            if current and now - current.get("first_ts", 0) < self.window_secs:
                current["count"] = current.get("count", 1) + 1
                entries[key] = current
                global_log.append(now)
                return DebounceDecision(
                    action="update",
                    message_refs=current.get("message_refs"),
                    repeat_count=current["count"],
                )

            # New
            entries[key] = {"first_ts": now, "count": 1, "message_refs": None}
            global_log.append(now)
            return DebounceDecision(action="new", message_refs=None, repeat_count=1)

    def record_refs(self, task: str, status: str, refs: dict[str, str]) -> None:
        key = f"{task}:{status}"
        with self._locked() as state:
            entries = state.setdefault("entries", {})
            if key in entries:
                entries[key]["message_refs"] = refs

    def cleanup(self, retention_secs: int) -> None:
        """Drop entries older than retention_secs. Run periodically."""
        now = time.time()
        with self._locked() as state:
            entries = state.get("entries", {})
            state["entries"] = {
                k: v for k, v in entries.items() if now - v.get("first_ts", 0) < retention_secs
            }
