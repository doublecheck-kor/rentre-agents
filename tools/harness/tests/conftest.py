"""Test fixtures — isolated state dir, stub backend/alerter."""

import os
import sys
from pathlib import Path

import pytest

# Make src importable without install
ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT / "src"))


@pytest.fixture
def tmp_state(tmp_path, monkeypatch):
    state = tmp_path / "harness"
    state.mkdir()
    monkeypatch.setenv("HARNESS_CONFIG_PATH", str(state / "config.toml"))
    # No real config file → load() falls back to defaults
    yield state
