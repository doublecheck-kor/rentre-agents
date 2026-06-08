#!/bin/bash
# workflow-discovery.md → workflow-discovery.rendered.md 렌더 (개발/검증용)
# config 값으로 placeholder 치환. DRY_RUN은 인자로 제어(기본 true).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
PROMPTS="$ROOT/cron-prompts"
CONFIG="${RENTRE_CONFIG:-$ROOT/config.json}"

DRY_RUN="${1:-true}"

get() {  # $1=json key → value or empty
  if [ -f "$CONFIG" ]; then
    python3 -c "import json,sys; print(json.load(open('$CONFIG')).get('$1',''))" 2>/dev/null || true
  fi
}
SLACK_DM="$(get slack_dm_channel)"
GITHUB_ORG="$(get github_org)"

# fallbacks
[ -z "$SLACK_DM" ] && SLACK_DM="D07S7RE6TK4"
[ -z "$GITHUB_ORG" ] && GITHUB_ORG="doublecheck-kor"

sed -e "s|{{SLACK_DM_CHANNEL}}|${SLACK_DM}|g" \
    -e "s|{{GITHUB_ORG}}|${GITHUB_ORG}|g" \
    -e "s|{{DRY_RUN}}|DRY_RUN=${DRY_RUN}|g" \
    "$PROMPTS/workflow-discovery.md" > "$PROMPTS/workflow-discovery.rendered.md"

echo "Rendered → $PROMPTS/workflow-discovery.rendered.md (DRY_RUN=${DRY_RUN}, org=${GITHUB_ORG})"
