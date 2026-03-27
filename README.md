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
  <strong>Claude Code 기반 AI 에이전트 시스템</strong><br/>
  30명의 AI 조직이 당신의 업무를 함께합니다.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-0.2.0-blue" alt="version"/>
  <img src="https://img.shields.io/badge/agents-19_commands-green" alt="commands"/>
  <img src="https://img.shields.io/badge/org-30_members-orange" alt="org"/>
  <img src="https://img.shields.io/badge/pipeline-9_stages-purple" alt="pipeline"/>
  <img src="https://img.shields.io/badge/platform-Claude_Code_CLI-black" alt="platform"/>
</p>

---

## What is Rentre Agents?

Claude Code CLI 위에서 동작하는 **AI 에이전트 프레임워크**입니다.

`/rentre:*` 슬래시 커맨드 하나로 — 일정 관리, 이메일 처리, 코드 개발, 아키텍처 토론, 품질 검증까지. 사람이 하는 모든 업무 프로세스를 AI 에이전트가 수행합니다.

```
"오늘 일정 알려줘"           → /rentre:schedule
"이 기능 개발해줘"           → /rentre:develop  (토론 → 설계 → TDD → PR)
"이 설계 괜찮은지 검증해봐"   → /rentre:challenge
"아이디어가 있는데..."       → /rentre:brainstorm
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
git clone https://github.com/doublecheck-kor/rentre-agents.git ~/.rentre-agents
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

Claude Code에서 `/rentre:help` 입력하면 전체 가이드를 볼 수 있습니다.

---

## Agent Commands

### Daily Assistant

| 커맨드 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/rentre:assistant` | **만능 비서** — 뭐든 물어보세요. 일정, 정보 조회, 요약, 커뮤니케이션까지 알아서 처리합니다. | `내일 오전에 재만님이랑 미팅 잡아줘` |
| `/rentre:schedule` | **일정 관리** — Google Calendar 기반. 내 일정 + 팀원 일정 + 회의실 조회. | `이번 주 내 스케줄` |
| `/rentre:email` | **이메일** — 받은 메일 요약, 드래프트 작성, 중요 메일 필터링. | `오늘 온 메일 중 중요한 거 요약해줘` |
| `/rentre:market` | **마켓 브리핑** — PropTech, 부동산, AI 시장 동향과 뉴스를 매일 아침 브리핑. | `오늘 시장 브리핑` |

### Development

| 커맨드 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/rentre:develop` | **풀사이클 개발** — PRD 하나로 토론 → 설계 → 스토리 → TDD → E2E → PR까지 9단계 자동화. 5인 패널이 아키텍처를 토론하고, 코드는 TDD로, 테스트는 Playwright로. | `[PRD 붙여넣기] 이거 개발해줘` |
| `/rentre:quickdev` | **빠른 개발** — 버그 픽스, 소규모 기능 추가 등 가벼운 작업용. 축약 TDD + PR 자동 생성. | `로그인 페이지 404 에러 수정해줘` |
| `/rentre:agile` | **애자일 프로세스** — 10라운드 토론으로 요구사항을 정제하고, PRD → Architecture Doc → 백로그까지 생성. 개발 없이 기획만 필요할 때. | `[PRD] 스프린트 플래닝 해줘` |
| `/rentre:adr` | **ADR 분석** — Architecture Decision Record를 5개 관점(기술/비즈니스/보안/운영/팀)에서 다각도 분석. Notion ADR DB와 연동. | `최근 ADR 리뷰해줘` |

### Quality & Review

| 커맨드 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/rentre:qa` | **QA 에이전트** — 코드리뷰, 테스트 커버리지 분석, 품질 메트릭 검증. 놓친 테스트 케이스를 찾아냅니다. | `이 PR 리뷰해줘` |
| `/rentre:edge` | **엣지케이스 헌터** — 체계적으로 경계값, 동시성, 실패 시나리오를 탐색. "이런 경우는 어떻게 되지?"를 대신 고민합니다. | `결제 플로우 엣지케이스 찾아줘` |
| `/rentre:challenge` | **적대적 리뷰어** — 설계와 의사결정을 의도적으로 반박하고 스트레스 테스트. 약점을 미리 발견합니다. | `이 아키텍처 결정 검증해줘` |

### Planning & Discussion

| 커맨드 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/rentre:brainstorm` | **브레인스토밍** — 막연한 아이디어를 구체적인 요구사항으로. Socratic 방식으로 질문하며 핵심을 끌어냅니다. | `AI 추천 기능 아이디어가 있는데...` |
| `/rentre:party` | **파티 모드** — 자유형 멀티 에이전트 토론. Tech, Business, 또는 전체 조직이 주제를 놓고 토론합니다. | `--tech 캐싱 전략 토론` |

### Integrations

| 커맨드 | 설명 | 사용 예시 |
|--------|------|-----------|
| `/rentre:slack` | **Slack** — 채널/DM 메시지 조회, 전송, 스레드 읽기. | `#general 최근 메시지 보여줘` |
| `/rentre:notion` | **Notion** — 페이지 검색, 문서 조회, 데이터베이스 쿼리. | `스프린트 백로그 조회` |
| `/rentre:ailab` | **AI Lab 쇼케이스** — 대화 컨텍스트를 분석해서 Notion DB에 자동 등록 + Slack 알림. | `이 대화 쇼케이스로 등록해줘` |
| `/rentre:pr-notion` | **Notion 기반 PR** — Notion 문서의 요구사항을 분석해서 GitHub PR 자동 생성. | `[Notion URL] 이거 PR 만들어줘` |
| `/rentre:pr-split` | **PR 분리** — 큰 변경사항을 600줄 미만 단위로 자동 분리. 리뷰하기 좋은 크기로. | `현재 변경사항 PR 분리해줘` |

### System

| 커맨드 | 설명 |
|--------|------|
| `/rentre:help` | 전체 가이드, 워크플로우 안내, 다음 단계 추천 |
| `/rentre:setup` | 초기 설정 (MCP 자동 감지 + config 생성 + 커맨드 설치) |

---

## Development Pipeline

`/rentre:develop`이 실행하는 **9단계 풀사이클 파이프라인**:

```
┌─────────────────────────────────────────────────────────────────┐
│                                                                 │
│   Stage 1    Stage 2    Stage 3    Stage 4    Stage 5           │
│  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐        │
│  │10Round│→ │Synthe-│→ │  PRD  │→ │ Arch  │→ │ Story │        │
│  │Debate │  │ sis   │  │  Doc  │  │  Doc  │  │Break- │        │
│  │       │  │       │  │       │  │       │  │ down  │        │
│  └───────┘  └───────┘  └──┬────┘  └──┬────┘  └──┬────┘        │
│                            │ Gate1    │ Gate2    │ Gate3        │
│                            ▼          ▼          ▼              │
│   Stage 6    Stage 7    Stage 8    Stage 9                      │
│  ┌───────┐  ┌───────┐  ┌───────┐  ┌───────┐                   │
│  │  TDD  │→ │  E2E  │→ │  PR   │→ │Retro- │                   │
│  │  Dev  │  │Playw- │  │Create │  │spect- │                   │
│  │R→G→R  │  │right  │  │       │  │ ive   │                   │
│  └──┬────┘  └──┬────┘  └───────┘  └───────┘                   │
│     │ Gate4    │ Gate5                                          │
│     ▼          ▼                                                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

**5인 토론 패널**이 매 단계 의사결정을 검증합니다:

| 역할 | 관점 |
|------|------|
| **CTO** | 기술 전략, 아키텍처, 확장성, 기술 부채 |
| **Backend Lead** | API 설계, DB 모델링, 성능, 보안 |
| **Frontend Lead** | UX/UI, 접근성, 컴포넌트 설계, 디자인 시스템 |
| **PM** | 비즈니스 가치, 사용자 니즈, 우선순위, ROI |
| **Agile Coach** | 리스크 관리, 의존성, 팀 역량, 프로세스 |

프로젝트 타입에 따라 자동 조절:

| 타입 | 토론 | 문서 | 게이트 |
|------|------|------|--------|
| **Greenfield** (신규) | 전체 10라운드 | 전체 생성 | 5개 전체 |
| **Brownfield** (확장) | 10라운드 + 기존 코드 분석 | 영향도 분석 포함 | 5개 전체 |
| **Hotfix** (긴급) | 축약 3라운드 | 간소화 | 핵심만 |

---

## Organization

30명 규모의 AI 조직이 에이전트 뒤에서 협업합니다.

```
                            CEO
                             │
                ┌────────────┼────────────┐
                │            │            │
            CTO (1)    Executive      COO (1)
                │      Assistant (1)      │
                │                         │
      ┌────┬────┴────┬──────┐    ┌────┬───┴───┬──────┬──────┐
      │    │         │      │    │    │       │      │      │
   Back  Front   Data/AI DevOps  PM  Agile  Mktg  Sales   Ops
   end   end      (3)   (2)   (3) Coach  (3)   (3)   (3)
   (3)   (3)                       (1)
```

| Division | 인원 | 역할 |
|----------|------|------|
| **Executive** | 3 | CEO, COO, Executive Assistant |
| **Tech** | 12 | CTO, Backend(3), Frontend(3), Data/AI(3), DevOps(2) |
| **Business** | 14 | PM(3), Agile(1), Marketing(3), Sales(3), Operations(3) |
| **합계** | **30** | |

---

## Automation

tmux 백그라운드에서 자동 실행되는 크론 작업:

| 시간 | 내용 | 채널 |
|------|------|------|
| 평일 08:47 | 마켓/뉴스 브리핑 | Slack DM |
| 평일 09:03 | 데일리 브리핑 (캘린더 일정) | Slack DM |
| 평일 08-20시 매시 | ADR 모니터링 (멘션 감지) | Slack DM |

크론 설정: `scripts/start-agent.sh`로 tmux 세션 시작 → `scripts/setup-crontab.sh`로 등록

---

## Project Structure

```
rentre-agents/
├── CLAUDE.md.template        # 프로젝트 컨텍스트 템플릿
├── config.example.json       # 설정 예시
├── org-chart.md              # 30명 조직도
│
├── executive/                # CEO, Executive Assistant
├── tech/                     # CTO, Backend, Frontend, Data/AI, DevOps
├── business/                 # COO, PM, Agile, Marketing, Sales, Ops
│
├── templates/                # BMAD 구조화 템플릿
│   ├── prd.md               #   PRD (문제 정의, JTBD, MoSCoW)
│   ├── architecture.md       #   아키텍처 (스택, 구조, API, 보안)
│   ├── story.md             #   유저 스토리 (AC, Gherkin, TDD)
│   └── checklist.md         #   5개 Validation Gate
│
├── shared-commands/
│   ├── install.sh           # 설치 스크립트
│   ├── quick-install.sh     # curl 원클릭 설치
│   └── rentre/              # 슬래시 커맨드 (19개)
│
├── cron-prompts/             # 크론 자동화 프롬프트
│   ├── daily-briefing.md    #   데일리 브리핑
│   ├── market-news.md       #   마켓/뉴스 브리핑
│   └── adr-monitor.md       #   ADR 모니터링
│
└── scripts/                  # 운영 스크립트
    ├── start-agent.sh       #   tmux 세션 시작
    ├── renew-agent.sh       #   주간 자동 갱신
    └── setup-crontab.sh     #   crontab 등록
```

---

## Update & Uninstall

**업데이트**
```bash
cd ~/.rentre-agents && git pull && ./shared-commands/install.sh
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
- MCP 연결 — 선택 사항, 연결하면 더 강력합니다:
  - **Slack** — 메시지 조회/전송, 유저 검색
  - **Notion** — 문서/DB 검색, 백로그 관리
  - **Google Calendar** — 일정 조회/생성
  - **Gmail** — 이메일 조회/드래프트

---

<p align="center">
  Built with Claude Code by <a href="https://rentre.kr">Rentre</a>
</p>
