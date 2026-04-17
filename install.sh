#!/bin/bash
# rentre-agents/install.sh — 루트 래퍼
# 실제 스크립트: shared-commands/install.sh
#
# macOS 기본 bash는 3.2이므로, Homebrew bash가 있으면 자동 재실행

MAIN_SCRIPT="$(dirname "${BASH_SOURCE[0]}")/shared-commands/install.sh"

# Bash 4.3+ 필요 — macOS에서 Homebrew bash 자동 감지
if [ "${BASH_VERSINFO[0]}" -lt 4 ] || { [ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -lt 3 ]; }; then
    for candidate in /opt/homebrew/bin/bash /usr/local/bin/bash; do
        if [ -x "$candidate" ]; then
            exec "$candidate" "$MAIN_SCRIPT" "$@"
        fi
    done
    # Homebrew bash도 없으면 메인 스크립트가 에러 메시지를 출력
fi

exec bash "$MAIN_SCRIPT" "$@"
