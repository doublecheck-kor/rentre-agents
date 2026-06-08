#!/usr/bin/env bash
# Install harness (CLIs + config skeleton). Idempotent — safe to re-run.
#
# Usage: bash tools/harness/install-harness.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${HOME}/.harness"
CONFIG_FILE="${CONFIG_DIR}/config.toml"
BACKUP_DIR="${CONFIG_DIR}/backup"

say() { printf "\033[1;36m[harness-install]\033[0m %s\n" "$*"; }
warn() { printf "\033[1;33m[harness-install] %s\033[0m\n" "$*" >&2; }
die() { printf "\033[1;31m[harness-install] %s\033[0m\n" "$*" >&2; exit 1; }

# 1) Require pipx
if ! command -v pipx >/dev/null 2>&1; then
    die "pipx not found. Install with: python3 -m pip install --user pipx && python3 -m pipx ensurepath"
fi
say "pipx detected: $(pipx --version)"

# 2) Install or upgrade harness
say "Installing harness from ${SCRIPT_DIR}..."
pipx install --force "${SCRIPT_DIR}" >/dev/null
say "Installed: $(which harness-run) and $(which harness-heartbeat)"

# 3) State dir + config skeleton
mkdir -p "${CONFIG_DIR}" "${BACKUP_DIR}"
chmod 700 "${CONFIG_DIR}"

if [ ! -f "${CONFIG_FILE}" ]; then
    say "Creating ${CONFIG_FILE} from example..."
    cp "${SCRIPT_DIR}/config.toml.example" "${CONFIG_FILE}"
    chmod 600 "${CONFIG_FILE}"
    warn "Edit ${CONFIG_FILE} — set NOTION_TOKEN and Slack bot_token/webhook_url."
else
    say "Config already exists: ${CONFIG_FILE} (leaving as-is)"
fi

# 4) Crontab backup
BACKUP_FILE="${BACKUP_DIR}/crontab.$(date +%F).txt"
if crontab -l > "${BACKUP_FILE}" 2>/dev/null; then
    say "Crontab backed up to ${BACKUP_FILE}"
else
    warn "No crontab to back up (or crontab not installed)"
fi

# 5) Smoke test (wrapper-only, no external deps)
say "Running smoke test (no Notion, no alert)..."
if harness-run smoke-test --no-notion --no-alert --grace-secs 0 -- echo "harness install smoke ok" >/dev/null 2>&1; then
    say "Smoke test passed ✅"
else
    die "Smoke test failed — check harness-run output manually"
fi

cat <<EOF

✅ harness installed.

다음 할 일:
  1) Notion Heartbeat DB를 NOTION_TOKEN integration과 공유
     (Notion UI: 페이지 우상단 ··· → Connections → integration 추가)
     DB: https://www.notion.so/245fb77268724fd49af093403543883e
  2) ${CONFIG_FILE} 편집해서 SLACK_BOT_TOKEN 또는 SLACK_WEBHOOK_URL 입력
  3) tools/harness/MIGRATION.md 를 따라 crontab 변경

설정 후 통합 검증:
  source ~/.env && NOTION_TOKEN=\$NOTION_TOKEN harness-run smoke-test --no-alert -- echo hi

EOF
