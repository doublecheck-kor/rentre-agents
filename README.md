<p align="center">
  <pre align="center">
    ____             __
   / __ \___  ____  / /_________
  / /_/ / _ \/ __ \/ __/ ___/ _ \
 / _, _/  __/ / / / /_/ /  /  __/
/_/ |_|\___/_/ /_/\__/_/   \___/
               A g e n t s
  </pre>
</p>

<p align="center">
  <strong>superpowers 개발 스킬 + MCP 업무 자동화</strong><br/>
  개발 규율은 superpowers가, 업무는 Rentre가.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-0.10.0-blue" alt="version"/>
  <img src="https://img.shields.io/badge/skills-superpowers_plugin-purple" alt="superpowers"/>
  <img src="https://img.shields.io/badge/rentre-9_commands-green" alt="commands"/>
  <img src="https://img.shields.io/badge/platform-Claude_Code_CLI-black" alt="platform"/>
</p>

---

## What is Rentre Agents?

**superpowers 플러그인**(개발 스킬) + **Rentre 커맨드**(업무 자동화)를 결합한 AI 에이전트 시스템입니다.

- **개발 프로세스** → superpowers 플러그인 (브레인스토밍, 플랜 작성/실행, TDD, 체계적 디버깅, 코드리뷰) — 글로벌 설치
- **업무 자동화** → Rentre의 커맨드 (Slack, Notion, Calendar, Gmail MCP 연동)
- **자율 운영** → 크론 기반 자동 브리핑, ADR 모니터링

```
"오늘 일정 알려줘"           → /rentre:assistant
"이 기능 개발해줘"           → /superpowers:brainstorming → writing-plans → executing-plans
"코드 리뷰해줘"              → /superpowers:requesting-code-review
"버그 잡아줘"                → /superpowers:systematic-debugging
"아이디어가 있는데..."       → /superpowers:brainstorming
```

---

## Quick Start

### 설치

Claude Code에서 이 한 문장이면 끝:

```
rentre-agents(https://github.com/doublecheck-kor/rentre-agents) 서브모듈로 설치하고 /rentre:setup 실행해줘
```

이 한 문장으로:
- git submodule 추가 → 초기 설정 수집 → superpowers 플러그인(글로벌) + 프로젝트 커맨드 설치
- 이미 설정(`~/.claude/rentre-config.json`)이 있으면 설정 스킵, 바로 설치

**터미널에서 직접**
```bash
# 프로젝트 루트에서:
git submodule add https://github.com/doublecheck-kor/rentre-agents
git submodule update --init
bash rentre-agents/install.sh
# → Claude Code에서 /rentre:setup 실행
```

**기존 프로젝트 클론**
```bash
git clone <repo-url>
bash rentre-agents/install.sh
```

### 사용

```
/rentre:help                  → Rentre + superpowers 통합 가이드
/superpowers:using-superpowers → superpowers 스킬 사용법
```

---

## 설치 구조

```
글로벌 (1회, 모든 프로젝트 공용)
  ~/.claude/plugins/                   ← superpowers 플러그인 (obra/superpowers-marketplace)

프로젝트별 (각 프로젝트에 독립 설치)
  my-project/
    rentre-agents/                     ← git submodule (nested submodule 없음)
    .claude/commands/rentre/           ← 모든 커맨드 (assistant, help, setup, adr, ailab 등)

글로벌 커맨드 (--with-global 옵션 시에만, 부트스트랩용)
  ~/.claude/commands/rentre/           ← assistant.md, help.md, setup.md
```

---

## Rentre Commands (`/rentre:*`)

Rentre 고유 업무 자동화 기능.

| 커맨드 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/rentre:assistant` | **만능 비서** — 일정, 이메일, Slack, Notion, 마켓 브리핑 통합 | `오늘 일정 알려줘` |
| `/rentre:adr` | **ADR 분석** — 5개 관점 멀티에이전트 분석 (Notion 연동) | `최근 ADR 리뷰해줘` |
| `/rentre:ailab` | **AI Lab 쇼케이스** — Notion DB 자동 등록 + Slack 알림 | `이 대화 쇼케이스로 등록해줘` |
| `/rentre:pr-notion` | **Notion 기반 PR** — 요구사항 분석 → GitHub PR 자동 생성 | `[Notion URL] PR 만들어줘` |
| `/rentre:pr-split` | **PR 분리** — 큰 변경사항을 600줄 미만 단위로 분리 | `현재 변경사항 PR 분리해줘` |
| `/rentre:marketplace` | **마켓플레이스 등록** — git(Next.js UI)/headless(Windmill)/url 3타입 자동 분기, rentre.config.json 생성 + 검증 | `마켓플레이스 등록 준비해줘` |
| `/rentre:help` | Rentre + superpowers 통합 가이드 | |
| `/rentre:setup` | 초기 설정 / 업데이트 (MCP 자동 감지) | |

---

## superpowers Skills (`/superpowers:*`)

[obra/superpowers](https://github.com/obra/superpowers) 플러그인 기반 개발 규율 스킬. install.sh가 글로벌(user 스코프)로 자동 설치.

### Key Skills

| 스킬 | 용도 |
|------|------|
| `/superpowers:brainstorming` | 구현 전 요구사항·설계 탐색 (모든 창작 작업 전 필수) |
| `/superpowers:writing-plans` | 멀티스텝 작업 구현 계획 작성 |
| `/superpowers:executing-plans` | 작성된 계획을 리뷰 체크포인트와 함께 실행 |
| `/superpowers:subagent-driven-development` | 독립 작업을 서브에이전트로 병렬 실행 |
| `/superpowers:test-driven-development` | TDD 사이클로 기능/버그 구현 |
| `/superpowers:systematic-debugging` | 버그·테스트 실패 체계적 디버깅 |
| `/superpowers:requesting-code-review` | 코드리뷰 요청 |
| `/superpowers:receiving-code-review` | 코드리뷰 피드백 검증·반영 |
| `/superpowers:verification-before-completion` | 완료 주장 전 검증 명령 실행 |
| `/superpowers:finishing-a-development-branch` | 작업 완료 후 머지/PR 정리 |
| `/superpowers:using-git-worktrees` | 격리된 작업 공간(worktree) 확보 |

> 전체 스킬 목록: `/superpowers:using-superpowers` 또는 `claude plugin details superpowers@superpowers-marketplace`

---

## Development Workflow

```
┌──────────────────────────────────────────────────────────────┐
│  superpowers (개발 규율)                                       │
│                                                              │
│  /superpowers:brainstorming → writing-plans                  │
│          ↓                                                   │
│  executing-plans (체크포인트) → test-driven-development       │
│          ↓                                                   │
│  systematic-debugging → requesting-code-review               │
│          ↓                                                   │
│  verification-before-completion → finishing-a-development-branch │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  Rentre Bridge (업무 연동)                                    │
│                                                              │
│  산출물 → Notion 백로그 생성 (_backlog-rules)                  │
│  PR 생성 → /rentre:pr-notion                                 │
│  기술 결정 → /rentre:adr (Notion ADR DB)                      │
│  쇼케이스 → /rentre:ailab (Notion + Slack)                    │
└──────────────────────────────────────────────────────────────┘
```

---

## Automation

tmux 백그라운드 크론 작업:

| 시간 | 내용 | 채널 |
|------|------|------|
| 평일 08:47 | 마켓/뉴스 브리핑 | Slack DM |
| 평일 09:03 | 데일리 브리핑 (캘린더 일정) | Slack DM |
| 평일 08-20시 매시 | ADR 모니터링 (멘션 감지) | Slack DM |
| 매주 금 16:00 | 워크플로우 발굴 (주 1회, 금) | Slack DM |

---

## Update & Uninstall

**업데이트**

Claude Code에서 한 줄:
```
/rentre:setup 업데이트해줘
```
또는 자연어로 `"rentre-agents 업데이트해줘"` 라고만 해도 자동 감지됩니다.

수동 업데이트:
```bash
cd rentre-agents && git pull && cd .. && bash rentre-agents/install.sh
```

**제거**
```bash
bash rentre-agents/install.sh --remove
```

---

## Install Options

| 플래그 | 설명 |
|--------|------|
| (없음) | 프로젝트 커맨드 설치 + superpowers 플러그인 글로벌 설치 |
| `--with-global` | 프로젝트 + 글로벌 커맨드 동시 설치 |
| `--global-only` | 글로벌 커맨드만 (부트스트랩용) |
| `--yes` | 대화형 프롬프트 없이 자동 실행 |
| `--remove` | 프로젝트에서 제거 |

> v3.0부터 `--preset`/프레임워크 선택은 제거되었습니다. 개발 스킬은 superpowers 플러그인(글로벌)이 제공합니다.

---

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (Claude Team / Enterprise 플랜)
- Bash 4.3+ (macOS: `brew install bash`)
- Git
- MCP 연결 (선택):
  - **Slack** — 메시지 조회/전송
  - **Notion** — 문서/DB 검색, 백로그 관리
  - **Google Calendar** — 일정 조회/생성
  - **Gmail** — 이메일 조회/드래프트

---

<p align="center">
  Powered by <a href="https://github.com/obra/superpowers">superpowers</a> + <a href="https://rentre.kr">Rentre</a>
</p>
