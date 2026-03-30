#!/bin/bash
# ============================================
# 시스템 crontab에 claude -p 기반 크론 에이전트 등록
# ============================================
# 실행: ./setup-cron-agents.sh
# 제거: ./setup-cron-agents.sh --remove
# 확인: crontab -l

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_DIR="$(dirname "$SCRIPT_DIR")"
PROMPTS_DIR="$AGENT_DIR/cron-prompts"
LOGS_DIR="$AGENT_DIR/logs"

MARKER_MARKET="# rentre-cron-market"
MARKER_DAILY="# rentre-cron-daily"
MARKER_ADR="# rentre-cron-adr"
ALL_MARKERS="rentre-cron-"

# claude 풀패스 감지
CLAUDE_BIN=$(which claude 2>/dev/null || echo "/usr/local/bin/claude")
if [ ! -x "$CLAUDE_BIN" ]; then
    echo "Error: claude 실행 파일을 찾을 수 없습니다."
    exit 1
fi

mkdir -p "$LOGS_DIR"

if [ "$1" = "--remove" ]; then
    crontab -l 2>/dev/null | grep -v "$ALL_MARKERS" | crontab -
    echo "크론 에이전트 전체 제거 완료"
    crontab -l
    exit 0
fi

# 기존 rentre-cron 항목 제거
EXISTING=$(crontab -l 2>/dev/null | grep -v "$ALL_MARKERS")

# 새 크론 등록
NEW_CRONS="$EXISTING
47 8 * * 1-5 cd $AGENT_DIR && $CLAUDE_BIN -p \"\$(cat $PROMPTS_DIR/market-news.rendered.md)\" --allowedTools 'WebSearch,mcp__claude_ai_Slack__slack_send_message' >> $LOGS_DIR/market-news.log 2>&1 $MARKER_MARKET
3 9 * * 1-5 cd $AGENT_DIR && $CLAUDE_BIN -p \"\$(cat $PROMPTS_DIR/daily-briefing.rendered.md)\" --allowedTools 'WebSearch,mcp__claude_ai_Google_Calendar__*,mcp__claude_ai_Slack__slack_send_message' >> $LOGS_DIR/daily-briefing.log 2>&1 $MARKER_DAILY
7 8-20 * * 1-5 cd $AGENT_DIR && $CLAUDE_BIN -p \"\$(cat $PROMPTS_DIR/adr-monitor.rendered.md)\" --allowedTools 'mcp__claude_ai_Notion__*,mcp__claude_ai_Slack__slack_send_message' >> $LOGS_DIR/adr-monitor.log 2>&1 $MARKER_ADR"

echo "$NEW_CRONS" | crontab -

echo "크론 에이전트 등록 완료!"
echo ""
echo "등록된 크론:"
crontab -l | grep "$ALL_MARKERS"
echo ""
echo "  마켓/뉴스 브리핑: 평일 08:47"
echo "  데일리 브리핑:    평일 09:03"
echo "  ADR 모니터링:     평일 08-20시 매시 :07"
echo ""
echo "  로그: $LOGS_DIR/"
echo "  제거: $0 --remove"
