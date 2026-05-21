"""Backend protocol — pluggable storage layer."""

from __future__ import annotations

from typing import Protocol

from ..models import Report, RunMeta, RunResult


class Backend(Protocol):
    def open(self, meta: RunMeta) -> str | None:
        """Create a baseline row. Returns external row id (or None on failure)."""

    def close(self, row_id: str | None, meta: RunMeta, result: RunResult) -> None:
        """Update row with end state."""

    def patch_report(self, row_id: str | None, report: Report) -> None:
        """Apply a self-report patch to the row."""

    def poll_report(self, row_id: str | None) -> Report | None:
        """Return latest self-report on the row, if any."""

    def row_url(self, row_id: str | None) -> str:
        """URL for the row (for alert messages)."""
