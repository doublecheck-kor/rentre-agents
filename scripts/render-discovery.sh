#!/bin/bash
# workflow-discovery.md → workflow-discovery.rendered.md 렌더 (개발/검증용)
# config 값으로 placeholder 치환. DRY_RUN은 인자로 제어(기본 true).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
PROMPTS="$ROOT/cron-prompts"
CONFIG="${RENTRE_CONFIG:-$HOME/.claude/rentre-config.json}"

DRY_RUN="${1:-true}"

TEMPLATE="$PROMPTS/workflow-discovery.md"
[ -f "$TEMPLATE" ] || { echo "Error: 템플릿 없음 — $TEMPLATE" >&2; exit 1; }

get() {  # $1=json key → value or empty
  if [ -f "$CONFIG" ]; then
    python3 -c "import json,sys; print(json.load(open('$CONFIG')).get('$1',''))" 2>/dev/null || true
  fi
}
SLACK_DM="$(get slack_dm_channel)"
GITHUB_ORG="$(get github_org)"

# fallbacks
[ -z "$SLACK_DM" ] && SLACK_DM="D07S7RE6TK4"
# github_org는 아직 rentre-config.json에 없는 키라 fallback이 정상 동작(예상된 기본값)
[ -z "$GITHUB_ORG" ] && GITHUB_ORG="doublecheck-kor"

esc() { printf '%s' "$1" | sed -e 's/[&|\\]/\\&/g'; }
SLACK_DM="$(esc "$SLACK_DM")"
GITHUB_ORG="$(esc "$GITHUB_ORG")"

sed -e "s|{{SLACK_DM_CHANNEL}}|${SLACK_DM}|g" \
    -e "s|{{GITHUB_ORG}}|${GITHUB_ORG}|g" \
    -e "s|{{DRY_RUN}}|DRY_RUN=${DRY_RUN}|g" \
    "$TEMPLATE" > "$PROMPTS/workflow-discovery.rendered.md"

echo "Rendered → $PROMPTS/workflow-discovery.rendered.md (DRY_RUN=${DRY_RUN}, org=${GITHUB_ORG})"
