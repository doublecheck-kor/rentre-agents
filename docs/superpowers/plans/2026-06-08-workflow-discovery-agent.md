# 워크플로우 발굴 에이전트 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Slack·Notion·캘린더·Git의 반복 업무 패턴을 주 1회 발굴해 ROI 추정과 함께 자동화 후보를 정재우 DM으로 제안하는 멀티에이전트 크론을 구축한다 (제안만, HITL 100%).

**Architecture:** 기존 cron-prompts 패턴 위에 단일 오케스트레이터 프롬프트(`workflow-discovery.md`)를 추가한다. 오케스트레이터는 `Task` 도구로 4개 스캐너 서브에이전트를 병렬 dispatch(fan-out)하고, 반환된 신호 JSON을 클러스터링·점수화(synthesis)하여 Slack 리포트를 만든다. `harness-run`으로 래핑해 기존 observability에 편입한다.

**Tech Stack:** Claude Code CLI (`claude -p`), MCP(Slack/Notion/Google Calendar), `gh` CLI, harness(Python CLI), bash cron, sed 렌더링.

---

## 도메인 노트 (구현자 필독)

이 저장소의 크론 에이전트는 **코드가 아니라 프롬프트**다. 동작 검증은 단위테스트가 아니라 "렌더 → 드라이런 실행 → 출력 확인"으로 한다.

- **템플릿/렌더 규약**: `cron-prompts/<name>.md`는 `{{PLACEHOLDER}}`를 포함한 템플릿(git 추적). `cron-prompts/<name>.rendered.md`는 config 값으로 치환된 실행본(**.gitignore됨**). 기존 3개(`market-news`, `daily-briefing`, `adr-monitor`)와 동일 규약을 따른다.
- **현재 알려진 placeholder**: `{{SLACK_DM_CHANNEL}}`(= `D07S7RE6TK4`), `{{NOTION_USER_ID}}`(= `121d872b-594c-81ce-bec2-00027566bb0d`). 값은 `config.example.json` 스키마의 `slack_dm_channel`, `notion_user_id`에 대응.
- **크론 등록**: `scripts/setup-cron-agents.sh`가 `crontab`에 `# rentre-cron-<name>` 마커로 항목을 등록/제거한다.
- **harness**: `harness-run <job> [--no-alert] [--timeout N] -- <cmd>`로 래핑. `--no-alert`는 shadow phase(알림 없이 기록만). 자동화 내부에서 `harness-heartbeat report --status ok --summary ...`로 자기보고.
- **참조 설계 문서**: `docs/superpowers/specs/2026-06-08-workflow-discovery-agent-design.md`

---

## File Structure

| 파일 | 책임 | 신규/수정 |
|------|------|-----------|
| `cron-prompts/workflow-discovery.md` | 오케스트레이터 프롬프트 템플릿 (fan-out 지시 + 스캐너 4종 인라인 지시문 + synthesis 로직 + 리포트 포맷 + DRY_RUN 토글) | 신규 |
| `scripts/render-discovery.sh` | 개발/검증용 수동 렌더 스크립트 (`.md` → `.rendered.md`, sed 치환) | 신규 |
| `scripts/setup-cron-agents.sh` | 금요일 16:00 크론 항목 1줄 추가 + 안내 문구 | 수정 |
| `cron-prompts/workflow-discovery.rendered.md` | 렌더 산출물 (gitignore, render 스크립트가 생성) | 생성물 |
| `~/.harness/discovery-history.jsonl` | 주차별 제안 패턴 기록 (중복 추적, 프롬프트가 Read/Write) | 런타임 생성 |
| `CLAUDE.md` / `README.md` / `VERSION` | 크론 자동화 표·커맨드 목록·버전 갱신 | 수정 |

프롬프트는 단일 파일로 둔다(스캐너 분리 안 함) — 기존 cron-prompts 패턴 일관성, `claude -p`가 단일 프롬프트를 받는 구조와 정합.

---

## Task 1: 오케스트레이터 프롬프트 골격 + 실행 흐름

**Files:**
- Create: `cron-prompts/workflow-discovery.md`

- [ ] **Step 1: 프롬프트 골격 작성**

`cron-prompts/workflow-discovery.md` 생성. 아래 전체 내용을 그대로 작성:

```markdown
워크플로우 발굴 에이전트 역할을 수행하세요. 직원들의 공개 업무 활동에서 반복 패턴을 찾아 자동화 후보를 제안합니다.

## 원칙
- 관찰 범위: **공개 영역만** — 공개 Slack 채널, 회사 Notion, 회사 GitHub 조직 레포, 정재우 본인 캘린더. DM·비공개 채널·개인 메일·타인 캘린더는 절대 보지 마세요.
- 개인 식별: 리포트 본문에 **실명을 쓰지 마세요**. "마케팅팀 N명" 같은 집계/익명으로만 표기합니다. 실명이 필요하면 evidence 링크로 대체합니다.
- 목적: 사람 평가가 아니라 자동화 후보 발굴입니다.
- 관찰 윈도우: **지난 7일**.

## 작업 흐름

### 1단계: 스캐너 병렬 dispatch (fan-out)
Task 도구로 아래 4개 스캐너 서브에이전트를 **병렬로** 실행하세요. 각 스캐너는 자기 소스만 관찰하고, §신호 스키마에 맞는 JSON 배열만 반환합니다. (스캐너 지시문은 §스캐너 정의 참조)

### 2단계: 신호 취합 → 클러스터링 → 우선순위 점수화 (synthesis)
(§우선순위 점수화 참조)

### 3단계: 중복 추적
(§중복 추적 참조)

### 4단계: 리포트 생성 및 전송
(§리포트 포맷 참조)

### 5단계: 자기보고
실행 종료 직전 아래를 Bash로 실행:
\`\`\`
command -v harness-heartbeat >/dev/null 2>&1 && \
  harness-heartbeat report --status ok \
    --summary "워크플로우 발굴 리포트 발송" \
    --detail signals=<수집신호수> --detail candidates=<후보수> || true
\`\`\`

## DRY_RUN 토글
{{DRY_RUN}}
DRY_RUN이 "true"이면 Slack 전송 대신 리포트 전문을 stdout으로 출력하고 종료하세요.
```

> 이후 Task에서 `§스캐너 정의`, `§우선순위 점수화`, `§중복 추적`, `§리포트 포맷` 섹션을 이 파일에 채운다.

- [ ] **Step 2: 구조 검증 (placeholder·섹션 존재 확인)**

Run:
```bash
grep -c '{{SLACK_DM_CHANNEL}}\|{{NOTION_USER_ID}}\|{{DRY_RUN}}' cron-prompts/workflow-discovery.md; \
grep -n '### .*단계' cron-prompts/workflow-discovery.md
```
Expected: placeholder grep이 0이 아닌 값(아직 SLACK/NOTION placeholder는 리포트 섹션에서 추가되므로 최소 `{{DRY_RUN}}` 1개 매치), 5개 단계 헤더 출력.

- [ ] **Step 3: Commit**

```bash
git add cron-prompts/workflow-discovery.md
git commit -m "feat: 워크플로우 발굴 프롬프트 골격 + 실행 흐름"
```

---

## Task 2: 스캐너 4종 인라인 지시문 + 신호 스키마

**Files:**
- Modify: `cron-prompts/workflow-discovery.md` (`## 스캐너 정의` 섹션 추가)

- [ ] **Step 1: 신호 스키마 + 스캐너 지시문 추가**

`cron-prompts/workflow-discovery.md` 끝에 아래 섹션 추가:

```markdown
## 스캐너 정의

각 스캐너는 아래 신호 스키마 배열만 반환합니다. 신호가 없으면 빈 배열 `[]`을 반환하세요 (실패 아님).

### 신호 스키마
\`\`\`json
{
  "source": "slack|notion|calendar|git",
  "pattern": "반복되는 업무 한 줄 서술",
  "evidence": ["근거 링크/인용 1", "근거 2"],
  "frequency": 5,
  "actors_count": 3,
  "team_hint": "마케팅|개발|영업|운영|...",
  "est_minutes_each": 15
}
\`\`\`

### slack-scanner
- 사용 도구: Slack 도구만 (slack_search_*, slack_read_channel). 다른 소스 도구 사용 금지.
- 공개 채널만. DM·비공개 채널 제외.
- 반복 신호: 동일·유사 질문 반복, "이거 누가 해줘"류 수동 요청, 같은 정보 반복 검색/공유.

### notion-scanner
- 사용 도구: Notion 도구만 (notion-search, notion-fetch).
- 회사 워크스페이스만.
- 반복 신호: 동일 템플릿 문서 반복 생성, 정형 리포트·백로그 수기 작성, 같은 속성 반복 업데이트.

### calendar-scanner
- 사용 도구: Google Calendar 도구만 (list_events).
- 정재우 본인 캘린더만.
- 반복 신호: 반복 회의(특히 정보 동기화성), 정형 일정 조율 패턴.

### git-scanner
- 사용 도구: gh CLI만 (Bash). 회사 GitHub 조직 레포의 지난 7일 PR/리뷰 활동 조회.
- 반복 신호: 반복되는 PR 유형, 같은 리뷰 코멘트 반복, 정형 커밋 관습.
- 예: `gh search prs --owner <org> --created '>=<7일전>' --json title,labels,author` 등.
```

- [ ] **Step 2: 스캐너 4종·스키마 키 일관성 검증**

Run:
```bash
grep -c 'scanner' cron-prompts/workflow-discovery.md; \
grep -o '"[a-z_]*":' cron-prompts/workflow-discovery.md | sort -u
```
Expected: scanner 4종 이상 매치. 스키마 키에 `"source": "pattern": "evidence": "frequency": "actors_count": "team_hint": "est_minutes_each":` 모두 존재.

- [ ] **Step 3: Commit**

```bash
git add cron-prompts/workflow-discovery.md
git commit -m "feat: 스캐너 4종 인라인 지시문 + 신호 스키마"
```

---

## Task 3: synthesis — 클러스터링 + 우선순위 점수화 + 중복 추적

**Files:**
- Modify: `cron-prompts/workflow-discovery.md` (`## 우선순위 점수화`, `## 중복 추적` 섹션 추가)

- [ ] **Step 1: 점수화·중복추적 섹션 추가**

`cron-prompts/workflow-discovery.md` 끝에 추가:

```markdown
## 우선순위 점수화

스캐너 신호를 의미 단위로 클러스터링(유사 패턴 병합)한 뒤, 클러스터마다 점수를 계산하세요.

\`\`\`
weekly_minutes_saved = frequency × est_minutes_each
reach_factor       = (영향 범위) 1명=1.0, 1팀=1.5, 전사=2.0
feasibility_factor = (구현 난이도) 상(기존 패턴 재사용)=1.5, 중(신규 커맨드)=1.0, 하(외부 연동)=0.6
priority_score     = weekly_minutes_saved × reach_factor × feasibility_factor
\`\`\`

priority_score 내림차순 Top 5만 리포트에 포함합니다.

## 중복 추적

- 이력 파일: `~/.harness/discovery-history.jsonl` (없으면 빈 것으로 간주).
- 각 줄: `{"week": "2026-W24", "pattern_key": "<정규화한 패턴 키>"}`.
- Read 도구로 이 파일을 읽어, 이번 Top 5 중 과거 등장한 pattern_key는 연속 등장 주차 수를 세어 `🔁 N주 연속 등장`으로 표기하세요.
- 리포트 전송(또는 DRY_RUN 출력) 후, 이번 Top 5의 pattern_key를 이번 주차로 Write 도구로 append 하세요.
```

- [ ] **Step 2: 점수 공식 키 일관성 검증**

Run:
```bash
grep -o 'weekly_minutes_saved\|reach_factor\|feasibility_factor\|priority_score\|pattern_key\|discovery-history.jsonl' cron-prompts/workflow-discovery.md | sort | uniq -c
```
Expected: `weekly_minutes_saved`, `reach_factor`, `feasibility_factor`, `priority_score` 각 2회 이상(정의+공식), `pattern_key` 2회 이상, `discovery-history.jsonl` 2회(이력 파일 경로). Task 1 5단계의 heartbeat detail 키(`signals`, `candidates`)와 모순 없음.

- [ ] **Step 3: Commit**

```bash
git add cron-prompts/workflow-discovery.md
git commit -m "feat: synthesis 점수화 + 중복 추적 로직"
```

---

## Task 4: Slack 리포트 포맷 + DRY_RUN 분기

**Files:**
- Modify: `cron-prompts/workflow-discovery.md` (`## 리포트 포맷` 섹션 추가)

- [ ] **Step 1: 리포트 포맷 섹션 추가**

`cron-prompts/workflow-discovery.md` 끝에 추가:

```markdown
## 리포트 포맷

전송 대상: channel_id `{{SLACK_DM_CHANNEL}}`, 도구 `mcp__claude_ai_Slack__slack_send_message`.
Slack mrkdwn 형식. DRY_RUN이 true면 전송하지 말고 아래 전문을 stdout 출력.

\`\`\`
:mag: *워크플로우 발굴 리포트* | {YYYY.MM.DD} ({요일}) | 지난 7일
스캔 신호 {N}개 → 자동화 후보 {M}건 | 총 절감 추정 ~{H}시간/주

*1. [{패턴 제목}]*  ⏱ ~{분}분/주  👥 {팀 N명}  🔧 난이도: {상|중|하}
   → {무엇이 반복되는지 + 어떻게 자동화 가능한지 1-2줄}
   📎 evidence: {링크들}  {🔁 N주 연속 등장 (해당 시)}

... (priority_score 상위 Top 5)

:bulb: 만들고 싶은 후보가 있으면 알려주세요 — 레시피 초안을 만들어 드립니다.
\`\`\`

- 신호가 0개면: "이번 주 발굴된 반복 패턴이 없습니다" 1줄만 전송.
- 일부 스캐너 실패 시: 리포트 하단에 `⚠️ {source} 신호 수집 실패` 주석 추가하고 나머지로 리포트 생성(graceful degradation).
```

- [ ] **Step 2: SLACK placeholder·전송 도구 검증**

Run:
```bash
grep -c '{{SLACK_DM_CHANNEL}}' cron-prompts/workflow-discovery.md; \
grep -c 'slack_send_message\|graceful\|DRY_RUN' cron-prompts/workflow-discovery.md
```
Expected: `{{SLACK_DM_CHANNEL}}` 1회 이상, 전송/예외 키워드 매치.

- [ ] **Step 3: Commit**

```bash
git add cron-prompts/workflow-discovery.md
git commit -m "feat: Slack 리포트 포맷 + DRY_RUN/graceful degradation"
```

---

## Task 5: 렌더 스크립트 작성 + 드라이런 실행 검증

**Files:**
- Create: `scripts/render-discovery.sh`

- [ ] **Step 1: 렌더 스크립트 작성**

`scripts/render-discovery.sh` 생성:

```bash
#!/bin/bash
# workflow-discovery.md → workflow-discovery.rendered.md 렌더 (개발/검증용)
# config 값으로 placeholder 치환. DRY_RUN은 인자로 제어(기본 true).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
PROMPTS="$ROOT/cron-prompts"
CONFIG="${RENTRE_CONFIG:-$ROOT/config.json}"

DRY_RUN="${1:-true}"

# config.json이 있으면 거기서, 없으면 기존 rendered에서 값 추출
get() {  # $1=jq_key  $2=fallback_grep_file
  if [ -f "$CONFIG" ]; then
    python3 -c "import json,sys; print(json.load(open('$CONFIG')).get('$1',''))"
  fi
}
SLACK_DM="$(get slack_dm_channel)"
NOTION_UID="$(get notion_user_id)"

# config가 비었으면 기존 adr-monitor.rendered.md에서 재사용
if [ -z "$SLACK_DM" ] && [ -f "$PROMPTS/adr-monitor.rendered.md" ]; then
  SLACK_DM="$(grep -oE 'channel_id: \S+' "$PROMPTS/adr-monitor.rendered.md" | head -1 | awk '{print $2}')"
  NOTION_UID="$(grep -oE 'Notion user ID: \S+' "$PROMPTS/adr-monitor.rendered.md" | head -1 | awk '{print $4}')"
fi

sed -e "s|{{SLACK_DM_CHANNEL}}|${SLACK_DM}|g" \
    -e "s|{{NOTION_USER_ID}}|${NOTION_UID}|g" \
    -e "s|{{DRY_RUN}}|DRY_RUN=${DRY_RUN}|g" \
    "$PROMPTS/workflow-discovery.md" > "$PROMPTS/workflow-discovery.rendered.md"

echo "Rendered → $PROMPTS/workflow-discovery.rendered.md (DRY_RUN=${DRY_RUN})"
```

- [ ] **Step 2: 실행 권한 + 렌더 실행**

Run:
```bash
chmod +x scripts/render-discovery.sh && ./scripts/render-discovery.sh true && \
  grep -c '{{' cron-prompts/workflow-discovery.rendered.md
```
Expected: "Rendered → ..." 출력, 마지막 grep 결과 `0` (치환되지 않은 placeholder 없음).

- [ ] **Step 3: 드라이런 실제 실행 (LLM 호출 — 사람 확인 필요)**

Run:
```bash
claude -p "$(cat cron-prompts/workflow-discovery.rendered.md)" \
  --allowedTools 'Task,Bash(git log:*),Bash(gh:*),mcp__claude_ai_Slack__*,mcp__claude_ai_Notion__*,mcp__claude_ai_Google_Calendar__*,Read,Write' \
  2>&1 | tee /tmp/discovery-dryrun.log
```
Expected (사람이 확인): Slack 전송 없이 stdout에 리포트 전문 출력. 4개 스캐너가 Task로 병렬 실행됨. 신호 0개여도 "발굴된 반복 패턴 없음" 출력이면 정상. 권한 부족·도구 오류가 있으면 로그에서 원인 확인 후 프롬프트 보정.

> 이 단계는 실제 데이터·MCP 인증에 의존한다. 실패 시 어느 스캐너가 막혔는지 로그로 진단하고 해당 스캐너 지시문(권한·쿼리)을 고친 뒤 Step 2부터 반복.

- [ ] **Step 4: Commit**

```bash
git add scripts/render-discovery.sh
git commit -m "feat: 발굴 프롬프트 렌더 스크립트 + 드라이런 검증"
```

---

## Task 6: 중복 추적 동작 검증

**Files:**
- (검증만, 코드 변경 없음. 필요 시 `cron-prompts/workflow-discovery.md` 보정)

- [ ] **Step 1: 이력 파일 초기 상태 준비**

Run:
```bash
mkdir -p ~/.harness && rm -f ~/.harness/discovery-history.jsonl && echo "history cleared"
```
Expected: "history cleared".

- [ ] **Step 2: 1회차 드라이런 → 이력 기록 확인**

Run:
```bash
claude -p "$(cat cron-prompts/workflow-discovery.rendered.md)" \
  --allowedTools 'Task,Bash(git log:*),Bash(gh:*),mcp__claude_ai_Slack__*,mcp__claude_ai_Notion__*,mcp__claude_ai_Google_Calendar__*,Read,Write' >/dev/null 2>&1; \
  wc -l ~/.harness/discovery-history.jsonl 2>/dev/null || echo "no history written"
```
Expected (사람이 확인): 신호가 있었다면 `discovery-history.jsonl`에 pattern_key 줄들이 append됨. 신호 0개였다면 빈 파일/미생성 — 정상. 줄이 기록됐으면 `🔁` 표기 로직이 다음 회차에 작동할 준비 완료.

- [ ] **Step 3: (선택) 2회차 실행 → 🔁 표기 확인**

신호가 있는 환경이라면 한 번 더 실행해 동일 패턴에 `🔁 2주 연속 등장` 표기가 stdout에 나타나는지 사람이 확인. 나타나지 않으면 `## 중복 추적` 지시문의 pattern_key 정규화/비교 로직을 보정하고 Task 5 Step 2부터 반복.

- [ ] **Step 4: Commit (보정이 있었던 경우만)**

```bash
git add cron-prompts/workflow-discovery.md
git commit -m "fix: 중복 추적 pattern_key 비교 보정"
```

---

## Task 7: 크론 등록 (shadow phase — 알림 없이)

**Files:**
- Modify: `scripts/setup-cron-agents.sh`

- [ ] **Step 1: 마커 변수 추가**

`scripts/setup-cron-agents.sh`에서 마커 변수 블록을 찾아 아래 줄을 추가:

기존:
```bash
MARKER_ADR="# rentre-cron-adr"
```
직후에 추가:
```bash
MARKER_DISCOVERY="# rentre-cron-discovery"
```

- [ ] **Step 2: 크론 항목 추가 (shadow — `--no-alert`)**

`NEW_CRONS` 변수의 heredoc/문자열에서 ADR 줄(`$MARKER_ADR`로 끝나는 줄) 뒤에 아래 한 줄을 추가:

```bash
0 16 * * 5 cd $AGENT_DIR && harness-run workflow-discovery --no-alert --timeout 900 -- $CLAUDE_BIN -p \"\$(cat $PROMPTS_DIR/workflow-discovery.rendered.md)\" --allowedTools 'Task,Bash(git log:*),Bash(gh:*),mcp__claude_ai_Slack__*,mcp__claude_ai_Notion__*,mcp__claude_ai_Google_Calendar__*,Read,Write' >> $LOGS_DIR/workflow-discovery.log 2>&1 $MARKER_DISCOVERY
```

> ADR 줄이 `"`로 끝나는 마지막 항목이면, ADR 줄 끝의 닫는 `"`를 새 줄 끝으로 옮긴다(기존 3줄 → 4줄로 확장). 즉 ADR 줄 끝 `$MARKER_ADR"` → `$MARKER_ADR` 로 바꾸고 새 discovery 줄 끝에 `$MARKER_DISCOVERY"` 로 닫는다.

- [ ] **Step 3: 안내 문구 추가**

`echo "  ADR 모니터링:     평일 08-20시 매시 :07"` 줄 뒤에 추가:
```bash
echo "  워크플로우 발굴:   매주 금요일 16:00 (shadow)"
```

- [ ] **Step 4: 스크립트 문법 검증 (등록은 하지 않음)**

Run:
```bash
bash -n scripts/setup-cron-agents.sh && echo "syntax OK"
```
Expected: "syntax OK". (실제 `crontab` 등록은 사용자가 배포 시점에 `./scripts/setup-cron-agents.sh`로 수행 — 이 단계에서는 실행하지 않는다.)

- [ ] **Step 5: Commit**

```bash
git add scripts/setup-cron-agents.sh
git commit -m "feat: 워크플로우 발굴 크론 등록 (금 16:00, shadow phase)"
```

---

## Task 8: harness 통합 확인 + active phase 전환 안내

**Files:**
- (검증 + 문서 주석. 코드 변경은 setup 스크립트 주석만)

- [ ] **Step 1: harness 설치 여부 확인**

Run:
```bash
command -v harness-run harness-heartbeat && echo "harness present" || echo "harness 미설치 — pipx install ./tools/harness 필요"
```
Expected: 두 바이너리 경로 출력 또는 설치 안내. 미설치면 `pipx install ./tools/harness` 후 재확인.

- [ ] **Step 2: harness 래핑 스모크 테스트 (실제 발굴 아님)**

Run:
```bash
harness-run workflow-discovery-smoke --no-alert -- echo "smoke ok" && \
  tail -1 ~/.harness/state.jsonl
```
Expected: "smoke ok" 출력 + `~/.harness/state.jsonl`에 close 라인 기록(exit 0). harness가 정상 래핑함을 확인.

- [ ] **Step 3: active phase 전환 방법 주석 추가**

`scripts/setup-cron-agents.sh`의 discovery 안내 문구(`echo "  워크플로우 발굴: ..."`) 위에 주석 추가:
```bash
# shadow phase 검증(2-4주) 후 --no-alert 제거하면 실패 시 Slack 알림 활성화
```

- [ ] **Step 4: Commit**

```bash
git add scripts/setup-cron-agents.sh
git commit -m "docs: harness active phase 전환 안내 주석"
```

---

## Task 9: 문서·버전 갱신 + 최종 정리

**Files:**
- Modify: `CLAUDE.md`, `README.md`, `VERSION`

- [ ] **Step 1: CLAUDE.md 크론 표에 행 추가**

`CLAUDE.md`의 "## 크론 자동화" 표에서 ADR 행 뒤에 추가:
```markdown
| 매주 금 16:00 | 워크플로우 발굴 (반복 업무 패턴 → 자동화 후보) → Slack DM |
```

- [ ] **Step 2: VERSION 범프**

`VERSION` 파일 내용을 `0.8.4` → `0.9.0`으로 변경 (신규 크론 에이전트 = minor).

Run:
```bash
echo "0.9.0" > VERSION && cat VERSION
```
Expected: `0.9.0`.

- [ ] **Step 3: README 크론/기능 언급 갱신**

`README.md`에서 기존 크론 3종을 소개하는 부분을 찾아 "워크플로우 발굴 (주 1회)" 1줄을 같은 형식으로 추가. (형식은 해당 위치의 기존 항목을 그대로 따른다.)

- [ ] **Step 4: 전체 산출물 점검**

Run:
```bash
ls cron-prompts/workflow-discovery.md scripts/render-discovery.sh && \
  grep -q 'rentre-cron-discovery' scripts/setup-cron-agents.sh && \
  grep -q '워크플로우 발굴' CLAUDE.md && cat VERSION && echo "all artifacts present"
```
Expected: 파일 2개 존재 + grep 통과 + VERSION 0.9.0 + "all artifacts present".

- [ ] **Step 5: Commit**

```bash
git add CLAUDE.md README.md VERSION
git commit -m "docs: v0.9.0 — 워크플로우 발굴 에이전트 문서·버전 갱신"
```

---

## 배포 후 절차 (구현 범위 밖, 참고)

1. 사용자가 `./scripts/setup-cron-agents.sh` 실행 → 금요일 16:00 크론 등록
2. push 시 메모리 규칙(`feedback_version_slack`)에 따라 `#ax-챌린지-feed`에 v0.9.0 알림
3. shadow phase 2-4주 관찰 후 `--no-alert` 제거 → active phase 전환
4. 유용성 검증되면 설계 문서 §향후 단계대로 자율성 상향(제안 + 초안 생성) 검토

---

## Spec Coverage 자기점검

| 설계 §  | 요구사항 | 구현 Task |
|--------|----------|-----------|
| §1 | fan-out→synthesis, 주1회 금16:00, harness 래핑 | T1(흐름), T7(크론), T8(harness) |
| §2 | 스캐너 4종 + 신호 스키마 + 최소권한 지시 | T2 |
| §3 | 공개영역 한정 + 집계/익명 | T1(원칙), T2(스캐너 범위) |
| §4 | 점수공식 + 리포트 포맷 + 중복추적 | T3(점수·중복), T4(포맷) |
| §5 | 산출물 파일 + 크론 등록 + 권한 트레이드오프 | T5(렌더), T7(크론) |
| §6 | DRY_RUN, 스캐너 독립검증, graceful degradation, 검증 | T4(DRY_RUN·degradation), T5/T6(검증) |
