#!/bin/bash
# ============================================
# Rentre Agent Commands 설치 스크립트
# ============================================
# 사용법: ./install.sh
# 제거:   ./install.sh --remove
#
# 모든 팀원이 이 스크립트를 한번 실행하면
# 어디서든 /rentre:* 커맨드를 사용할 수 있습니다.
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/rentre"
TARGET_DIR="$HOME/.claude/commands/rentre"

# 색상
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$1" = "--remove" ]; then
    if [ -L "$TARGET_DIR" ]; then
        rm "$TARGET_DIR"
        echo -e "${GREEN}[OK]${NC} rentre 커맨드 제거 완료"
    elif [ -d "$TARGET_DIR" ]; then
        rm -rf "$TARGET_DIR"
        echo -e "${GREEN}[OK]${NC} rentre 커맨드 제거 완료"
    else
        echo "설치된 커맨드가 없습니다."
    fi
    exit 0
fi

# Claude Code 설치 확인
if ! command -v claude &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} Claude Code가 설치되어 있지 않습니다."
    echo "설치: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# ~/.claude/commands 디렉토리 생성
mkdir -p "$HOME/.claude/commands"

# 기존 설치 확인
if [ -e "$TARGET_DIR" ]; then
    echo "기존 rentre 커맨드가 있습니다. 업데이트합니다."
    rm -rf "$TARGET_DIR"
fi

# 심볼릭 링크 생성 (업데이트 시 git pull만 하면 자동 반영)
ln -s "$SOURCE_DIR" "$TARGET_DIR"

echo ""
echo -e "${GREEN}=== Rentre Agent Commands 설치 완료 ===${NC}"
echo ""
echo "사용 가능한 커맨드:"

for f in "$SOURCE_DIR"/*.md; do
    name=$(basename "$f" .md)
    desc=$(head -1 "$f" | sed 's/#//g' | xargs)
    echo "  /rentre:$name"
done

echo ""
echo "사용법: Claude Code에서 /rentre:커맨드명 [인자]"
echo "예시:  /rentre:schedule 박재만님 오늘 스케줄"
echo "       /rentre:develop [PRD 내용]"
echo "       /rentre:agile [지시사항]"
echo ""
echo "업데이트: 이 repo에서 git pull하면 자동 반영됩니다."
