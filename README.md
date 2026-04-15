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
  <strong>BMAD Framework + MCP 업무 자동화</strong><br/>
  개발은 BMAD가, 업무는 Rentre가.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-0.7.4-blue" alt="version"/>
  <img src="https://img.shields.io/badge/BMAD-v6-purple" alt="bmad"/>
  <img src="https://img.shields.io/badge/rentre-8_commands-green" alt="commands"/>
  <img src="https://img.shields.io/badge/bmad-109_skills-orange" alt="skills"/>
  <img src="https://img.shields.io/badge/platform-Claude_Code_CLI-black" alt="platform"/>
</p>

---

## What is Rentre Agents?

**BMAD Framework**(개발 엔진) + **Rentre 커맨드**(업무 자동화)를 결합한 AI 에이전트 시스템입니다.

- **개발 프로세스** → BMAD의 109개 스킬 (워크플로우 샤딩, 3-Layer 코드리뷰, 에이전트 핸드오프)
- **업무 자동화** → Rentre의 8개 커맨드 (Slack, Notion, Calendar, Gmail MCP 연동)
- **자율 운영** → 크론 기반 자동 브리핑, ADR 모니터링

```
"오늘 일정 알려줘"           → /rentre:assistant
"이 기능 개발해줘"           → /bmad-agent-dev
"코드 리뷰해줘"              → /bmad-code-review (3-Layer)
"이 설계 검증해봐"           → /bmad-review-adversarial-general
"아이디어가 있는데..."       → /bmad-brainstorming
```

---

## Quick Start

### 설치

Claude Code에서 이 한 문장이면 끝:

```
rentre-agents(https://github.com/doublecheck-kor/rentre-agents) 설치하고 /rentre:setup 실행해줘
```

이 한 문장으로:
- **첫 프로젝트** → 레포 clone + 글로벌 Rentre 커맨드 + 프로젝트 BMAD 설치 + 초기 설정
- **이후 프로젝트** → 이미 설치된 글로벌은 스킵, BMAD만 현재 프로젝트에 설치

**터미널에서 직접**
```bash
git clone --recurse-submodules https://github.com/doublecheck-kor/rentre-agents.git ~/.rentre-agents
bash ~/.rentre-agents/shared-commands/install.sh
# → Claude Code에서 /rentre:setup 실행
```

**원클릭**
```bash
curl -sL https://raw.githubusercontent.com/doublecheck-kor/rentre-agents/main/shared-commands/quick-install.sh | bash
```

### 사용

```
/rentre:help    → Rentre + BMAD 통합 가이드
/bmad-help      → BMAD 개발 워크플로우 가이드
```

---

## 설치 구조

```
글로벌 (1회, 모든 프로젝트 공통)
  ~/.rentre-agents/                  ← 레포 clone
  ~/.claude/commands/rentre/         ← /rentre:* 커맨드 7개
  ~/.claude/skills/rentre-pr-*       ← PR 스킬 2개

프로젝트별 (install.sh 실행한 프로젝트마다)
  ~/my-project/.claude/skills/bmad-* ← BMAD 스킬 109개 (심링크)
  ~/my-project/_bmad/                ← BMAD config (심링크)
```

---

## Rentre Commands (`/rentre:*`)

BMAD에 없는 Rentre 고유 업무 자동화 기능.

| 커맨드 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/rentre:assistant` | **만능 비서** — 일정, 이메일, Slack, Notion, 마켓 브리핑 통합 | `오늘 일정 알려줘` |
| `/rentre:adr` | **ADR 분석** — 5개 관점 멀티에이전트 분석 (Notion 연동) | `최근 ADR 리뷰해줘` |
| `/rentre:ailab` | **AI Lab 쇼케이스** — Notion DB 자동 등록 + Slack 알림 | `이 대화 쇼케이스로 등록해줘` |
| `/rentre:pr-notion` | **Notion 기반 PR** — 요구사항 분석 → GitHub PR 자동 생성 | `[Notion URL] PR 만들어줘` |
| `/rentre:pr-split` | **PR 분리** — 큰 변경사항을 600줄 미만 단위로 분리 | `현재 변경사항 PR 분리해줘` |
| `/rentre:marketplace` | **마켓플레이스 등록** — rentre.config.json 생성 + 호환성 검증 | `마켓플레이스 등록 준비해줘` |
| `/rentre:help` | Rentre + BMAD 통합 가이드 | |
| `/rentre:setup` | 초기 설정 (MCP 자동 감지) | |

---

## BMAD Skills (`/bmad-*`)

[BMAD Framework v6](https://github.com/OhSeungWan/bmad-submodule) 기반 개발 프로세스. 109개 스킬.

### Core Agents

| 스킬 | 이름 | 역할 |
|------|------|------|
| `/bmad-agent-pm` | John | PRD 작성, 요구사항 발견 |
| `/bmad-agent-architect` | Winston | 아키텍처 설계, 기술 결정 |
| `/bmad-agent-dev` | Amelia | 스토리 구현, 코드 작성 |
| `/bmad-agent-sm` | Bob | 스프린트 플래닝, 스토리 준비 |
| `/bmad-agent-qa` | Quinn | 테스트 자동화, 커버리지 |
| `/bmad-agent-ux-designer` | Sally | UX 디자인, UI 기획 |
| `/bmad-agent-quick-flow-solo-dev` | Barry | 빠른 개발 (버그/소기능) |

### Key Workflows

| 스킬 | 용도 |
|------|------|
| `/bmad-brainstorming` | 브레인스토밍 세션 |
| `/bmad-create-prd` | PRD 생성 |
| `/bmad-create-architecture` | 아키텍처 문서 생성 |
| `/bmad-create-epics-and-stories` | 에픽/스토리 분해 |
| `/bmad-dev-story` | 스토리 구현 (TDD) |
| `/bmad-quick-dev` | 빠른 개발 |
| `/bmad-code-review` | 3-Layer 코드리뷰 |
| `/bmad-review-adversarial-general` | 적대적 리뷰 |
| `/bmad-party-mode` | 멀티에이전트 토론 |
| `/bmad-sprint-planning` | 스프린트 플래닝 |

> 전체 스킬 목록: `/bmad-help` 실행

---

## Development Workflow

```
┌──────────────────────────────────────────────────────────────┐
│  BMAD Framework (개발 엔진)                                   │
│                                                              │
│  /bmad-brainstorming → /bmad-create-prd → /bmad-validate-prd │
│          ↓                                                   │
│  /bmad-create-architecture → /bmad-create-epics-and-stories  │
│          ↓                                                   │
│  /bmad-sprint-planning → /bmad-dev-story → /bmad-code-review │
│          ↓                                                   │
│  /bmad-retrospective                                         │
│                                                              │
├──────────────────────────────────────────────────────────────┤
│  Rentre Bridge (업무 연동)                                    │
│                                                              │
│  BMAD 산출물 → Notion 백로그 생성 (_backlog-rules)             │
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
cd ~/.rentre-agents && git pull --recurse-submodules && ./shared-commands/install.sh
```

**제거**
```bash
~/.rentre-agents/shared-commands/install.sh --remove
rm -rf ~/.rentre-agents
```

---

## Requirements

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (Claude Team / Enterprise 플랜)
- Node.js (Claude Code 설치 시 포함)
- Git
- MCP 연결 (선택):
  - **Slack** — 메시지 조회/전송
  - **Notion** — 문서/DB 검색, 백로그 관리
  - **Google Calendar** — 일정 조회/생성
  - **Gmail** — 이메일 조회/드래프트

---

<p align="center">
  Powered by <a href="https://github.com/bmad-code-org/BMAD-METHOD">BMAD Framework</a> + <a href="https://rentre.kr">Rentre</a>
</p>
