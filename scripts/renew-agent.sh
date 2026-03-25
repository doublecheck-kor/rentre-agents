#!/bin/bash
# ============================================
# Rentre Agent 자동 갱신 스크립트
# ============================================
# 6일마다 실행되어 크론 만료 전에 세션을 재시작합니다.
# 시스템 crontab에 등록하여 사용합니다.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="$SCRIPT_DIR/../logs/renew.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== 에이전트 갱신 시작 ==="

# 기존 세션 종료 + 새 세션 시작
bash "$SCRIPT_DIR/start-agent.sh" 2>&1 | tee -a "$LOG_FILE"

log "=== 에이전트 갱신 완료 ==="
