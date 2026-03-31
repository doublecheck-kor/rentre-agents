#!/bin/bash
# ============================================
# Rentre Agents 설치 스크립트
# ============================================
# 사용법:
#   bash install.sh                  ← 글로벌 + 현재 프로젝트에 BMAD 설치
#   bash install.sh --global-only    ← 글로벌만 (Rentre 커맨드)
#   bash install.sh --bmad-only      ← 현재 프로젝트에 BMAD만
#   bash install.sh --remove         ← 전체 제거
#
# 동작 방식:
#   1) 글로벌: Rentre 커맨드 → ~/.claude/commands/rentre/ (항상)
#   2) 프로젝트: BMAD 스킬 → $PWD/.claude/skills/ (현재 디렉토리)
# ============================================

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$SCRIPT_DIR/rentre"
PROJECT_DIR="$(pwd)"

# 글로벌 경로
GLOBAL_CMD_DIR="$HOME/.claude/commands/rentre"
GLOBAL_SKILLS_DIR="$HOME/.claude/skills"
CONFIG_FILE="$HOME/.claude/rentre-config.json"
CRON_SOURCE="$REPO_DIR/cron-prompts"
CRON_TARGET="$HOME/.claude/rentre-cron-prompts"
SCRIPTS_SOURCE="$REPO_DIR/scripts"
SCRIPTS_TARGET="$HOME/.claude/rentre-scripts"
VERSION_FILE="$REPO_DIR/VERSION"
LOCAL_VERSION_FILE="$HOME/.claude/rentre-version"

# BMAD 경로
BMAD_DIR="$REPO_DIR/bmad-submodule"

# 색상
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

# 플래그
DO_GLOBAL=true
DO_BMAD=true

# 옵션 처리
while [[ $# -gt 0 ]]; do
    case $1 in
        --global-only)
            DO_BMAD=false
            shift
            ;;
        --bmad-only)
            DO_GLOBAL=false
            shift
            ;;
        --config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        --remove)
            echo -e "${YELLOW}Rentre Agents 제거 중...${NC}"
            rm -rf "$GLOBAL_CMD_DIR" "$CRON_TARGET" "$SCRIPTS_TARGET" "$LOCAL_VERSION_FILE"
            rm -f "$GLOBAL_SKILLS_DIR/rentre-pr-notion" "$GLOBAL_SKILLS_DIR/rentre-pr-split"
            # 현재 프로젝트 BMAD 제거
            if [ -d "$PROJECT_DIR/.claude/skills" ]; then
                find "$PROJECT_DIR/.claude/skills" -maxdepth 1 -type l -name "bmad-*" -delete 2>/dev/null
                find "$PROJECT_DIR/.claude/skills" -maxdepth 1 -type l -name "gds-*" -delete 2>/dev/null
                rm -f "$PROJECT_DIR/.claude/skills/wds" "$PROJECT_DIR/.claude/skills/applying-fsd-architecture"
            fi
            rm -f "$PROJECT_DIR/_bmad"
            echo -e "${GREEN}[OK]${NC} 제거 완료"
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

echo ""
echo -e "${GREEN}"
cat << 'LOGO'
    ____             __
   / __ \___  ____  / /_________
  / /_/ / _ \/ __ \/ __/ ___/ _ \
 / _, _/  __/ / / / /_/ /  /  __/
/_/ |_|\___/_/ /_/\__/_/   \___/
                         Agents
LOGO
echo -e "${NC}"

# ============================================
# 1. 글로벌 설치: Rentre 커맨드
# ============================================
if [ "$DO_GLOBAL" = true ]; then
    echo -e "${CYAN}[1/2] 글로벌 설치 (Rentre 커맨드)${NC}"

    # config.json 확인
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}[!] 설정 파일이 없습니다.${NC}"
        echo ""
        echo "  방법 1 (추천): Claude Code에서 /rentre:setup 실행"
        echo "  방법 2: cp $REPO_DIR/config.example.json $CONFIG_FILE"
        echo ""

        # setup + help만 부트스트랩 설치
        mkdir -p "$GLOBAL_CMD_DIR"
        cp "$SOURCE_DIR/setup.md" "$GLOBAL_CMD_DIR/setup.md" 2>/dev/null
        cp "$SOURCE_DIR/help.md" "$GLOBAL_CMD_DIR/help.md" 2>/dev/null
        echo -e "${GREEN}  [OK]${NC} /rentre:setup, /rentre:help 설치됨"
        echo "  → Claude Code에서 /rentre:setup 을 실행하세요."
    else
        # 플레이스홀더 치환 함수
        install_with_substitution() {
            local src_dir="$1"
            local dst_dir="$2"
            mkdir -p "$dst_dir"
            for src_file in "$src_dir"/*; do
                [ -f "$src_file" ] || continue
                local filename=$(basename "$src_file")
                local dst_file="$dst_dir/$filename"
                cp "$src_file" "$dst_file"
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

        # 기존 설치 정리
        [ -e "$GLOBAL_CMD_DIR" ] && rm -rf "$GLOBAL_CMD_DIR"
        [ -e "$CRON_TARGET" ] && rm -rf "$CRON_TARGET"
        [ -e "$SCRIPTS_TARGET" ] && rm -rf "$SCRIPTS_TARGET"

        # 커맨드 설치
        install_with_substitution "$SOURCE_DIR" "$GLOBAL_CMD_DIR"
        echo -e "${GREEN}  [OK]${NC} Rentre 커맨드 → ~/.claude/commands/rentre/"

        # 크론 프롬프트
        if [ -d "$CRON_SOURCE" ]; then
            install_with_substitution "$CRON_SOURCE" "$CRON_TARGET"
            echo -e "${GREEN}  [OK]${NC} 크론 프롬프트 → ~/.claude/rentre-cron-prompts/"
        fi

        # 스크립트
        if [ -d "$SCRIPTS_SOURCE" ]; then
            install_with_substitution "$SCRIPTS_SOURCE" "$SCRIPTS_TARGET"
            chmod +x "$SCRIPTS_TARGET"/*.sh 2>/dev/null
            echo -e "${GREEN}  [OK]${NC} 스크립트 → ~/.claude/rentre-scripts/"
        fi
    fi

    # 버전 기록
    if [ -f "$VERSION_FILE" ]; then
        cp "$VERSION_FILE" "$LOCAL_VERSION_FILE"
    fi
fi

# ============================================
# 2. 프로젝트 설치: BMAD 스킬
# ============================================
if [ "$DO_BMAD" = true ]; then
    echo ""
    echo -e "${CYAN}[2/2] 프로젝트 설치 (BMAD 스킬 → $PROJECT_DIR)${NC}"

    if [ ! -d "$BMAD_DIR" ] || [ ! -d "$BMAD_DIR/.claude/skills" ]; then
        echo -e "${YELLOW}  [!] BMAD submodule이 없습니다.${NC}"
        echo "  → cd $REPO_DIR && git submodule update --init --recursive"
    else
        TARGET_SKILLS_DIR="$PROJECT_DIR/.claude/skills"
        mkdir -p "$TARGET_SKILLS_DIR"

        # 기존 BMAD 심링크 정리
        REMOVED=0
        for pattern in "bmad-*" "gds-*"; do
            for item in "$TARGET_SKILLS_DIR"/$pattern; do
                if [ -L "$item" ]; then
                    rm "$item"
                    REMOVED=$((REMOVED + 1))
                fi
            done
        done
        for exact in "wds" "applying-fsd-architecture"; do
            if [ -L "$TARGET_SKILLS_DIR/$exact" ]; then
                rm "$TARGET_SKILLS_DIR/$exact"
                REMOVED=$((REMOVED + 1))
            fi
        done

        # 절대 경로 심링크 생성
        LINKED=0
        for skill_dir in "$BMAD_DIR"/.claude/skills/bmad-* "$BMAD_DIR"/.claude/skills/gds-*; do
            [ -d "$skill_dir" ] || continue
            local_name=$(basename "$skill_dir")
            ln -s "$skill_dir" "$TARGET_SKILLS_DIR/$local_name"
            LINKED=$((LINKED + 1))
        done
        for exact in "wds" "applying-fsd-architecture"; do
            if [ -d "$BMAD_DIR/.claude/skills/$exact" ]; then
                ln -s "$BMAD_DIR/.claude/skills/$exact" "$TARGET_SKILLS_DIR/$exact"
                LINKED=$((LINKED + 1))
            fi
        done
        echo -e "${GREEN}  [OK]${NC} BMAD 스킬 ${LINKED}개 심링크 → $TARGET_SKILLS_DIR/"

        # _bmad 심링크
        TARGET_BMAD="$PROJECT_DIR/_bmad"
        [ -e "$TARGET_BMAD" ] || [ -L "$TARGET_BMAD" ] && rm -rf "$TARGET_BMAD"
        ln -s "$BMAD_DIR/_bmad" "$TARGET_BMAD"
        echo -e "${GREEN}  [OK]${NC} _bmad → $TARGET_BMAD"

        # CLAUDE.md 생성 (config가 있고, 프로젝트에 template이 없으면)
        if [ -f "$CONFIG_FILE" ] && [ -f "$REPO_DIR/CLAUDE.md.template" ] && [ "$PROJECT_DIR" = "$REPO_DIR" ]; then
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
            echo -e "${GREEN}  [OK]${NC} CLAUDE.md 생성"
        fi
    fi
fi

# ============================================
# 완료
# ============================================
echo ""
INSTALLED_VERSION=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]' || echo "unknown")

if [ -f "$CONFIG_FILE" ]; then
    USER_NAME=$(node -e "const c=require('$CONFIG_FILE');console.log(c.user_name||'')" 2>/dev/null)
    if [ -n "$USER_NAME" ]; then
        echo -e "  안녕하세요, ${GREEN}${USER_NAME}${NC}님!"
    fi
fi

echo -e "  Rentre Agents ${GREEN}v${INSTALLED_VERSION}${NC} 설치 완료"
echo ""
echo "  시작하기: /rentre:help"
echo "  전체 가이드: /bmad-help"
echo ""
