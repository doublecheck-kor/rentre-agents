#!/bin/bash
# ============================================
# Rentre Agent Commands - 원클릭 설치
# ============================================
# 팀원에게 이 한 줄만 공유하면 됩니다:
#
#   curl -sL https://raw.githubusercontent.com/rentre-kr/rentre-agents/main/shared-commands/quick-install.sh | bash
#
# 또는 사내 서버가 있다면:
#   curl -sL https://internal.rentre.kr/agents/install.sh | bash
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_URL="git@github.com:rentre-kr/rentre-agents.git"
INSTALL_DIR="$HOME/.rentre-agents"
TARGET_DIR="$HOME/.claude/commands/rentre"

echo ""
echo -e "${GREEN}=== Rentre Agent Commands 설치 ===${NC}"
echo ""

# Claude Code 확인
if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}[!] Claude Code가 없습니다. 먼저 설치하세요:${NC}"
    echo "    npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# 기존 설치 확인
if [ -d "$INSTALL_DIR" ]; then
    echo "기존 설치 발견. 업데이트합니다..."
    cd "$INSTALL_DIR" && git pull
else
    echo "다운로드 중..."
    git clone "$REPO_URL" "$INSTALL_DIR"
fi

# 디렉토리 생성
mkdir -p "$HOME/.claude/commands"

# 기존 링크/폴더 제거
[ -e "$TARGET_DIR" ] && rm -rf "$TARGET_DIR"

# 심볼릭 링크
ln -s "$INSTALL_DIR/shared-commands/rentre" "$TARGET_DIR"

echo ""
echo -e "${GREEN}[OK] 설치 완료!${NC}"
echo ""
echo "사용 가능한 커맨드:"
echo "  /rentre:assistant  - 만능 비서"
echo "  /rentre:schedule   - 일정 조회"
echo "  /rentre:market     - 마켓/뉴스"
echo "  /rentre:agile      - 애자일 프로세스 (10라운드 토론)"
echo "  /rentre:develop    - 풀사이클 개발 (TDD + E2E + PR)"
echo "  /rentre:adr        - ADR 분석"
echo "  /rentre:slack      - Slack 연동"
echo "  /rentre:notion     - Notion 검색"
echo "  /rentre:email      - 이메일 관리"
echo ""
echo "업데이트: cd ~/.rentre-agents && git pull"
echo "제거:     rm -rf ~/.rentre-agents ~/.claude/commands/rentre"
