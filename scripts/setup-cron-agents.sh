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
MARKER_DISCOVERY="# rentre-cron-discovery"
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

# 발굴 프롬프트 렌더 (production: DRY_RUN=false) — rendered 파일은 gitignore라 배포 시 생성 필요
if [ -f "$SCRIPT_DIR/render-discovery.sh" ]; then
    bash "$SCRIPT_DIR/render-discovery.sh" false || echo "경고: 발굴 프롬프트 렌더 실패"
fi

# 기존 rentre-cron 항목 제거
EXISTING=$(crontab -l 2>/dev/null | grep -v "$ALL_MARKERS")

# 새 크론 등록
NEW_CRONS="$EXISTING
47 8 * * 1-5 cd $AGENT_DIR && $CLAUDE_BIN -p \"\$(cat $PROMPTS_DIR/market-news.rendered.md)\" --allowedTools 'WebSearch,mcp__claude_ai_Slack__slack_send_message' >> $LOGS_DIR/market-news.log 2>&1 $MARKER_MARKET
3 9 * * 1-5 cd $AGENT_DIR && $CLAUDE_BIN -p \"\$(cat $PROMPTS_DIR/daily-briefing.rendered.md)\" --allowedTools 'WebSearch,mcp__claude_ai_Google_Calendar__*,mcp__claude_ai_Slack__slack_send_message' >> $LOGS_DIR/daily-briefing.log 2>&1 $MARKER_DAILY
7 8-20 * * 1-5 cd $AGENT_DIR && $CLAUDE_BIN -p \"\$(cat $PROMPTS_DIR/adr-monitor.rendered.md)\" --allowedTools 'mcp__claude_ai_Notion__*,mcp__claude_ai_Slack__slack_send_message' >> $LOGS_DIR/adr-monitor.log 2>&1 $MARKER_ADR
0 16 * * 5 cd $AGENT_DIR && harness-run workflow-discovery --no-alert --timeout 900 -- $CLAUDE_BIN -p \"\$(cat $PROMPTS_DIR/workflow-discovery.rendered.md)\" --allowedTools 'Task,Bash,mcp__claude_ai_Slack__*,mcp__claude_ai_Notion__*,mcp__claude_ai_Google_Calendar__*,Read,Write' >> $LOGS_DIR/workflow-discovery.log 2>&1 $MARKER_DISCOVERY"

echo "$NEW_CRONS" | crontab -

echo "크론 에이전트 등록 완료!"
echo ""
echo "등록된 크론:"
crontab -l | grep "$ALL_MARKERS"
echo ""
echo "  마켓/뉴스 브리핑: 평일 08:47"
echo "  데일리 브리핑:    평일 09:03"
echo "  ADR 모니터링:     평일 08-20시 매시 :07"
# shadow phase 검증(2-4주) 후 --no-alert 제거하면 실패 시 Slack 알림 활성화
echo "  워크플로우 발굴:   매주 금요일 16:00 (shadow)"
echo ""
echo "  로그: $LOGS_DIR/"
echo "  제거: $0 --remove"
