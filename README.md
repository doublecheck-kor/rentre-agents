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
  <img src="https://img.shields.io/badge/version-0.7.9-blue" alt="version"/>
  <img src="https://img.shields.io/badge/BMAD-v6.3-purple" alt="bmad"/>
  <img src="https://img.shields.io/badge/rentre-8_commands-green" alt="commands"/>
  <img src="https://img.shields.io/badge/bmad-119_skills-orange" alt="skills"/>
  <img src="https://img.shields.io/badge/platform-Claude_Code_CLI-black" alt="platform"/>
</p>

---

## What is Rentre Agents?

**BMAD Framework**(개발 엔진) + **Rentre 커맨드**(업무 자동화)를 결합한 AI 에이전트 시스템입니다.

- **개발 프로세스** → BMAD의 119개 스킬 (워크플로우 샤딩, 3-Layer 코드리뷰, 에이전트 핸드오프)
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
rentre-agents(https://github.com/doublecheck-kor/rentre-agents) 서브모듈로 설치하고 /rentre:setup 실행해줘
```

이 한 문장으로:
- git submodule 추가 → 초기 설정 수집 → 프로젝트별 스킬/커맨드 설치
- 이미 설정(`~/.claude/rentre-config.json`)이 있으면 설정 스킵, 바로 설치

**터미널에서 직접**
```bash
# 프로젝트 루트에서:
git submodule add https://github.com/doublecheck-kor/rentre-agents
git submodule update --init --recursive
bash rentre-agents/install.sh --preset full
# → Claude Code에서 /rentre:setup 실행
```

**기존 프로젝트 클론**
```bash
git clone --recurse-submodules <repo-url>
bash rentre-agents/install.sh
```

### 사용

```
/rentre:help    → Rentre + BMAD 통합 가이드
/bmad-help      → BMAD 개발 워크플로우 가이드
```

---

## 설치 구조

```
프로젝트별 (기본, 각 프로젝트에 독립 설치)
  my-project/
    rentre-agents/                     ← git submodule
      bmad-submodule/                  ← nested submodule (v2.6.0)
    .claude/skills/bmad-*              ← BMAD 스킬 119개 (상대경로 심링크)
    .claude/commands/rentre/           ← 모든 커맨드 (assistant, help, setup, adr, ailab 등)
    .claude/bmad-profile.json          ← 설치 프로파일
    _bmad/                             ← BMAD config (상대경로 심링크)

글로벌 (--with-global 옵션 시에만, 부트스트랩용)
  ~/.claude/commands/rentre/           ← assistant.md, help.md, setup.md
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
| `/rentre:marketplace` | **마켓플레이스 등록** — Next.js 16+ 필수, rentre.config.json 생성 + 호환성 검증 | `마켓플레이스 등록 준비해줘` |
| `/rentre:help` | Rentre + BMAD 통합 가이드 | |
| `/rentre:setup` | 초기 설정 / 업데이트 (MCP 자동 감지) | |

---

## BMAD Skills (`/bmad-*`)

[BMAD Framework v6.3](https://github.com/OhSeungWan/bmad-submodule) 기반 개발 프로세스. 119개 스킬.

### Core Agents

| 스킬 | 이름 | 역할 |
|------|------|------|
| `/bmad-agent-pm` | John | PRD 작성, 요구사항 발견 |
| `/bmad-agent-architect` | Winston | 아키텍처 설계, 기술 결정 |
| `/bmad-agent-dev` | Amelia | 스토리 구현, 코드 작성 |
| `/bmad-agent-ux-designer` | Sally | UX 디자인, UI 기획 |
| `/bmad-agent-analyst` | Mary | 비즈니스 분석, 요구사항 |
| `/bmad-agent-tech-writer` | Paige | 기술 문서화 |
| `/bmad-tea` | Murat | 테스트 아키텍트 |

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
| `/bmad-checkpoint-preview` | 변경사항 워크스루 리뷰 |
| `/bmad-prfaq` | Working Backwards PRFAQ |

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
cd rentre-agents && git pull --recurse-submodules && cd .. && bash rentre-agents/install.sh
```

**제거**
```bash
bash rentre-agents/install.sh --remove
```

---

## Install Options

| 플래그 | 설명 |
|--------|------|
| `--preset backend` | 백엔드 개발자용 (에이전트, 기획, 개발, 테스트, 아키텍처) |
| `--preset frontend` | 프론트엔드 개발자용 (+ FSD 아키텍처) |
| `--preset pm` | PM/기획자용 (에이전트, 기획, 비즈니스, 문서화) |
| `--preset gamedev` | 게임 개발자용 (GDS 스킬) |
| `--preset full` | 전체 설치 (119개 스킬) |
| `--with-global` | 프로젝트 + 글로벌 동시 설치 |
| `--global-only` | 글로벌 커맨드만 (부트스트랩용) |
| `--yes` | 대화형 프롬프트 없이 자동 실행 |
| `--remove` | 프로젝트에서 제거 |

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
  Powered by <a href="https://github.com/bmad-code-org/BMAD-METHOD">BMAD Framework</a> + <a href="https://rentre.kr">Rentre</a>
</p>
