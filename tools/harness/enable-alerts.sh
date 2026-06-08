#!/usr/bin/env bash
# Phase 2 stepup — remove --no-alert from the 3 harness-run cron lines.
# Run this AFTER 1주 shadow 관찰 to flip alerts ON.

set -euo pipefail

BACKUP="${HOME}/.harness/backup/crontab.before-alerts.$(date +%F-%H%M%S).txt"

mkdir -p "$(dirname "$BACKUP")"
crontab -l > "$BACKUP"
echo "[enable-alerts] backup → $BACKUP"

# Remove '--no-alert ' from harness-run lines for the 3 target tasks
TMP=$(mktemp)
crontab -l | sed -E '/harness-run (market-news|daily-briefing|adr-monitor|lead-meeting-summary) /s/ --no-alert / /g' > "$TMP"

echo "=== diff ==="
diff "$BACKUP" "$TMP" || true
echo

read -p "위 변경 적용? [y/N] " yn
if [ "$yn" = "y" ] || [ "$yn" = "Y" ]; then
    crontab "$TMP"
    echo "[enable-alerts] applied. 알림이 이제 켜졌습니다."
else
    echo "[enable-alerts] aborted. crontab 변경 안 됨."
fi
rm -f "$TMP"
