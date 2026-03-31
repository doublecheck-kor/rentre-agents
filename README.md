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
  <img src="https://img.shields.io/badge/version-0.4.0-blue" alt="version"/>
  <img src="https://img.shields.io/badge/BMAD-v6.0.4-purple" alt="bmad"/>
  <img src="https://img.shields.io/badge/rentre-12_commands-green" alt="commands"/>
  <img src="https://img.shields.io/badge/bmad-121_skills-orange" alt="skills"/>
  <img src="https://img.shields.io/badge/platform-Claude_Code_CLI-black" alt="platform"/>
</p>

---

## What is Rentre Agents?

**BMAD Framework**(개발 엔진) + **Rentre 커맨드**(업무 자동화)를 결합한 AI 에이전트 시스템입니다.

- **개발 프로세스** → BMAD v6의 121개 스킬 (워크플로우 샤딩, 3-Layer 코드리뷰, 에이전트 핸드오프)
- **업무 자동화** → Rentre의 12개 커맨드 (Slack, Notion, Calendar, Gmail MCP 연동)
- **자율 운영** → 크론 기반 자동 브리핑, ADR 모니터링

```
"오늘 일정 알려줘"           → /rentre:schedule
"이 기능 개발해줘"           → /bmad-agent-dev
"코드 리뷰해줘"              → /bmad-code-review (3-Layer)
"이 설계 괜찮은지 검증해봐"   → /rentre:challenge
"아이디어가 있는데..."       → /bmad-brainstorming
```

---

## Quick Start

### 1. 설치

**Claude Code에서 (추천)**
```
https://github.com/doublecheck-kor/rentre-agents 클론하고 설치해줘
```

**터미널에서**
```bash
git clone --recurse-submodules https://github.com/doublecheck-kor/rentre-agents.git ~/.rentre-agents
bash ~/.rentre-agents/shared-commands/install.sh
```

**원클릭**
```bash
curl -sL https://raw.githubusercontent.com/doublecheck-kor/rentre-agents/main/shared-commands/quick-install.sh | bash
```

### 2. 초기 설정

Claude Code에서 `/rentre:setup` 실행 — 이름, 이메일만 입력하면 끝.
Slack, Notion, Gmail은 MCP로 자동 감지합니다.

### 3. 사용

```
/rentre:help    → Rentre + BMAD 통합 가이드
/bmad-help      → BMAD 개발 워크플로우 가이드
```

---

## Architecture

```
rentre-agents/
├── bmad-submodule/           ← BMAD Framework (git submodule)
│   ├── .claude/skills/       ←   121개 개발 스킬
│   └── _bmad/                ←   워크플로우, 에이전트, 메모리
│
├── shared-commands/rentre/   ← Rentre 고유 커맨드
│   ├── assistant, schedule,  ←   업무 자동화 (MCP 연동)
│   │   email, slack, notion
│   ├── market, adr,          ←   분석 & 모니터링
│   │   challenge, ailab
│   └── _backlog-rules.md     ←   Notion 백로그 규칙
│
├── cron-prompts/             ← 자율 운영 (크론)
└── scripts/                  ← 설치/운영 스크립트
```

---

## Rentre Commands (`/rentre:*`)

BMAD에 없는 업무 자동화 기능.

### Daily Assistant

| 커맨드 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/rentre:assistant` | **만능 비서** — 일정, 정보 조회, 요약, 커뮤니케이션 | `내일 오전에 재만님이랑 미팅 잡아줘` |
| `/rentre:schedule` | **일정 관리** — Google Calendar 기반 | `이번 주 내 스케줄` |
| `/rentre:email` | **이메일** — 받은 메일 요약, 드래프트 작성 | `오늘 온 메일 중 중요한 거 요약해줘` |
| `/rentre:market` | **마켓 브리핑** — PropTech, 부동산, AI 시장 동향 | `오늘 시장 브리핑` |

### Analysis & Review

| 커맨드 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/rentre:challenge` | **적대적 리뷰어** — 설계/의사결정 스트레스 테스트 | `이 아키텍처 결정 검증해줘` |
| `/rentre:adr` | **ADR 분석** — 5개 관점 다각도 분석 (Notion 연동) | `최근 ADR 리뷰해줘` |

### Integrations

| 커맨드 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/rentre:slack` | **Slack** — 채널/DM 메시지 조회, 전송 | `#general 최근 메시지 보여줘` |
| `/rentre:notion` | **Notion** — 페이지 검색, DB 쿼리 | `스프린트 백로그 조회` |
| `/rentre:ailab` | **AI Lab 쇼케이스** — Notion DB 자동 등록 + Slack 알림 | `이 대화 쇼케이스로 등록해줘` |
| `/rentre:pr-notion` | **Notion 기반 PR** — 요구사항 분석 → GitHub PR 자동 생성 | `[Notion URL] 이거 PR 만들어줘` |
| `/rentre:pr-split` | **PR 분리** — 큰 변경사항을 600줄 미만 단위로 분리 | `현재 변경사항 PR 분리해줘` |

### System

| 커맨드 | 설명 |
|--------|------|
| `/rentre:help` | Rentre + BMAD 통합 가이드 |
| `/rentre:setup` | 초기 설정 (MCP 자동 감지 + BMAD 설치) |

---

## BMAD Skills (`/bmad-*`)

[BMAD Framework v6](https://github.com/OhSeungWan/bmad-submodule) 기반 개발 프로세스. 121개 스킬.

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
| `/bmad-party-mode` | 멀티에이전트 토론 |
| `/bmad-sprint-planning` | 스프린트 플래닝 |
| `/bmad-retrospective` | 레트로스펙티브 |

> 전체 121개 스킬 목록: `/bmad-help` 실행

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
│  코드리뷰 결과 → Slack 알림 (/rentre:slack)                    │
│  PR 생성 → /rentre:pr-notion                                 │
│  기술 결정 → /rentre:adr (Notion ADR DB)                      │
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
```bash
cd ~/.rentre-agents && git pull --recurse-submodules && ./shared-commands/install.sh
```

**BMAD만 업데이트**
```bash
cd ~/.rentre-agents && git submodule update --remote bmad-submodule && ./shared-commands/install.sh
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
- Git (submodule 지원)
- MCP 연결 — 선택 사항, 연결하면 더 강력합니다:
  - **Slack** — 메시지 조회/전송, 유저 검색
  - **Notion** — 문서/DB 검색, 백로그 관리
  - **Google Calendar** — 일정 조회/생성
  - **Gmail** — 이메일 조회/드래프트

---

<p align="center">
  Powered by <a href="https://github.com/bmad-code-org/BMAD-METHOD">BMAD Framework</a> + <a href="https://rentre.kr">Rentre</a>
</p>
