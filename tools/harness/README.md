# harness

Lightweight observability wrapper for cron/CLI automations. Captures exit code,
duration, stdout tail, and self-reported domain context to a pluggable backend
(default: Notion) and notifies a pluggable alerter (default: Slack) on failure.

Design doc: [`docs/superpowers/specs/2026-05-21-harness-observability-design.md`](../../docs/superpowers/specs/2026-05-21-harness-observability-design.md)

## Install

```bash
pipx install ./tools/harness   # from rentre-agents root
# or for development:
pipx install --editable ./tools/harness
```

This puts `harness-run` and `harness-heartbeat` on your PATH.

## Quick start

```bash
mkdir -p ~/.harness
cp tools/harness/config.toml.example ~/.harness/config.toml
$EDITOR ~/.harness/config.toml   # fill in tokens + channel IDs

# Smoke test
harness-run smoke-test -- echo "hello"
harness-run smoke-fail -- bash -c 'exit 1'   # → Slack DM alert
```

## Usage

### Wrap a cron job

```bash
# Before:
47 8 * * 1-5 /path/to/morning-brief.sh

# After (shadow phase — no alerts yet):
47 8 * * 1-5 harness-run morning-brief --timeout 600 --no-alert -- /path/to/morning-brief.sh

# After (active phase):
47 8 * * 1-5 harness-run morning-brief --timeout 600 -- /path/to/morning-brief.sh
```

### Add self-report inside automation

```bash
# end of morning-brief.sh
command -v harness-heartbeat >/dev/null 2>&1 && \
  harness-heartbeat report --status ok \
    --summary "마켓/뉴스 브리핑 발송 완료" \
    --detail slack_messages_sent=2 || true
```

### Kill switch

```bash
touch ~/.harness/disabled    # all harness-run become transparent passthrough
rm ~/.harness/disabled       # re-enable
```

## State

- `~/.harness/state.jsonl` — append-only log of all runs (open/close/report)
- `~/.harness/alerts.json` — debounce state
- `~/.harness/logs/{task}/{ts}-{run_id}.log` — per-run stdout/stderr capture
- `~/.harness/disabled` — kill switch (file existence check)

## Tests

```bash
pip install pytest
pytest tools/harness/tests
```
