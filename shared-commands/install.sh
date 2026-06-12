#!/bin/bash
# ============================================
# Rentre Agents 설치 스크립트 v3.0
# ============================================
# rentre-agents는 프로젝트 내 git submodule로 사용됩니다.
#
# 사용법:
#   bash rentre-agents/install.sh                    ← 프로젝트 설치
#   bash rentre-agents/install.sh --global-only      ← 글로벌 커맨드만 (부트스트랩)
#   bash rentre-agents/install.sh --with-global      ← 프로젝트 + 글로벌 동시 설치
#   bash rentre-agents/install.sh --yes              ← 대화형 프롬프트 없이 자동
#   bash rentre-agents/install.sh --remove           ← 제거
#
# 설치 구조:
#   글로벌 (1회):       superpowers 플러그인 (obra/superpowers-marketplace, user 스코프)
#   프로젝트 (.claude/commands/rentre/): 모든 커맨드 (assistant, help, setup, adr, ailab 등)
#   글로벌 (~/.claude/commands/rentre/): --with-global 또는 --global-only 시에만
#
# 개발 스킬은 superpowers 플러그인(글로벌)이 제공합니다. (TDD, 디버깅,
# 브레인스토밍, 플랜 작성/실행, 코드리뷰 등) — 프로젝트별 심링크가 아닙니다.
# ============================================

set -euo pipefail

# ─── Bash 버전 확인 (4.3+ 필요: nameref, associative arrays) ───
if [ "${BASH_VERSINFO[0]}" -lt 4 ] || { [ "${BASH_VERSINFO[0]}" -eq 4 ] && [ "${BASH_VERSINFO[1]}" -lt 3 ]; }; then
    echo "ERROR: Bash 4.3 이상이 필요합니다 (현재: $BASH_VERSION)"
    echo ""
    echo "macOS 사용자:"
    echo "  brew install bash"
    echo "  /opt/homebrew/bin/bash rentre-agents/install.sh"
    exit 1
fi

# ─── 경로 설정 ───────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$SCRIPT_DIR/rentre"
PROJECT_DIR="$(pwd)"
VERSION_FILE="$REPO_DIR/VERSION"
CONFIG_FILE="$HOME/.claude/rentre-config.json"

# ─── superpowers 플러그인 ─────────────────────────────
SUPERPOWERS_MARKETPLACE="obra/superpowers-marketplace"
SUPERPOWERS_MARKETPLACE_NAME="superpowers-marketplace"
SUPERPOWERS_PLUGIN="superpowers@superpowers-marketplace"

# ─── 색상 (비터미널이면 비활성화) ─────────────────────
if [ -t 1 ]; then
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    DIM='\033[2m'
    NC='\033[0m'
else
    GREEN='' YELLOW='' RED='' CYAN='' BOLD='' DIM='' NC=''
fi

# ─── 커맨드 목록 ─────────────────────────────────────
GLOBAL_COMMANDS=("assistant.md" "help.md" "setup.md")
PROJECT_COMMANDS=("assistant.md" "help.md" "setup.md" "adr.md" "ailab.md" "_backlog-rules.md" "resume-review.md" "marketplace.md" "pm-weekly-backlog.md")

# ─── 유틸리티 함수 ───────────────────────────────────

print_logo() {
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
}

# 크로스 플랫폼 sed -i
sedi() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# 플레이스홀더 치환 (Node.js 없이)
substitute_placeholders() {
    local file="$1"
    local config="$2"
    [ -f "$config" ] || return 0
    if command -v jq &>/dev/null; then
        local keys
        keys=$(jq -r 'keys[]' "$config" 2>/dev/null) || return 0
        while IFS= read -r key; do
            [ -z "$key" ] && continue
            # jq로 값 가져오되, 개행을 \\n 리터럴로 보존
            local value
            value=$(jq -r ".[\"$key\"] // \"\"" "$config" | head -1)
            local placeholder escaped_value
            placeholder="{{$(echo "$key" | tr '[:lower:]' '[:upper:]')}}"
            # sed 메타문자 이스케이프
            escaped_value=$(printf '%s' "$value" | sed 's/[&\\/|]/\\&/g')
            sedi "s|$placeholder|$escaped_value|g" "$file" 2>/dev/null || true
        done <<< "$keys"
    else
        # jq 없을 때 순수 bash 파싱 (단순 flat JSON)
        while IFS= read -r line; do
            local key value placeholder escaped_value
            key=$(echo "$line" | sed -n 's/.*"\([^"]*\)"[[:space:]]*:.*/\1/p')
            value=$(echo "$line" | sed -n 's/.*:[[:space:]]*"\([^"]*\)".*/\1/p')
            if [ -n "$key" ] && [ -n "$value" ]; then
                placeholder="{{$(echo "$key" | tr '[:lower:]' '[:upper:]')}}"
                escaped_value=$(printf '%s' "$value" | sed 's/[&\\/|]/\\&/g')
                sedi "s|$placeholder|$escaped_value|g" "$file" 2>/dev/null || true
            fi
        done < <(grep '"[^"]*"[[:space:]]*:' "$config")
    fi
}

# MCP 서버 감지
detect_mcp() {
    local settings_file="$HOME/.claude/settings.json"
    local project_settings="$PROJECT_DIR/.claude/settings.json"

    declare -gA MCP_STATUS
    local mcp_names=("Notion" "Slack" "Google Calendar" "Gmail" "Linear" "Figma" "GitHub")
    local mcp_keys=("notion" "slack" "google.calendar" "gmail" "linear" "figma" "github")

    for i in "${!mcp_names[@]}"; do
        MCP_STATUS["${mcp_names[$i]}"]="disconnected"
    done

    # settings.json 파싱
    for settings in "$settings_file" "$project_settings"; do
        [ -f "$settings" ] || continue
        if command -v jq &>/dev/null; then
            local mcpServers
            mcpServers=$(jq -r '.mcpServers // {} | keys[]' "$settings" 2>/dev/null) || continue
            while IFS= read -r server; do
                [ -z "$server" ] && continue
                local server_lower
                server_lower=$(echo "$server" | tr '[:upper:]' '[:lower:]')
                for j in "${!mcp_names[@]}"; do
                    if echo "$server_lower" | grep -qi "${mcp_keys[$j]}"; then
                        MCP_STATUS["${mcp_names[$j]}"]="connected"
                    fi
                done
            done <<< "$mcpServers"
        else
            for j in "${!mcp_names[@]}"; do
                if grep -qiF "${mcp_keys[$j]}" "$settings" 2>/dev/null; then
                    MCP_STATUS["${mcp_names[$j]}"]="connected"
                fi
            done
        fi
    done

    # gh CLI 확인
    if command -v gh &>/dev/null && gh auth status &>/dev/null; then
        MCP_STATUS["GitHub"]="connected"
    fi
}

# MCP 상태 표시
print_mcp_status() {
    echo -e "  ${BOLD}📡 MCP 연결 상태${NC}"
    echo -e "  ─────────────────────────────"
    for name in "Notion" "Slack" "Google Calendar" "Gmail" "Linear" "Figma" "GitHub"; do
        if [ "${MCP_STATUS[$name]}" = "connected" ]; then
            printf "  ${GREEN}✅${NC} %-18s — 연결됨\n" "$name"
        else
            printf "  ${RED}❌${NC} %-18s — 미연결\n" "$name"
        fi
    done
    echo ""
}

# ─── superpowers 플러그인 설치 (글로벌, 멱등) ──────────

install_superpowers() {
    # claude CLI 없으면 스킵 (메인에서 이미 검사하지만 방어적으로)
    if ! command -v claude &>/dev/null; then
        echo -e "  ${YELLOW}[!]${NC} claude CLI 없음 — superpowers 설치 건너뜀"
        return 0
    fi

    # 1) 마켓플레이스 등록 (이미 있으면 건너뜀)
    if claude plugin marketplace list 2>/dev/null | grep -q "$SUPERPOWERS_MARKETPLACE_NAME"; then
        echo -e "  ${DIM}superpowers 마켓플레이스 이미 등록됨${NC}"
    else
        if claude plugin marketplace add "$SUPERPOWERS_MARKETPLACE" >/dev/null 2>&1; then
            echo -e "  ${GREEN}[OK]${NC} superpowers 마켓플레이스 등록"
        else
            echo -e "  ${YELLOW}[!]${NC} 마켓플레이스 등록 실패"
            echo -e "      수동 설치: ${CYAN}claude plugin marketplace add $SUPERPOWERS_MARKETPLACE${NC}"
            return 0
        fi
    fi

    # 2) 플러그인 설치 (이미 있으면 건너뜀, user=글로벌 스코프)
    if claude plugin list 2>/dev/null | grep -q "$SUPERPOWERS_PLUGIN"; then
        echo -e "  ${DIM}superpowers 플러그인 이미 설치됨 (글로벌)${NC}"
    else
        if claude plugin install "$SUPERPOWERS_PLUGIN" --scope user >/dev/null 2>&1; then
            echo -e "  ${GREEN}[OK]${NC} superpowers 플러그인 설치 (글로벌/user 스코프)"
        else
            echo -e "  ${YELLOW}[!]${NC} 플러그인 설치 실패"
            echo -e "      수동 설치: ${CYAN}claude plugin install $SUPERPOWERS_PLUGIN --scope user${NC}"
            return 0
        fi
    fi
}

# ─── 커맨드 설치 ─────────────────────────────────────

install_project_commands() {
    local target_dir="$PROJECT_DIR/.claude/commands/rentre"
    mkdir -p "$target_dir"

    local installed=0
    for cmd in "${PROJECT_COMMANDS[@]}"; do
        local src="$SOURCE_DIR/$cmd"
        local dst="$target_dir/$cmd"
        if [ -f "$src" ]; then
            cp "$src" "$dst"
            if [ -f "$CONFIG_FILE" ]; then
                substitute_placeholders "$dst" "$CONFIG_FILE"
            fi
            installed=$((installed + 1))
        fi
    done
    echo -e "  ${GREEN}[OK]${NC} 프로젝트 커맨드 ${installed}개 → .claude/commands/rentre/"
}

install_global_commands() {
    local target_dir="$HOME/.claude/commands/rentre"
    mkdir -p "$target_dir"

    local installed=0
    for cmd in "${GLOBAL_COMMANDS[@]}"; do
        local src="$SOURCE_DIR/$cmd"
        local dst="$target_dir/$cmd"
        if [ -f "$src" ]; then
            cp "$src" "$dst"
            if [ -f "$CONFIG_FILE" ]; then
                substitute_placeholders "$dst" "$CONFIG_FILE"
            fi
            installed=$((installed + 1))
        fi
    done
    echo -e "  ${GREEN}[OK]${NC} 글로벌 커맨드 ${installed}개 → ~/.claude/commands/rentre/"

    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "  ${YELLOW}[!]${NC} 설정 파일 없음 → Claude Code에서 ${CYAN}/rentre:setup${NC} 실행 필요"
    fi
}

# ─── 설치 검증 ────────────────────────────────────────

verify_installation() {
    echo ""
    echo -e "  ${BOLD}📋 설치 검증${NC}"
    echo -e "  ─────────────────────────────"

    local errors=0

    # 글로벌 커맨드 확인 (--with-global 또는 --global-only일 때만)
    if [ "${WITH_GLOBAL:-false}" = true ] || [ "${GLOBAL_ONLY:-false}" = true ]; then
        local global_dir="$HOME/.claude/commands/rentre"
        for cmd in "${GLOBAL_COMMANDS[@]}"; do
            if [ -f "$global_dir/$cmd" ]; then
                echo -e "  ${GREEN}✅${NC} 글로벌: $cmd"
            else
                echo -e "  ${RED}❌${NC} 글로벌: $cmd (누락)"
                errors=$((errors + 1))
            fi
        done
    fi

    # 프로젝트 커맨드 확인
    local proj_cmd_dir="$PROJECT_DIR/.claude/commands/rentre"
    if [ "${GLOBAL_ONLY:-false}" = false ] && [ -d "$proj_cmd_dir" ]; then
        for cmd in "${PROJECT_COMMANDS[@]}"; do
            if [ -f "$proj_cmd_dir/$cmd" ]; then
                echo -e "  ${GREEN}✅${NC} 프로젝트 커맨드: $cmd"
            else
                echo -e "  ${RED}❌${NC} 프로젝트 커맨드: $cmd (누락)"
                errors=$((errors + 1))
            fi
        done
    fi

    # superpowers 플러그인 확인
    if command -v claude &>/dev/null && claude plugin list 2>/dev/null | grep -q "$SUPERPOWERS_PLUGIN"; then
        echo -e "  ${GREEN}✅${NC} superpowers 플러그인 (글로벌)"
    else
        echo -e "  ${YELLOW}⚠️${NC}  superpowers 플러그인 미확인 — 수동 설치 필요할 수 있음"
    fi

    if [ "$errors" -gt 0 ]; then
        echo ""
        echo -e "  ${RED}⚠️  ${errors}개 오류 발견${NC}"
        return 1
    else
        echo ""
        echo -e "  ${GREEN}설치 검증 완료 — 문제 없음${NC}"
        return 0
    fi
}

# ─── 제거 ─────────────────────────────────────────────

do_remove() {
    echo -e "${YELLOW}Rentre Agents 제거 중...${NC}"
    echo ""

    # 프로젝트 커맨드 제거
    local proj_cmd_dir="$PROJECT_DIR/.claude/commands/rentre"
    if [ -d "$proj_cmd_dir" ]; then
        rm -rf "$proj_cmd_dir"
        echo -e "  ${GREEN}[OK]${NC} 프로젝트 커맨드 제거"
    fi

    # 글로벌 커맨드 제거 여부
    echo ""
    echo -ne "  글로벌 커맨드도 제거하시겠습니까? [y/N]: "
    read -r remove_global
    if [[ "$remove_global" =~ ^[yY]$ ]]; then
        rm -rf "$HOME/.claude/commands/rentre"
        echo -e "  ${GREEN}[OK]${NC} 글로벌 커맨드 제거"
    fi

    echo ""
    echo -e "  ${DIM}superpowers 플러그인은 글로벌 공용이라 유지합니다.${NC}"
    echo -e "  ${DIM}직접 제거하려면: claude plugin uninstall $SUPERPOWERS_PLUGIN${NC}"

    echo ""
    echo -e "  ${GREEN}제거 완료${NC}"
    exit 0
}

# ─── 메인 ─────────────────────────────────────────────

main() {
    local GLOBAL_ONLY=false
    local WITH_GLOBAL=false
    local DO_REMOVE=false
    local AUTO_YES=false

    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            --yes|-y)
                AUTO_YES=true
                shift
                ;;
            --global-only)
                GLOBAL_ONLY=true
                shift
                ;;
            --with-global)
                WITH_GLOBAL=true
                shift
                ;;
            --remove)
                DO_REMOVE=true
                shift
                ;;
            --preset)
                # v3.0부터 프리셋/프레임워크 선택 제거 (개발 스킬은 superpowers 글로벌 플러그인)
                echo -e "${YELLOW}[!]${NC} --preset 은 v3.0부터 더 이상 사용되지 않습니다 (무시됨)."
                # 값이 따라오면 함께 소비
                if [ -n "${2:-}" ] && [[ "${2:-}" != --* ]]; then shift 2; else shift; fi
                ;;
            *)
                echo -e "${YELLOW}[!]${NC} 알 수 없는 옵션: $1 (무시됨)"
                shift
                ;;
        esac
    done

    print_logo

    # 제거 모드
    if [ "$DO_REMOVE" = true ]; then
        do_remove
    fi

    # Claude Code 확인
    if ! command -v claude &>/dev/null; then
        echo -e "  ${RED}[ERROR]${NC} Claude Code가 설치되어 있지 않습니다."
        echo "  설치: npm install -g @anthropic-ai/claude-code"
        exit 1
    fi

    # ─── 안전 검사 ───────────────────────────────
    # 홈 디렉토리 경고
    if [ "$PROJECT_DIR" = "$HOME" ] && [ "$GLOBAL_ONLY" = false ]; then
        echo -e "  ${YELLOW}⚠️  홈 디렉토리에 설치하면 글로벌처럼 동작합니다.${NC}"
        if [ "$AUTO_YES" = false ]; then
            echo -ne "  계속하시겠습니까? [y/N]: "
            read -r confirm
            if [[ ! "$confirm" =~ ^[yY]$ ]]; then
                echo "  설치를 취소합니다."
                exit 0
            fi
        fi
    fi

    # .git 존재 확인
    if [ ! -d "$PROJECT_DIR/.git" ] && [ "$GLOBAL_ONLY" = false ]; then
        echo -e "  ${YELLOW}⚠️  현재 디렉토리에 .git이 없습니다.${NC}"
        echo -e "  프로젝트 루트에서 실행해주세요."
        if [ "$AUTO_YES" = false ]; then
            echo -ne "  무시하고 계속하시겠습니까? [y/N]: "
            read -r confirm
            if [[ ! "$confirm" =~ ^[yY]$ ]]; then
                exit 0
            fi
        fi
    fi

    # rentre-agents가 프로젝트 내에 있는지 확인
    if [ "$GLOBAL_ONLY" = false ]; then
        case "$REPO_DIR" in
            "$PROJECT_DIR"/*)
                ;; # 정상: rentre-agents가 프로젝트 하위에 있음
            "$PROJECT_DIR")
                ;; # rentre-agents 자체 프로젝트
            *)
                echo -e "  ${YELLOW}⚠️  rentre-agents가 현재 프로젝트 내에 없습니다.${NC}"
                echo -e "  현재 프로젝트: $PROJECT_DIR"
                echo -e "  rentre-agents: $REPO_DIR"
                if [ "$AUTO_YES" = false ]; then
                    echo -ne "  계속하시겠습니까? [y/N]: "
                    read -r confirm
                    if [[ ! "$confirm" =~ ^[yY]$ ]]; then
                        exit 0
                    fi
                fi
                ;;
        esac
    fi

    # MCP 감지 & 표시
    detect_mcp
    echo ""
    print_mcp_status

    # ─── Step 1: superpowers 플러그인 (글로벌, 멱등) ──
    echo -e "  ${CYAN}${BOLD}[1] 개발 스킬 — superpowers 플러그인 설치${NC}"
    install_superpowers
    echo ""

    # ─── 글로벌 전용 모드 ───────────────────────────
    if [ "$GLOBAL_ONLY" = true ]; then
        echo -e "  ${CYAN}${BOLD}[2] 글로벌 커맨드 설치${NC}"
        install_global_commands
        verify_installation
        echo ""
        echo -e "  ${GREEN}글로벌 부트스트랩 완료${NC}"
        echo ""
        echo "  시작하기: /rentre:help"
        exit 0
    fi

    # ─── Step 2: 글로벌 커맨드 (--with-global 시) ────
    if [ "$WITH_GLOBAL" = true ]; then
        echo -e "  ${CYAN}${BOLD}[2] 글로벌 커맨드 설치${NC}"
        install_global_commands
        echo ""
    fi

    # ─── Step 3: 프로젝트 커맨드 ─────────────────────
    echo -e "  ${CYAN}${BOLD}[3] 프로젝트 커맨드 설치${NC}"
    install_project_commands

    # ─── 설치 검증 ───────────────────────────────
    verify_installation

    # ─── 완료 메시지 ─────────────────────────────
    echo ""
    local version
    version=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]' || echo "unknown")

    if [ -f "$CONFIG_FILE" ]; then
        local user_name=""
        if command -v jq &>/dev/null; then
            user_name=$(jq -r '.user_name // ""' "$CONFIG_FILE" 2>/dev/null)
        else
            user_name=$(grep '"user_name"' "$CONFIG_FILE" | sed 's/.*: *"\([^"]*\)".*/\1/')
        fi
        if [ -n "$user_name" ]; then
            echo -e "  안녕하세요, ${GREEN}${user_name}${NC}님!"
        fi
    fi

    echo -e "  Rentre Agents ${GREEN}v${version}${NC} 설치 완료"
    echo ""
    echo -e "  시작하기:           ${CYAN}/rentre:help${NC}"
    echo -e "  superpowers 활성화: ${CYAN}/reload-plugins${NC} (또는 Claude 재시작)"
    echo ""

    # ─── SessionStart hook: 업데이트 체크 등록 ────
    register_update_hook
}

register_update_hook() {
    local settings_file="$PROJECT_DIR/.claude/settings.local.json"
    local check_script="$REPO_DIR/scripts/check-update.sh"

    # 스크립트 없으면 스킵
    [ -f "$check_script" ] || return 0

    # settings.local.json 없으면 생성
    if [ ! -f "$settings_file" ]; then
        mkdir -p "$(dirname "$settings_file")"
        echo '{}' > "$settings_file"
    fi

    # jq 없으면 스킵
    command -v jq &>/dev/null || return 0

    # 이미 등록되어 있는지 확인
    if jq -e '.hooks.SessionStart[]?.hooks[]? | select(.command | contains("check-update.sh"))' "$settings_file" &>/dev/null; then
        return 0
    fi

    # SessionStart hook 추가
    local hook_cmd="bash $check_script"
    local tmp_file
    tmp_file=$(mktemp)

    jq --arg cmd "$hook_cmd" '
        .hooks //= {} |
        .hooks.SessionStart //= [] |
        .hooks.SessionStart += [{
            "hooks": [{
                "type": "command",
                "command": $cmd,
                "timeout": 10
            }]
        }]
    ' "$settings_file" > "$tmp_file" && mv "$tmp_file" "$settings_file"

    echo -e "  ${GREEN}[OK]${NC} 업데이트 자동 체크 등록 (SessionStart hook)"
}

main "$@"
