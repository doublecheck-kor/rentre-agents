"""Slack alerter — uses bot token (Web API) or webhook URL."""

from __future__ import annotations

import sys
from typing import Any

import requests

from ..models import AlertEvent

SLACK_API = "https://slack.com/api"
TIMEOUT_S = 5


class SlackAlerter:
    """Sends formatted alerts to a DM and a broadcast channel.

    Prefers bot_token (allows chat.update for debounce). Falls back to webhook_url
    (post-only, no debounce update — sends a fresh message each time).
    """

    def __init__(
        self,
        bot_token: str | None,
        webhook_url: str | None,
        dm_channel: str | None,
        broadcast_channel: str | None,
    ):
        self.bot_token = bot_token
        self.webhook_url = webhook_url
        self.dm_channel = dm_channel
        self.broadcast_channel = broadcast_channel

    def _enabled(self) -> bool:
        return bool(self.bot_token or self.webhook_url)

    def notify(self, event: AlertEvent) -> dict[str, str] | None:
        if not self._enabled():
            print("[slack] disabled (no bot_token or webhook_url)", file=sys.stderr)
            return None

        text = _format(event)
        channels = self._channels_for(event.status)
        refs: dict[str, str] = {}
        for ch in channels:
            ts = self._send(ch, text)
            if ts:
                refs[ch] = ts
        return refs or None

    def update(self, message_refs: dict[str, str], event: AlertEvent) -> None:
        if not self.bot_token or not message_refs:
            # Webhook can't update, just send fresh
            self.notify(event)
            return

        text = _format(event)
        for channel, ts in message_refs.items():
            try:
                r = requests.post(
                    f"{SLACK_API}/chat.update",
                    headers={"Authorization": f"Bearer {self.bot_token}"},
                    json={"channel": channel, "ts": ts, "text": text},
                    timeout=TIMEOUT_S,
                )
                if not r.json().get("ok"):
                    print(f"[slack] chat.update failed: {r.text}", file=sys.stderr)
            except Exception as e:
                print(f"[slack] chat.update error: {e}", file=sys.stderr)

    def _channels_for(self, status: str) -> list[str]:
        channels = []
        if self.dm_channel:
            channels.append(self.dm_channel)
        # broadcast only for fail-class, not warn
        if status in {"fail", "timeout", "missing-report"} and self.broadcast_channel:
            channels.append(self.broadcast_channel)
        return channels

    def _send(self, channel: str, text: str) -> str | None:
        if self.bot_token:
            try:
                r = requests.post(
                    f"{SLACK_API}/chat.postMessage",
                    headers={"Authorization": f"Bearer {self.bot_token}"},
                    json={"channel": channel, "text": text},
                    timeout=TIMEOUT_S,
                )
                data = r.json()
                if not data.get("ok"):
                    print(f"[slack] postMessage failed: {data}", file=sys.stderr)
                    return None
                return data.get("ts")
            except Exception as e:
                print(f"[slack] postMessage error: {e}", file=sys.stderr)
                return None
        elif self.webhook_url:
            try:
                requests.post(
                    self.webhook_url,
                    json={"text": text, "channel": channel},
                    timeout=TIMEOUT_S,
                )
                return f"webhook-{channel}"
            except Exception as e:
                print(f"[slack] webhook error: {e}", file=sys.stderr)
                return None
        return None


_EMOJI = {
    "fail": "🔴",
    "timeout": "⏱️",
    "missing-report": "🟠",
    "warn": "🟡",
}


def _format(event: AlertEvent) -> str:
    emoji = _EMOJI.get(event.status, "⚠️")
    started_kst = event.started_at.strftime("%Y-%m-%d %H:%M:%S KST")
    summary = event.summary or "(self-report 없음)"
    stdout_block = "\n".join(event.stdout_tail[-5:]) if event.stdout_tail else "(no output)"
    url = event.backend_row_url or "(no link)"
    return (
        f"{emoji} *{event.task}* — {event.status}\n\n"
        f"• 시각: {started_kst} ({event.duration_s}s)\n"
        f"• Host: {event.host}\n"
        f"• Exit: {event.exit_code}\n\n"
        f"> {summary}\n\n"
        f"```\n{stdout_block}\n```\n\n"
        f"📊 <{url}|Notion row> · 🔁 {event.repeat_count}건째"
    )
