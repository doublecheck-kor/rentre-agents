#!/bin/bash
# ============================================
# Rentre Agent Commands 설치 스크립트
# ============================================
# 사용법: ./install.sh [--config /path/to/config.json]
# 제거:   ./install.sh --remove
#
# config.json이 있으면 플레이스홀더를 치환하여 설치합니다.
# config.json이 없으면 /rentre:setup으로 설정을 안내합니다.
# ============================================

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$SCRIPT_DIR/rentre"
TARGET_DIR="$HOME/.claude/commands/rentre"
CONFIG_FILE="$HOME/.claude/rentre-config.json"
CRON_SOURCE="$REPO_DIR/cron-prompts"
CRON_TARGET="$HOME/.claude/rentre-cron-prompts"
SCRIPTS_SOURCE="$REPO_DIR/scripts"
SCRIPTS_TARGET="$HOME/.claude/rentre-scripts"
VERSION_FILE="$REPO_DIR/VERSION"
LOCAL_VERSION_FILE="$HOME/.claude/rentre-version"

# 색상
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --config 옵션 처리
while [[ $# -gt 0 ]]; do
    case $1 in
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --remove)
            rm -rf "$TARGET_DIR" "$CRON_TARGET" "$SCRIPTS_TARGET"
            echo -e "${GREEN}[OK]${NC} rentre 커맨드 제거 완료"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

# Claude Code 설치 확인
if ! command -v claude &> /dev/null; then
    echo -e "${RED}[ERROR]${NC} Claude Code가 설치되어 있지 않습니다."
    echo "설치: npm install -g @anthropic-ai/claude-code"
    exit 1
fi

# 디렉토리 생성
mkdir -p "$HOME/.claude/commands"

# 기존 설치 정리
[ -e "$TARGET_DIR" ] && rm -rf "$TARGET_DIR"
[ -e "$CRON_TARGET" ] && rm -rf "$CRON_TARGET"
[ -e "$SCRIPTS_TARGET" ] && rm -rf "$SCRIPTS_TARGET"

# config.json 존재 확인
if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${YELLOW}[!] 설정 파일이 없습니다.${NC}"
    echo ""
    echo "두 가지 방법으로 설정할 수 있습니다:"
    echo ""
    echo "  방법 1 (추천): Claude Code에서 /rentre:setup 실행"
    echo "    → MCP로 Slack/Notion/Gmail 정보를 자동 감지합니다."
    echo ""
    echo "  방법 2: 수동 설정"
    echo "    cp $REPO_DIR/config.example.json $CONFIG_FILE"
    echo "    → 값을 편집한 후 이 스크립트를 다시 실행하세요."
    echo ""

    # setup 커맨드만 먼저 설치 (부트스트랩)
    mkdir -p "$TARGET_DIR"
    cp "$SOURCE_DIR/setup.md" "$TARGET_DIR/setup.md" 2>/dev/null
    cp "$SOURCE_DIR/help.md" "$TARGET_DIR/help.md" 2>/dev/null
    echo -e "${GREEN}[OK]${NC} /rentre:setup 커맨드를 설치했습니다."
    echo "Claude Code에서 /rentre:setup 을 실행하세요."
    exit 0
fi

echo ""
echo -e "${GREEN}=== Rentre Agent Commands 설치 ===${NC}"
echo ""

# config.json에서 값 읽기 (node 사용 — Claude Code가 설치되어 있으므로 node는 항상 있음)
read_config() {
    node -e "
        const cfg = require('$CONFIG_FILE');
        const key = process.argv[1];
        console.log(cfg[key] || '');
    " "$1"
}

# 플레이스홀더 치환하여 파일 복사
install_with_substitution() {
    local src_dir="$1"
    local dst_dir="$2"

    mkdir -p "$dst_dir"

    for src_file in "$src_dir"/*; do
        [ -f "$src_file" ] || continue
        local filename=$(basename "$src_file")
        local dst_file="$dst_dir/$filename"

        # 파일 복사 후 플레이스홀더 치환
        cp "$src_file" "$dst_file"

        # node로 모든 {{KEY}} 플레이스홀더를 config 값으로 치환
        node -e "
            const fs = require('fs');
            const cfg = require('$CONFIG_FILE');
            let content = fs.readFileSync('$dst_file', 'utf8');
            for (const [key, value] of Object.entries(cfg)) {
                const placeholder = '{{' + key.toUpperCase() + '}}';
                content = content.split(placeholder).join(value || '');
            }
            fs.writeFileSync('$dst_file', content);
        "
    done
}

# 커맨드 파일 설치
echo "커맨드 파일 설치 중..."
install_with_substitution "$SOURCE_DIR" "$TARGET_DIR"

# 크론 프롬프트 설치
if [ -d "$CRON_SOURCE" ]; then
    echo "크론 프롬프트 설치 중..."
    install_with_substitution "$CRON_SOURCE" "$CRON_TARGET"
fi

# 스크립트 설치
if [ -d "$SCRIPTS_SOURCE" ]; then
    echo "스크립트 설치 중..."
    install_with_substitution "$SCRIPTS_SOURCE" "$SCRIPTS_TARGET"
    chmod +x "$SCRIPTS_TARGET"/*.sh 2>/dev/null
fi

# CLAUDE.md 템플릿 처리 (프로젝트 디렉토리용)
if [ -f "$REPO_DIR/CLAUDE.md.template" ]; then
    echo "CLAUDE.md 생성 중..."
    cp "$REPO_DIR/CLAUDE.md.template" "$REPO_DIR/CLAUDE.md"
    node -e "
        const fs = require('fs');
        const cfg = require('$CONFIG_FILE');
        let content = fs.readFileSync('$REPO_DIR/CLAUDE.md', 'utf8');
        for (const [key, value] of Object.entries(cfg)) {
            const placeholder = '{{' + key.toUpperCase() + '}}';
            content = content.split(placeholder).join(value || '');
        }
        fs.writeFileSync('$REPO_DIR/CLAUDE.md', content);
    "
fi

# 버전 기록
if [ -f "$VERSION_FILE" ]; then
    cp "$VERSION_FILE" "$LOCAL_VERSION_FILE"
    INSTALLED_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
else
    INSTALLED_VERSION="unknown"
fi

echo ""
echo -e "${GREEN}[OK] Rentre Agents v${INSTALLED_VERSION} 설치 완료!${NC}"
echo ""
echo "사용 가능한 커맨드:"
for f in "$TARGET_DIR"/*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f" .md)
    [[ "$name" == _* ]] && continue
    echo "  /rentre:$name"
done
echo ""
echo "시작하기: Claude Code에서 /rentre:help"
echo "업데이트: cd $(dirname "$SCRIPT_DIR") && git pull && ./shared-commands/install.sh"
