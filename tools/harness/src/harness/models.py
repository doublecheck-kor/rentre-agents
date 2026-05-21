"""Data models passed between engine, backends, and alerters."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Literal

Status = Literal["running", "ok", "warn", "fail", "missing-report", "timeout"]


@dataclass
class RunMeta:
    run_id: str
    task: str
    started_at: datetime
    host: str
    user: str
    trigger: Literal["cron", "manual", "schedule", "event"]
    rentre_version: str | None = None


@dataclass
class RunResult:
    ended_at: datetime
    duration_s: int
    exit_code: int
    status: Status
    stdout_tail: list[str]
    log_file_url: str | None = None


@dataclass
class Report:
    status: Literal["ok", "warn", "fail"]
    summary: str
    detail: dict[str, Any] = field(default_factory=dict)


@dataclass
class AlertEvent:
    run_id: str
    task: str
    status: Literal["fail", "warn", "missing-report", "timeout"]
    started_at: datetime
    ended_at: datetime
    duration_s: int
    exit_code: int | None
    host: str
    summary: str | None
    detail: dict[str, Any] | None
    stdout_tail: list[str]
    backend_row_url: str
    repeat_count: int = 1
