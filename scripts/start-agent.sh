#!/bin/bash
# ============================================
# Rentre Agent Daemon - tmux + Claude Code
# ============================================
# 사용법: ./start-agent.sh
# 중지:   tmux kill-session -t rentre-agent
# 상태:   tmux ls
# 접속:   tmux attach -t rentre-agent

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
AGENT_DIR="$(dirname "$SCRIPT_DIR")"
SESSION_NAME="rentre-agent"
PROMPT_FILE="$SCRIPT_DIR/init-prompt.txt"

# 기존 세션이 있으면 종료
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 기존 세션 종료 중..."
    tmux kill-session -t "$SESSION_NAME"
    sleep 2
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Rentre Agent 세션 시작..."

# tmux 세션 생성
tmux new-session -d -s "$SESSION_NAME" -x 200 -y 50

# Claude Code를 인터랙티브 모드로 실행
tmux send-keys -t "$SESSION_NAME" "cd $AGENT_DIR && claude" Enter

# Claude Code가 시작될 때까지 대기
sleep 5

# 초기 프롬프트 전송 (크론 설정 요청)
tmux send-keys -t "$SESSION_NAME" "$(cat "$PROMPT_FILE")" Enter

echo "[$(date '+%Y-%m-%d %H:%M:%S')] tmux 세션 '$SESSION_NAME' 시작됨"
echo ""
echo "  접속:  tmux attach -t $SESSION_NAME"
echo "  분리:  Ctrl+B, D"
echo "  종료:  tmux kill-session -t $SESSION_NAME"
echo "  상태:  tmux ls"
