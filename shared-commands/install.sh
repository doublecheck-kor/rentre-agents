#!/bin/bash
# ============================================
# Rentre Agents 설치 스크립트 v2.0
# ============================================
# rentre-agents는 프로젝트 내 git submodule로 사용됩니다.
#
# 사용법:
#   bash rentre-agents/install.sh                    ← 대화형 설치
#   bash rentre-agents/install.sh --preset backend   ← 프리셋 설치
#   bash rentre-agents/install.sh --preset frontend
#   bash rentre-agents/install.sh --preset pm
#   bash rentre-agents/install.sh --preset gamedev
#   bash rentre-agents/install.sh --preset full
#   bash rentre-agents/install.sh --global-only      ← 글로벌 커맨드만
#   bash rentre-agents/install.sh --remove           ← 제거
#
# 설치 구조:
#   글로벌 (~/.claude/commands/rentre/): assistant.md, help.md, setup.md
#   프로젝트 (.claude/skills/):          BMAD/GDS/WDS/FSD 스킬 (상대 심링크)
#   프로젝트 (.claude/commands/rentre/): adr.md, ailab.md, _backlog-rules.md
#   프로젝트 (_bmad):                    BMAD config (상대 심링크)
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
BMAD_DIR="$REPO_DIR/bmad-submodule"
BMAD_SKILLS_DIR="$BMAD_DIR/.claude/skills"
PROFILE_FILE="$PROJECT_DIR/.claude/bmad-profile.json"
CONFIG_FILE="$HOME/.claude/rentre-config.json"

# ─── 색상 ────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ─── 글로벌 커맨드 목록 ─────────────────────────────
GLOBAL_COMMANDS=("assistant.md" "help.md" "setup.md")
PROJECT_COMMANDS=("adr.md" "ailab.md" "_backlog-rules.md")

# ─── BMAD Core 서브카테고리 정의 ─────────────────────
declare -a BMAD_AGENTS=(
    bmad-agent-pm bmad-agent-architect bmad-agent-dev bmad-agent-qa
    bmad-agent-ux-designer bmad-agent-tech-writer bmad-agent-sm
    bmad-agent-analyst bmad-agent-builder bmad-agent-quick-flow-solo-dev bmad-tea
)
declare -a BMAD_PLANNING=(
    bmad-create-prd bmad-edit-prd bmad-validate-prd bmad-product-brief
    bmad-create-epics-and-stories bmad-create-story bmad-sprint-planning bmad-sprint-status
)
declare -a BMAD_DEVELOPMENT=(
    bmad-code-review bmad-review-adversarial-general bmad-review-edge-case-hunter
    bmad-quick-dev bmad-dev-story
)
declare -a BMAD_TESTING=(
    bmad-testarch-test-design bmad-testarch-atdd bmad-testarch-automate
    bmad-testarch-framework bmad-testarch-ci bmad-testarch-nfr
    bmad-testarch-test-review bmad-testarch-trace bmad-qa-generate-e2e-tests
    bmad-teach-me-testing
)
declare -a BMAD_ARCHITECTURE=(
    bmad-create-architecture bmad-create-ux-design
)
declare -a BMAD_BUSINESS=(
    bmad-brainstorming bmad-cis-design-thinking bmad-cis-innovation-strategy
    bmad-cis-problem-solving bmad-cis-storytelling bmad-cis-agent-brainstorming-coach
    bmad-cis-agent-design-thinking-coach bmad-cis-agent-creative-problem-solver
    bmad-cis-agent-innovation-strategist bmad-cis-agent-presentation-master
    bmad-cis-agent-storyteller bmad-market-research bmad-domain-research
    bmad-technical-research bmad-retrospective bmad-correct-course
    bmad-check-implementation-readiness bmad-advanced-elicitation
)
declare -a BMAD_DOCUMENTATION=(
    bmad-document-project bmad-generate-project-context bmad-index-docs
    bmad-shard-doc bmad-editorial-review-prose bmad-editorial-review-structure
    bmad-distillator bmad-agent-tech-writer
)
declare -a BMAD_QUALITY=(
    bmad-check-implementation-readiness bmad-correct-course bmad-retrospective
    bmad-sprint-status
)
declare -a BMAD_BUILD_TOOLS=(
    bmad-module-builder bmad-workflow-builder bmad-bmb-setup
)
declare -a BMAD_UTILITIES=(
    bmad-init bmad-help bmad-party-mode
)

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

# 상대 경로 계산: relative_path <from_dir> <to_file>
relative_path() {
    local from_dir="$1"
    local to_file="$2"
    python3 -c "import os.path, sys; print(os.path.relpath(sys.argv[2], sys.argv[1]))" "$from_dir" "$to_file" 2>/dev/null \
        || perl -e 'use File::Spec; print File::Spec->abs2rel($ARGV[1], $ARGV[0])' "$from_dir" "$to_file" 2>/dev/null \
        || echo "$to_file"
}

# 심링크 생성 (상대경로, 실패 시 복사 폴백)
create_link() {
    local source_path="$1"
    local target_path="$2"
    local target_dir
    target_dir="$(dirname "$target_path")"

    # 이미 존재하면 스킵
    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        return 0
    fi

    local rel_path
    rel_path="$(relative_path "$target_dir" "$source_path")"

    if ln -s "$rel_path" "$target_path" 2>/dev/null; then
        return 0
    else
        # 심링크 실패 시 (Windows 등) 복사 폴백
        if [ -d "$source_path" ]; then
            cp -r "$source_path" "$target_path"
        else
            cp "$source_path" "$target_path"
        fi
        LINK_MODE="copy"
        return 0
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
            local value
            value=$(jq -r ".[\"$key\"] // \"\"" "$config")
            local placeholder escaped_value
            placeholder="{{$(echo "$key" | tr '[:lower:]' '[:upper:]')}}"
            escaped_value=$(printf '%s\n' "$value" | sed 's/[&\|/]/\\&/g')
            sedi "s|$placeholder|$escaped_value|g" "$file"
        done <<< "$keys"
    else
        # jq 없을 때 순수 bash 파싱 (단순 flat JSON)
        while IFS= read -r line; do
            local key value placeholder escaped_value
            key=$(echo "$line" | sed -n 's/.*"\([^"]*\)"[[:space:]]*:.*/\1/p')
            value=$(echo "$line" | sed -n 's/.*:[[:space:]]*"\([^"]*\)".*/\1/p')
            if [ -n "$key" ] && [ -n "$value" ]; then
                placeholder="{{$(echo "$key" | tr '[:lower:]' '[:upper:]')}}"
                escaped_value=$(printf '%s\n' "$value" | sed 's/[&\|/]/\\&/g')
                sedi "s|$placeholder|$escaped_value|g" "$file"
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

# 스킬 목록을 배열로 수집 (중복 제거)
collect_skills() {
    local -n result_ref=$1
    shift
    for skill in "$@"; do
        local found=false
        for existing in "${result_ref[@]+"${result_ref[@]}"}"; do
            if [ "$existing" = "$skill" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            # 실제 존재하는지 확인
            if [ -d "$BMAD_SKILLS_DIR/$skill" ]; then
                result_ref+=("$skill")
            fi
        fi
    done
}

# ─── 프레임워크 메뉴 ─────────────────────────────────

show_framework_menu() {
    local gds_count wds_count bmad_count fsd_count total_count
    bmad_count=$(ls -d "$BMAD_SKILLS_DIR"/bmad-* 2>/dev/null | wc -l | tr -d ' ')
    gds_count=$(ls -d "$BMAD_SKILLS_DIR"/gds-* 2>/dev/null | wc -l | tr -d ' ')
    wds_count=$(ls -d "$BMAD_SKILLS_DIR"/wds* 2>/dev/null | wc -l | tr -d ' ')
    fsd_count=1
    total_count=$((bmad_count + gds_count + wds_count + fsd_count))

    echo ""
    echo -e "  ╔══════════════════════════════════════════════════════╗"
    echo -e "  ║  ${BOLD}Rentre Agents 설치${NC} — ${CYAN}$(basename "$PROJECT_DIR")${NC}"
    echo -e "  ╠══════════════════════════════════════════════════════╣"
    echo -e "  ║"

    print_mcp_status

    echo -e "  ║  ${BOLD}🏗️  프레임워크 선택${NC}"
    echo -e "  ║  ─────────────────────────────"
    printf "  ║  ${GREEN}[1]${NC} 🔧 BMAD Core     (웹/앱 개발)         %3d개 스킬\n" "$bmad_count"
    printf "  ║  ${GREEN}[2]${NC} 🎮 GDS           (게임 개발)           %3d개 스킬\n" "$gds_count"
    printf "  ║  ${GREEN}[3]${NC} 🎨 WDS           (UX/디자인 시스템)    %3d개 스킬\n" "$wds_count"
    printf "  ║  ${GREEN}[4]${NC} 📐 FSD           (프론트엔드 아키텍처)   %d개 스킬\n" "$fsd_count"
    printf "  ║  ${GREEN}[A]${NC} ✅ 전체 설치                          %3d개 스킬\n" "$total_count"
    echo -e "  ║"
    echo -e "  ║  💡 여러 개 선택 가능: ${DIM}1,3${NC} 또는 ${DIM}1 3${NC}"
    echo -e "  ╚══════════════════════════════════════════════════════╝"
    echo ""
    echo -ne "  선택 (1-4, A, 또는 조합): "
}

show_bmad_subcategory_menu() {
    echo ""
    echo -e "  ╔══════════════════════════════════════════════════════╗"
    echo -e "  ║  ${BOLD}BMAD Core — 세부 카테고리 선택${NC}"
    echo -e "  ╠══════════════════════════════════════════════════════╣"
    printf "  ║  ${GREEN}[1]${NC} 👥 에이전트        PM, 아키텍트, 개발자 등  %2d개\n" "${#BMAD_AGENTS[@]}"
    printf "  ║  ${GREEN}[2]${NC} 📋 기획/스프린트   PRD, 에픽, 스토리        %2d개\n" "${#BMAD_PLANNING[@]}"
    printf "  ║  ${GREEN}[3]${NC} 💻 개발/코드리뷰   quick-dev, 코드리뷰      %2d개\n" "${#BMAD_DEVELOPMENT[@]}"
    printf "  ║  ${GREEN}[4]${NC} 🧪 테스트/QA      ATDD, CI, 프레임워크     %2d개\n" "${#BMAD_TESTING[@]}"
    printf "  ║  ${GREEN}[5]${NC} 🏛️  아키텍처       기술 설계, UX 설계        %2d개\n" "${#BMAD_ARCHITECTURE[@]}"
    printf "  ║  ${GREEN}[6]${NC} 💼 비즈니스/전략   브레인스토밍, 리서치      %2d개\n" "${#BMAD_BUSINESS[@]}"
    printf "  ║  ${GREEN}[7]${NC} 📝 문서화         프로젝트 문서, 편집 리뷰  %2d개\n" "${#BMAD_DOCUMENTATION[@]}"
    printf "  ║  ${GREEN}[8]${NC} ✅ 품질/회고       구현 준비 확인, 회고      %2d개\n" "${#BMAD_QUALITY[@]}"
    printf "  ║  ${GREEN}[9]${NC} 🔨 빌드 도구      모듈, 워크플로우 빌더     %2d개\n" "${#BMAD_BUILD_TOOLS[@]}"
    printf "  ║  ${GREEN}[0]${NC} 📚 교육/유틸      초기화, 도움말, 파티모드  %2d개\n" "${#BMAD_UTILITIES[@]}"
    echo -e "  ║  ${GREEN}[A]${NC} ✅ BMAD 전체"
    echo -e "  ║"
    echo -e "  ║  💡 추천 조합:"
    echo -e "  ║  ${DIM}• 백엔드 개발: 1,2,3,4,5${NC}"
    echo -e "  ║  ${DIM}• 프론트엔드:  1,2,3,5${NC}"
    echo -e "  ║  ${DIM}• PM/기획:     1,2,6,7${NC}"
    echo -e "  ╚══════════════════════════════════════════════════════╝"
    echo ""
    echo -ne "  선택 (0-9, A, 또는 조합): "
}

# 선택 문자열 파싱 → 배열 ("1,3 4" → "1" "3" "4")
parse_selections() {
    local input="$1"
    echo "$input" | tr ',' ' ' | tr -s ' '
}

# ─── 스킬 설치 로직 ──────────────────────────────────

install_skills() {
    local -a skills_to_install=("$@")
    local target_dir="$PROJECT_DIR/.claude/skills"
    mkdir -p "$target_dir"

    local installed=0
    local skipped=0

    for skill in "${skills_to_install[@]}"; do
        local source="$BMAD_SKILLS_DIR/$skill"
        local target="$target_dir/$skill"

        if [ ! -d "$source" ]; then
            skipped=$((skipped + 1))
            continue
        fi

        if [ -e "$target" ] || [ -L "$target" ]; then
            # 기존 심링크/디렉토리 제거 후 재생성
            rm -rf "$target"
        fi

        create_link "$source" "$target"
        installed=$((installed + 1))
    done

    echo -e "  ${GREEN}[OK]${NC} 스킬 ${installed}개 설치 완료 (스킵 ${skipped}개)"
}

install_bmad_config() {
    local target="$PROJECT_DIR/_bmad"
    local source="$BMAD_DIR/_bmad"

    if [ ! -d "$source" ]; then
        echo -e "  ${YELLOW}[!]${NC} _bmad 디렉토리를 찾을 수 없습니다"
        return 1
    fi

    [ -e "$target" ] || [ -L "$target" ] && rm -rf "$target"
    create_link "$source" "$target"
    echo -e "  ${GREEN}[OK]${NC} _bmad 설정 링크 완료"
}

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

# ─── 프로파일 저장/로드 ──────────────────────────────

save_profile() {
    local frameworks_json="$1"
    local subcategories_json="$2"
    local skill_count="$3"

    local version
    version=$(cat "$VERSION_FILE" 2>/dev/null | tr -d '[:space:]' || echo "unknown")
    local platform="unknown"
    case "$OSTYPE" in
        darwin*)  platform="darwin" ;;
        linux*)   platform="linux" ;;
        msys*|cygwin*|mingw*) platform="windows" ;;
    esac
    local today
    today=$(date +%Y-%m-%d)

    # MCP 상태 JSON
    local mcp_json="{"
    local first=true
    for name in "Notion" "Slack" "Google Calendar" "Gmail" "Linear" "Figma" "GitHub"; do
        local key
        key=$(echo "$name" | tr '[:upper:]' '[:lower:]' | tr ' ' '_')
        local val="false"
        [ "${MCP_STATUS[$name]}" = "connected" ] && val="true"
        if [ "$first" = true ]; then
            first=false
        else
            mcp_json+=","
        fi
        mcp_json+="\"$key\":$val"
    done
    mcp_json+="}"

    mkdir -p "$(dirname "$PROFILE_FILE")"
    cat > "$PROFILE_FILE" << EOPROFILE
{
  "installed_at": "$today",
  "rentre_agents_version": "$version",
  "platform": "$platform",
  "link_mode": "$LINK_MODE",
  "mcp": $mcp_json,
  "frameworks": $frameworks_json,
  "bmad_subcategories": $subcategories_json,
  "skill_count": $skill_count
}
EOPROFILE
    echo -e "  ${GREEN}[OK]${NC} 프로파일 저장 → .claude/bmad-profile.json"
}

load_profile() {
    if [ ! -f "$PROFILE_FILE" ]; then
        return 1
    fi

    local skill_count="unknown"
    if command -v jq &>/dev/null; then
        skill_count=$(jq -r '.skill_count // "unknown"' "$PROFILE_FILE" 2>/dev/null)
    else
        skill_count=$(grep '"skill_count"' "$PROFILE_FILE" | sed 's/[^0-9]//g')
    fi

    echo ""
    echo -e "  ${CYAN}이전 설정이 있습니다 (${skill_count}개 스킬)${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} 이전 설정으로 빠른 설치"
    echo -e "  ${GREEN}[2]${NC} 새로 선택"
    echo ""
    echo -ne "  선택 (1/2): "
    read -r choice

    if [ "$choice" = "1" ]; then
        return 0  # 이전 설정 사용
    else
        return 1  # 새로 선택
    fi
}

reinstall_from_profile() {
    if ! command -v jq &>/dev/null; then
        echo -e "  ${RED}[ERROR]${NC} 빠른 설치에는 jq가 필요합니다. 새로 선택해주세요."
        return 1
    fi

    local -a skills_to_install=()

    # 프레임워크별 스킬 수집
    local frameworks
    frameworks=$(jq -r '.frameworks[]' "$PROFILE_FILE" 2>/dev/null)

    while IFS= read -r fw; do
        case "$fw" in
            "bmad-core")
                local subcats
                subcats=$(jq -r '.bmad_subcategories[]' "$PROFILE_FILE" 2>/dev/null)
                while IFS= read -r subcat; do
                    add_bmad_subcategory_skills skills_to_install "$subcat"
                done <<< "$subcats"
                ;;
            "gds")
                local gds_skills
                while IFS= read -r s; do
                    [ -n "$s" ] && collect_skills skills_to_install "$s"
                done < <(for d in "$BMAD_SKILLS_DIR"/gds-*; do [ -d "$d" ] && echo "${d##*/}"; done)
                ;;
            "wds")
                local wds_skills
                while IFS= read -r s; do
                    [ -n "$s" ] && collect_skills skills_to_install "$s"
                done < <(for d in "$BMAD_SKILLS_DIR"/wds*; do [ -d "$d" ] && echo "${d##*/}"; done)
                ;;
            "fsd")
                collect_skills skills_to_install "applying-fsd-architecture"
                ;;
        esac
    done <<< "$frameworks"

    if [ ${#skills_to_install[@]} -eq 0 ]; then
        echo -e "  ${YELLOW}[!]${NC} 프로파일에서 스킬을 복원할 수 없습니다."
        return 1
    fi

    install_skills "${skills_to_install[@]}"
    return 0
}

add_bmad_subcategory_skills() {
    local -n target_arr=$1
    local category="$2"
    case "$category" in
        agents)       collect_skills target_arr "${BMAD_AGENTS[@]}" ;;
        planning)     collect_skills target_arr "${BMAD_PLANNING[@]}" ;;
        development)  collect_skills target_arr "${BMAD_DEVELOPMENT[@]}" ;;
        testing)      collect_skills target_arr "${BMAD_TESTING[@]}" ;;
        architecture) collect_skills target_arr "${BMAD_ARCHITECTURE[@]}" ;;
        business)     collect_skills target_arr "${BMAD_BUSINESS[@]}" ;;
        documentation) collect_skills target_arr "${BMAD_DOCUMENTATION[@]}" ;;
        quality)      collect_skills target_arr "${BMAD_QUALITY[@]}" ;;
        build_tools)  collect_skills target_arr "${BMAD_BUILD_TOOLS[@]}" ;;
        utilities)    collect_skills target_arr "${BMAD_UTILITIES[@]}" ;;
    esac
}

# ─── 기존 스킬 정리 ──────────────────────────────────

cleanup_existing_skills() {
    local target_dir="$PROJECT_DIR/.claude/skills"
    [ -d "$target_dir" ] || return 0

    local removed=0
    local _old_nullglob
    _old_nullglob=$(shopt -p nullglob)
    shopt -s nullglob
    for pattern in bmad-* gds-* wds* applying-fsd-architecture; do
        for item in "$target_dir"/$pattern; do
            rm -rf "$item"
            removed=$((removed + 1))
        done
    done
    $_old_nullglob

    if [ "$removed" -gt 0 ]; then
        echo -e "  ${DIM}기존 스킬 ${removed}개 정리 완료${NC}"
    fi
}

# ─── 설치 검증 ────────────────────────────────────────

verify_installation() {
    echo ""
    echo -e "  ${BOLD}📋 설치 검증${NC}"
    echo -e "  ─────────────────────────────"

    local errors=0

    # 글로벌 커맨드 확인
    local global_dir="$HOME/.claude/commands/rentre"
    for cmd in "${GLOBAL_COMMANDS[@]}"; do
        if [ -f "$global_dir/$cmd" ]; then
            echo -e "  ${GREEN}✅${NC} 글로벌: $cmd"
        else
            echo -e "  ${RED}❌${NC} 글로벌: $cmd (누락)"
            errors=$((errors + 1))
        fi
    done

    # 프로젝트 커맨드 확인
    local proj_cmd_dir="$PROJECT_DIR/.claude/commands/rentre"
    if [ -d "$proj_cmd_dir" ]; then
        for cmd in "${PROJECT_COMMANDS[@]}"; do
            if [ -f "$proj_cmd_dir/$cmd" ]; then
                echo -e "  ${GREEN}✅${NC} 프로젝트 커맨드: $cmd"
            else
                echo -e "  ${RED}❌${NC} 프로젝트 커맨드: $cmd (누락)"
                errors=$((errors + 1))
            fi
        done
    fi

    # 스킬 심링크 확인 (깨진 링크 검사)
    local skills_dir="$PROJECT_DIR/.claude/skills"
    local broken=0
    if [ -d "$skills_dir" ]; then
        for link in "$skills_dir"/*; do
            [ -L "$link" ] || continue
            if [ ! -e "$link" ]; then
                echo -e "  ${RED}❌${NC} 깨진 심링크: $(basename "$link")"
                broken=$((broken + 1))
                errors=$((errors + 1))
            fi
        done
        if [ "$broken" -eq 0 ]; then
            local skill_count
            skill_count=$(ls -d "$skills_dir"/* 2>/dev/null | wc -l | tr -d ' ')
            echo -e "  ${GREEN}✅${NC} 스킬 심링크 ${skill_count}개 정상"
        fi
    fi

    # _bmad 확인
    if [ -e "$PROJECT_DIR/_bmad" ]; then
        echo -e "  ${GREEN}✅${NC} _bmad 설정"
    fi

    # 프로파일 확인
    if [ -f "$PROFILE_FILE" ]; then
        echo -e "  ${GREEN}✅${NC} 프로파일 저장됨"
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

    # 프로젝트 스킬 제거
    local skills_dir="$PROJECT_DIR/.claude/skills"
    if [ -d "$skills_dir" ]; then
        local _old_nullglob
        _old_nullglob=$(shopt -p nullglob)
        shopt -s nullglob
        for pattern in bmad-* gds-* wds* applying-fsd-architecture; do
            for item in "$skills_dir"/$pattern; do
                rm -rf "$item"
            done
        done
        $_old_nullglob
        echo -e "  ${GREEN}[OK]${NC} 프로젝트 스킬 제거"
    fi

    # 프로젝트 커맨드 제거
    local proj_cmd_dir="$PROJECT_DIR/.claude/commands/rentre"
    if [ -d "$proj_cmd_dir" ]; then
        rm -rf "$proj_cmd_dir"
        echo -e "  ${GREEN}[OK]${NC} 프로젝트 커맨드 제거"
    fi

    # _bmad 제거
    [ -e "$PROJECT_DIR/_bmad" ] || [ -L "$PROJECT_DIR/_bmad" ] && rm -rf "$PROJECT_DIR/_bmad"
    echo -e "  ${GREEN}[OK]${NC} _bmad 제거"

    # 프로파일 제거
    [ -f "$PROFILE_FILE" ] && rm -f "$PROFILE_FILE"
    echo -e "  ${GREEN}[OK]${NC} 프로파일 제거"

    # 글로벌 커맨드 제거 여부
    echo ""
    echo -ne "  글로벌 커맨드도 제거하시겠습니까? [y/N]: "
    read -r remove_global
    if [[ "$remove_global" =~ ^[yY]$ ]]; then
        rm -rf "$HOME/.claude/commands/rentre"
        echo -e "  ${GREEN}[OK]${NC} 글로벌 커맨드 제거"
    fi

    echo ""
    echo -e "  ${GREEN}제거 완료${NC}"
    exit 0
}

# ─── 프리셋 처리 ─────────────────────────────────────

get_preset_config() {
    local preset="$1"
    case "$preset" in
        backend)
            PRESET_FRAMEWORKS='["bmad-core"]'
            PRESET_SUBCATS='["agents","planning","development","testing","architecture"]'
            PRESET_CATEGORIES=(agents planning development testing architecture)
            ;;
        frontend)
            PRESET_FRAMEWORKS='["bmad-core","fsd"]'
            PRESET_SUBCATS='["agents","planning","development","architecture"]'
            PRESET_CATEGORIES=(agents planning development architecture)
            PRESET_EXTRA_FW=("fsd")
            ;;
        pm)
            PRESET_FRAMEWORKS='["bmad-core"]'
            PRESET_SUBCATS='["agents","planning","business","documentation"]'
            PRESET_CATEGORIES=(agents planning business documentation)
            ;;
        gamedev)
            PRESET_FRAMEWORKS='["gds"]'
            PRESET_SUBCATS='[]'
            PRESET_CATEGORIES=()
            PRESET_EXTRA_FW=("gds")
            ;;
        full)
            PRESET_FRAMEWORKS='["bmad-core","gds","wds","fsd"]'
            PRESET_SUBCATS='["agents","planning","development","testing","architecture","business","documentation","quality","build_tools","utilities"]'
            PRESET_CATEGORIES=(agents planning development testing architecture business documentation quality build_tools utilities)
            PRESET_EXTRA_FW=("gds" "wds" "fsd")
            ;;
        *)
            echo -e "${RED}[ERROR]${NC} 알 수 없는 프리셋: $preset"
            echo "사용 가능: backend, frontend, pm, gamedev, full"
            exit 1
            ;;
    esac
}

# ─── 메인 ─────────────────────────────────────────────

main() {
    local PRESET=""
    local GLOBAL_ONLY=false
    local DO_REMOVE=false
    LINK_MODE="${LINK_MODE:-symlink}"

    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            --preset)
                if [ -z "${2:-}" ]; then
                    echo -e "${RED}[ERROR]${NC} --preset 뒤에 값이 필요합니다"
                    echo "사용 가능: backend, frontend, pm, gamedev, full"
                    exit 1
                fi
                PRESET="$2"
                shift 2
                ;;
            --global-only)
                GLOBAL_ONLY=true
                shift
                ;;
            --remove)
                DO_REMOVE=true
                shift
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
    if [ "$PROJECT_DIR" = "$HOME" ]; then
        echo -e "  ${YELLOW}⚠️  홈 디렉토리에 설치하면 글로벌처럼 동작합니다.${NC}"
        echo -ne "  계속하시겠습니까? [y/N]: "
        read -r confirm
        if [[ ! "$confirm" =~ ^[yY]$ ]]; then
            echo "  설치를 취소합니다."
            exit 0
        fi
    fi

    # .git 존재 확인
    if [ ! -d "$PROJECT_DIR/.git" ] && [ "$GLOBAL_ONLY" = false ]; then
        echo -e "  ${YELLOW}⚠️  현재 디렉토리에 .git이 없습니다.${NC}"
        echo -e "  프로젝트 루트에서 실행해주세요."
        echo -ne "  무시하고 계속하시겠습니까? [y/N]: "
        read -r confirm
        if [[ ! "$confirm" =~ ^[yY]$ ]]; then
            exit 0
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
                echo -ne "  계속하시겠습니까? [y/N]: "
                read -r confirm
                if [[ ! "$confirm" =~ ^[yY]$ ]]; then
                    exit 0
                fi
                ;;
        esac
    fi

    # BMAD submodule 확인
    if [ ! -d "$BMAD_DIR" ] || [ ! -d "$BMAD_SKILLS_DIR" ]; then
        echo -e "  ${YELLOW}[!]${NC} BMAD submodule이 초기화되지 않았습니다."
        echo -e "  실행: ${CYAN}cd $REPO_DIR && git submodule update --init --recursive${NC}"
        if [ "$GLOBAL_ONLY" = false ]; then
            echo -ne "  글로벌 커맨드만 설치하시겠습니까? [Y/n]: "
            read -r fallback
            if [[ "$fallback" =~ ^[nN]$ ]]; then
                exit 1
            fi
            GLOBAL_ONLY=true
        fi
    fi

    # MCP 감지
    detect_mcp

    # ─── Step 1: 글로벌 커맨드 설치 ──────────────
    echo -e "  ${CYAN}${BOLD}[1/3] 글로벌 커맨드 설치${NC}"
    install_global_commands
    echo ""

    if [ "$GLOBAL_ONLY" = true ]; then
        echo -e "  ${GREEN}글로벌 커맨드 설치 완료${NC}"
        echo ""
        echo "  시작하기: /rentre:help"
        exit 0
    fi

    # ─── Step 2: 프로젝트 스킬 설치 ──────────────
    echo -e "  ${CYAN}${BOLD}[2/3] 프로젝트 스킬 설치${NC}"

    local -a selected_skills=()
    local frameworks_json='[]'
    local subcategories_json='[]'
    local -a selected_frameworks=()
    local -a selected_subcats=()

    # 이전 프로파일 확인
    local use_previous=false
    if [ -z "$PRESET" ] && [ -f "$PROFILE_FILE" ]; then
        if load_profile; then
            use_previous=true
        fi
    fi

    if [ "$use_previous" = true ]; then
        cleanup_existing_skills
        if reinstall_from_profile; then
            # 프로파일에서 JSON 값 읽기
            if command -v jq &>/dev/null; then
                frameworks_json=$(jq -c '.frameworks' "$PROFILE_FILE" 2>/dev/null || echo '[]')
                subcategories_json=$(jq -c '.bmad_subcategories' "$PROFILE_FILE" 2>/dev/null || echo '[]')
            fi
        else
            use_previous=false
        fi
    fi

    if [ "$use_previous" = false ]; then
        cleanup_existing_skills

        if [ -n "$PRESET" ]; then
            # ─── 프리셋 모드 ─────────────────
            echo -e "  프리셋: ${GREEN}${PRESET}${NC}"
            get_preset_config "$PRESET"

            for cat in "${PRESET_CATEGORIES[@]+"${PRESET_CATEGORIES[@]}"}"; do
                add_bmad_subcategory_skills selected_skills "$cat"
            done

            # 추가 프레임워크
            for fw in "${PRESET_EXTRA_FW[@]+"${PRESET_EXTRA_FW[@]}"}"; do
                case "$fw" in
                    gds)
                        while IFS= read -r s; do
                            [ -n "$s" ] && collect_skills selected_skills "$s"
                        done < <(for d in "$BMAD_SKILLS_DIR"/gds-*; do [ -d "$d" ] && echo "${d##*/}"; done)
                        ;;
                    wds)
                        while IFS= read -r s; do
                            [ -n "$s" ] && collect_skills selected_skills "$s"
                        done < <(for d in "$BMAD_SKILLS_DIR"/wds*; do [ -d "$d" ] && echo "${d##*/}"; done)
                        ;;
                    fsd)
                        collect_skills selected_skills "applying-fsd-architecture"
                        ;;
                esac
            done

            frameworks_json="$PRESET_FRAMEWORKS"
            subcategories_json="$PRESET_SUBCATS"

        else
            # ─── 대화형 메뉴 ─────────────────
            show_framework_menu
            read -r fw_input
            if [ -z "$fw_input" ]; then
                echo -e "  ${YELLOW}[!]${NC} 선택이 필요합니다. 다시 시도해주세요."
                echo ""
                show_framework_menu
                read -r fw_input
            fi

            local -a fw_selections
            IFS=' ' read -ra fw_selections <<< "$(parse_selections "$fw_input")"

            for sel in "${fw_selections[@]}"; do
                case "$sel" in
                    1|bmad)
                        selected_frameworks+=("bmad-core")
                        # BMAD 서브카테고리 메뉴
                        show_bmad_subcategory_menu
                        read -r sub_input

                        local -a sub_selections
                        IFS=' ' read -ra sub_selections <<< "$(parse_selections "$sub_input")"

                        for sub in "${sub_selections[@]}"; do
                            case "$sub" in
                                1) selected_subcats+=("agents");       add_bmad_subcategory_skills selected_skills "agents" ;;
                                2) selected_subcats+=("planning");     add_bmad_subcategory_skills selected_skills "planning" ;;
                                3) selected_subcats+=("development");  add_bmad_subcategory_skills selected_skills "development" ;;
                                4) selected_subcats+=("testing");      add_bmad_subcategory_skills selected_skills "testing" ;;
                                5) selected_subcats+=("architecture"); add_bmad_subcategory_skills selected_skills "architecture" ;;
                                6) selected_subcats+=("business");     add_bmad_subcategory_skills selected_skills "business" ;;
                                7) selected_subcats+=("documentation"); add_bmad_subcategory_skills selected_skills "documentation" ;;
                                8) selected_subcats+=("quality");      add_bmad_subcategory_skills selected_skills "quality" ;;
                                9) selected_subcats+=("build_tools");  add_bmad_subcategory_skills selected_skills "build_tools" ;;
                                0) selected_subcats+=("utilities");    add_bmad_subcategory_skills selected_skills "utilities" ;;
                                [aA])
                                    selected_subcats=("agents" "planning" "development" "testing" "architecture" "business" "documentation" "quality" "build_tools" "utilities")
                                    for cat in "${selected_subcats[@]}"; do
                                        add_bmad_subcategory_skills selected_skills "$cat"
                                    done
                                    ;;
                            esac
                        done
                        ;;
                    2|gds)
                        selected_frameworks+=("gds")
                        while IFS= read -r s; do
                            [ -n "$s" ] && collect_skills selected_skills "$s"
                        done < <(for d in "$BMAD_SKILLS_DIR"/gds-*; do [ -d "$d" ] && echo "${d##*/}"; done)
                        ;;
                    3|wds)
                        selected_frameworks+=("wds")
                        while IFS= read -r s; do
                            [ -n "$s" ] && collect_skills selected_skills "$s"
                        done < <(for d in "$BMAD_SKILLS_DIR"/wds*; do [ -d "$d" ] && echo "${d##*/}"; done)
                        ;;
                    4|fsd)
                        selected_frameworks+=("fsd")
                        collect_skills selected_skills "applying-fsd-architecture"
                        ;;
                    [aA])
                        selected_frameworks=("bmad-core" "gds" "wds" "fsd")
                        selected_subcats=("agents" "planning" "development" "testing" "architecture" "business" "documentation" "quality" "build_tools" "utilities")
                        for cat in "${selected_subcats[@]}"; do
                            add_bmad_subcategory_skills selected_skills "$cat"
                        done
                        while IFS= read -r s; do
                            [ -n "$s" ] && collect_skills selected_skills "$s"
                        done < <(for d in "$BMAD_SKILLS_DIR"/gds-*; do [ -d "$d" ] && echo "${d##*/}"; done)
                        while IFS= read -r s; do
                            [ -n "$s" ] && collect_skills selected_skills "$s"
                        done < <(for d in "$BMAD_SKILLS_DIR"/wds*; do [ -d "$d" ] && echo "${d##*/}"; done)
                        collect_skills selected_skills "applying-fsd-architecture"
                        ;;
                esac
            done

            # JSON 배열 빌드
            frameworks_json="["
            local first=true
            for fw in "${selected_frameworks[@]+"${selected_frameworks[@]}"}"; do
                if [ "$first" = true ]; then first=false; else frameworks_json+=","; fi
                frameworks_json+="\"$fw\""
            done
            frameworks_json+="]"

            subcategories_json="["
            first=true
            for sc in "${selected_subcats[@]+"${selected_subcats[@]}"}"; do
                if [ "$first" = true ]; then first=false; else subcategories_json+=","; fi
                subcategories_json+="\"$sc\""
            done
            subcategories_json+="]"
        fi

        # 스킬 설치
        if [ ${#selected_skills[@]} -gt 0 ]; then
            install_skills "${selected_skills[@]}"
        else
            echo -e "  ${YELLOW}[!]${NC} 선택된 스킬이 없습니다."
        fi
    fi

    # _bmad 설정
    install_bmad_config
    echo ""

    # ─── Step 3: 프로젝트 커맨드 + 마무리 ────────
    echo -e "  ${CYAN}${BOLD}[3/3] 프로젝트 커맨드 + 프로파일 저장${NC}"
    install_project_commands

    # 스킬 수 계산
    local final_skill_count
    final_skill_count=$(ls -d "$PROJECT_DIR/.claude/skills"/* 2>/dev/null | wc -l | tr -d ' ')

    # 프로파일 저장
    save_profile "$frameworks_json" "$subcategories_json" "$final_skill_count"

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

    echo -e "  Rentre Agents ${GREEN}v${version}${NC} 설치 완료 (${final_skill_count}개 스킬)"
    echo ""
    echo -e "  시작하기:    ${CYAN}/rentre:help${NC}"
    echo -e "  BMAD 가이드: ${CYAN}/bmad-help${NC}"
    echo ""
}

main "$@"
