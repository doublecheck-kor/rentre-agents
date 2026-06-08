"""Alerter protocol — pluggable notification layer."""

from __future__ import annotations

from typing import Protocol

from ..models import AlertEvent


class Alerter(Protocol):
    def notify(self, event: AlertEvent) -> dict[str, str] | None:
        """Send a new alert. Returns provider message IDs (per-channel) or None."""

    def update(self, message_refs: dict[str, str], event: AlertEvent) -> None:
        """Update existing alert (for debouncing)."""
