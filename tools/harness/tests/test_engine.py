"""Engine smoke tests — no real Notion/Slack calls."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

from harness import config as cfgmod
from harness import engine
from harness.debounce import DebounceStore


def _make_cfg(tmp_state: Path):
    cfg = cfgmod.Config()
    cfg.state_dir = tmp_state
    cfg.disabled_file = tmp_state / "disabled"
    return cfg


def test_happy_path(tmp_state):
    cfg = _make_cfg(tmp_state)
    rc = engine.run(
        task="smoke-ok",
        command=["true"],
        cfg=cfg,
        timeout_s=10,
        grace_secs=0,  # skip grace polling for fast tests
        no_notion=True,
        no_alert=True,
    )
    assert rc == 0
    state = (tmp_state / "state.jsonl").read_text().splitlines()
    assert len(state) == 2
    open_rec = json.loads(state[0])
    close_rec = json.loads(state[1])
    assert open_rec["type"] == "open"
    assert close_rec["type"] == "close"
    assert close_rec["status"] == "missing-report" or close_rec["status"] == "ok"
    # grace_secs=0 means status stays ok (no polling) — engine treats ok directly
    # depending on engine logic; check exit_code at minimum
    assert close_rec["exit_code"] == 0


def test_non_zero_exit(tmp_state):
    cfg = _make_cfg(tmp_state)
    rc = engine.run(
        task="smoke-fail",
        command=["bash", "-c", "exit 7"],
        cfg=cfg,
        timeout_s=10,
        grace_secs=0,
        no_notion=True,
        no_alert=True,
    )
    assert rc == 7
    state = [json.loads(l) for l in (tmp_state / "state.jsonl").read_text().splitlines()]
    close = next(r for r in state if r["type"] == "close")
    assert close["status"] == "fail"
    assert close["exit_code"] == 7


def test_timeout(tmp_state):
    cfg = _make_cfg(tmp_state)
    rc = engine.run(
        task="smoke-timeout",
        command=["sleep", "5"],
        cfg=cfg,
        timeout_s=1,
        grace_secs=0,
        no_notion=True,
        no_alert=True,
    )
    assert rc == 124
    state = [json.loads(l) for l in (tmp_state / "state.jsonl").read_text().splitlines()]
    close = next(r for r in state if r["type"] == "close")
    assert close["status"] == "timeout"


def test_debounce_new_then_update(tmp_path):
    db = DebounceStore(tmp_path / "alerts.json", window_secs=300, hourly_limit=10)
    d1 = db.decide("task-a", "fail")
    assert d1.action == "new"
    assert d1.repeat_count == 1
    d2 = db.decide("task-a", "fail")
    assert d2.action == "update"
    assert d2.repeat_count == 2


def test_debounce_global_limit(tmp_path):
    db = DebounceStore(tmp_path / "alerts.json", window_secs=300, hourly_limit=2)
    assert db.decide("a", "fail").action == "new"
    assert db.decide("b", "fail").action == "new"
    assert db.decide("c", "fail").action == "skip"


def test_kill_switch(tmp_state, monkeypatch):
    cfg = _make_cfg(tmp_state)
    (tmp_state / "disabled").touch()
    assert cfgmod.is_disabled(cfg) is True
