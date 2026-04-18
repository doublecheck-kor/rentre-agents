#!/bin/bash
# ============================================
# Rentre Agents 업데이트 체크 (SessionStart hook용)
# ============================================
# Claude Code 세션 시작 시 자동 실행.
# rentre-agents submodule이 있으면 원격 최신 버전과 비교.
# 업데이트가 있으면 안내 메시지 출력.
#
# 사용법: settings.json SessionStart hook에 등록
# 타임아웃: 5초 (네트워크 실패 시 무음)

set -euo pipefail

# rentre-agents 위치 탐지 (프로젝트 서브모듈 → 글로벌)
RENTRE_DIR=""
if [ -d "rentre-agents/.git" ] || [ -f "rentre-agents/.git" ]; then
    RENTRE_DIR="rentre-agents"
elif [ -d "$HOME/.rentre-agents/.git" ]; then
    RENTRE_DIR="$HOME/.rentre-agents"
fi

# rentre-agents 없으면 무음 종료
[ -z "$RENTRE_DIR" ] && exit 0

# 현재 버전
LOCAL_VERSION=$(cat "$RENTRE_DIR/VERSION" 2>/dev/null | tr -d '[:space:]')
[ -z "$LOCAL_VERSION" ] && exit 0

# 원격 최신 VERSION 파일 (5초 타임아웃, 실패 시 무음)
REMOTE_VERSION=$(timeout 5 git -C "$RENTRE_DIR" fetch origin main --quiet 2>/dev/null \
    && git -C "$RENTRE_DIR" show origin/main:VERSION 2>/dev/null | tr -d '[:space:]') || exit 0

[ -z "$REMOTE_VERSION" ] && exit 0

# 버전 비교
if [ "$LOCAL_VERSION" != "$REMOTE_VERSION" ]; then
    echo ""
    echo "📦 Rentre Agents 업데이트 available: v${LOCAL_VERSION} → v${REMOTE_VERSION}"
    echo "   업데이트: /rentre:setup 업데이트해줘"
    echo ""
fi
