"""Config loading. Supports TOML at ~/.harness/config.toml + env overrides."""

from __future__ import annotations

import os
import sys
import tomllib
from dataclasses import dataclass, field
from pathlib import Path


DEFAULT_CONFIG_PATH = Path.home() / ".harness" / "config.toml"
DEFAULT_STATE_DIR = Path.home() / ".harness"


@dataclass
class BackendConfig:
    type: str = "notion"
    token: str | None = None
    data_source_id: str | None = None


@dataclass
class AlerterConfig:
    type: str = "slack"
    bot_token: str | None = None
    webhook_url: str | None = None
    dm_channel: str | None = None
    broadcast_channel: str | None = None
    debounce_window_secs: int = 300
    hourly_rate_limit: int = 10


@dataclass
class IdentityConfig:
    user: str = "unknown"


@dataclass
class Config:
    backend: BackendConfig = field(default_factory=BackendConfig)
    alerter: AlerterConfig = field(default_factory=AlerterConfig)
    identity: IdentityConfig = field(default_factory=IdentityConfig)
    state_dir: Path = DEFAULT_STATE_DIR
    disabled_file: Path = DEFAULT_STATE_DIR / "disabled"


def load(path: Path | None = None) -> Config:
    path = path or Path(os.environ.get("HARNESS_CONFIG_PATH", DEFAULT_CONFIG_PATH))
    cfg = Config()
    if path.exists():
        with path.open("rb") as fh:
            raw = tomllib.load(fh)
        b = raw.get("backend", {})
        cfg.backend = BackendConfig(
            type=b.get("type", "notion"),
            token=b.get("token") or os.environ.get("NOTION_TOKEN"),
            data_source_id=b.get("data_source_id"),
        )
        a = raw.get("alerter", {}).get("slack", {})
        cfg.alerter = AlerterConfig(
            type="slack",
            bot_token=a.get("bot_token") or os.environ.get("SLACK_BOT_TOKEN"),
            webhook_url=a.get("webhook_url") or os.environ.get("SLACK_WEBHOOK_URL"),
            dm_channel=a.get("dm_channel"),
            broadcast_channel=a.get("broadcast_channel"),
            debounce_window_secs=a.get("debounce_window_secs", 300),
            hourly_rate_limit=a.get("hourly_rate_limit", 10),
        )
        i = raw.get("identity", {})
        cfg.identity = IdentityConfig(user=i.get("user", "unknown"))
    else:
        # Allow env-only operation for smoke tests
        cfg.backend.token = os.environ.get("NOTION_TOKEN")
        cfg.alerter.bot_token = os.environ.get("SLACK_BOT_TOKEN")
        cfg.alerter.webhook_url = os.environ.get("SLACK_WEBHOOK_URL")

    cfg.state_dir.mkdir(parents=True, exist_ok=True)
    return cfg


def is_disabled(cfg: Config) -> bool:
    """Check kill switch."""
    return cfg.disabled_file.exists()
