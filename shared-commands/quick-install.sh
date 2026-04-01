#!/bin/bash
# ============================================
# Rentre Agents - 원클릭 설치
# ============================================
# 팀원에게 이 한 줄만 공유하면 됩니다:
#
#   curl -sL https://raw.githubusercontent.com/doublecheck-kor/rentre-agents/main/shared-commands/quick-install.sh | bash
#
# 동작:
#   1. ~/.rentre-agents/ 에 레포 clone (또는 update)
#   2. install.sh 실행 → 글로벌 Rentre + 현재 프로젝트 BMAD
# ============================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

REPO_URL="https://github.com/doublecheck-kor/rentre-agents.git"
INSTALL_DIR="$HOME/.rentre-agents"

# Claude Code 확인
if ! command -v claude &> /dev/null; then
    echo -e "${YELLOW}[!] Claude Code가 없습니다. 먼저 설치하세요:${NC}"
    echo "    npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# clone 또는 update
if [ -d "$INSTALL_DIR" ]; then
    echo "기존 설치 발견. 업데이트합니다..."
    cd "$INSTALL_DIR" && git pull --recurse-submodules
    git submodule update --init --recursive
    cd - > /dev/null
else
    echo "다운로드 중..."
    git clone --recurse-submodules "$REPO_URL" "$INSTALL_DIR"
fi

# install.sh 실행 (현재 디렉토리에 BMAD 설치)
chmod +x "$INSTALL_DIR/shared-commands/install.sh"
bash "$INSTALL_DIR/shared-commands/install.sh"

echo ""
echo -e "${GREEN}다음 단계:${NC} Claude Code에서 /rentre:setup 실행"
