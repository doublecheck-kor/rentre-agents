#!/bin/bash
# ============================================
# 시스템 crontab에 6일 갱신 스케줄 등록
# ============================================
# 실행: ./setup-crontab.sh
# 확인: crontab -l
# 제거: ./setup-crontab.sh --remove

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RENEW_SCRIPT="$SCRIPT_DIR/renew-agent.sh"
CRON_MARKER="# rentre-agent-renew"

if [ "$1" = "--remove" ]; then
    crontab -l 2>/dev/null | grep -v "$CRON_MARKER" | crontab -
    echo "crontab에서 rentre-agent 갱신 스케줄 제거 완료"
    exit 0
fi

# 기존 등록 여부 확인
if crontab -l 2>/dev/null | grep -q "$CRON_MARKER"; then
    echo "이미 등록되어 있습니다. 업데이트합니다."
    crontab -l 2>/dev/null | grep -v "$CRON_MARKER" | crontab -
fi

# 6일마다 오전 8:45에 갱신 (월요일 기준으로 일요일에 갱신)
# */6 day-of-month는 정확히 6일은 아니지만, 매주 일요일로 설정
(crontab -l 2>/dev/null; echo "45 8 * * 0 $RENEW_SCRIPT $CRON_MARKER") | crontab -

echo "crontab 등록 완료!"
echo ""
echo "등록된 스케줄:"
crontab -l | grep "$CRON_MARKER"
echo ""
echo "  매주 일요일 08:45에 에이전트 세션 자동 갱신"
echo "  제거: $0 --remove"
echo "  확인: crontab -l"
