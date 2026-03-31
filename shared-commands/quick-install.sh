#!/bin/bash
# ============================================
# Rentre Agent Commands - 원클릭 설치
# ============================================
# 팀원에게 이 한 줄만 공유하면 됩니다:
#
#   curl -sL https://raw.githubusercontent.com/doublecheck-kor/rentre-agents/main/shared-commands/quick-install.sh | bash
#
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_URL="https://github.com/doublecheck-kor/rentre-agents.git"
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
    cd "$INSTALL_DIR" && git pull --recurse-submodules
    git submodule update --init --recursive
else
    echo "다운로드 중..."
    git clone --recurse-submodules "$REPO_URL" "$INSTALL_DIR"
fi

# install.sh 실행
chmod +x "$INSTALL_DIR/shared-commands/install.sh"
"$INSTALL_DIR/shared-commands/install.sh"
