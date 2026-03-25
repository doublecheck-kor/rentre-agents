# Rentre Agents

Claude Code CLI 기반의 AI 에이전트 시스템입니다.
비서, 개발, 분석, 토론 에이전트를 `/rentre:*` 커맨드로 실행합니다.

## 주요 기능

**비서/유틸리티** — 일정 조회, Slack 연동, Notion 검색, 이메일 관리, 마켓 브리핑

**개발 프로세스 (BMAD-Enhanced)** — 10라운드 토론 → PRD → Architecture → Story → TDD → E2E → PR의 9단계 파이프라인

**품질 & 리뷰** — QA 코드리뷰, 엣지케이스 탐색, 적대적 리뷰

**기획 & 토론** — 브레인스토밍, 멀티에이전트 파티 모드

## 설치

### 방법 1: Claude Code에서 설치 (추천)

Claude Code를 열고 이렇게 말하세요:

```
https://github.com/rentre-kr/rentre-agents 클론하고 shared-commands/install.sh 실행해줘.
그다음 /rentre:setup 실행해줘.
```

### 방법 2: 터미널에서 설치

```bash
git clone https://github.com/rentre-kr/rentre-agents.git ~/.rentre-agents
bash ~/.rentre-agents/shared-commands/install.sh
```

### 초기 설정

설치 후 Claude Code에서 `/rentre:setup`을 실행하세요.

- 이름, 이메일만 입력하면 나머지는 MCP로 자동 감지
- Slack User ID, Notion User ID, Gmail 프로필 자동 수집
- 설정 파일: `~/.claude/rentre-config.json`

## 커맨드 목록

| 커맨드 | 설명 |
|--------|------|
| `/rentre:assistant` | 만능 비서 (일정, 커뮤니케이션, 정보 조회) |
| `/rentre:schedule` | Google Calendar 일정 조회 |
| `/rentre:market` | 마켓/뉴스 모닝 브리핑 |
| `/rentre:slack` | Slack 메시지 조회/전송 |
| `/rentre:notion` | Notion 문서 검색/조회 |
| `/rentre:email` | Gmail 관리 |
| `/rentre:agile` | 애자일 프로세스 (10라운드 토론 + PRD + Architecture + 백로그) |
| `/rentre:develop` | 풀사이클 개발 (토론 → TDD → E2E → PR) |
| `/rentre:quickdev` | 빠른 개발 (소규모 작업용 축약 TDD + PR) |
| `/rentre:adr` | ADR 다중 관점 분석 (5개 에이전트) |
| `/rentre:qa` | QA 코드리뷰, 품질 검증 |
| `/rentre:edge` | 엣지케이스 헌터 |
| `/rentre:challenge` | 적대적 리뷰 (설계/결정 스트레스 테스트) |
| `/rentre:brainstorm` | 브레인스토밍 (아이디어 → 요구사항 도출) |
| `/rentre:party` | 멀티에이전트 자유형 토론 |
| `/rentre:help` | 가이드 및 워크플로우 안내 |
| `/rentre:setup` | 초기 설정 (MCP 자동 감지) |

## 개발 파이프라인

`/rentre:develop` 실행 시 9단계 파이프라인:

```
Stage 1: 10 Round Debate (5인 패널 토론)
Stage 2: Debate Synthesis (토론 결과 통합)
Stage 3: PRD Document          → Gate 1 검증
Stage 4: Architecture Document → Gate 2 검증
Stage 5: Story Breakdown       → Gate 3 검증
Stage 6: TDD Development       → Gate 4 검증
Stage 7: E2E Test (Playwright) → Gate 5 검증
Stage 8: PR Creation
Stage 9: Retrospective
```

프로젝트 타입별 자동 조절:
- **Greenfield**: 전체 10라운드 + 전체 문서 생성
- **Brownfield**: 10라운드 + 기존 코드 분석 + 영향도 분석
- **Hotfix**: 축약 3라운드 + 간소화된 게이트

## 토론 패널 (5명)

| 역할 | 관점 |
|------|------|
| CTO | 기술 전략, 아키텍처, 확장성, 기술 부채 |
| Backend Lead | API, DB, 성능, 보안, 인프라 |
| Frontend Lead | UX/UI, 접근성, 컴포넌트, 디자인 시스템 |
| PM | 비즈니스 가치, 사용자 니즈, 우선순위, ROI |
| Agile Coach | 리스크, 의존성, 팀 역량, 프로세스 |

## 크론 자동화

| 시간 | 내용 |
|------|------|
| 평일 08:47 | 마켓/뉴스 브리핑 → Slack DM |
| 평일 09:03 | 데일리 브리핑 (캘린더) → Slack DM |
| 평일 08-20시 매시 | ADR 모니터링 → 멘션 감지 시 Slack DM |

크론 설정은 `scripts/start-agent.sh`로 tmux 세션에서 자동 실행됩니다.

## 프로젝트 구조

```
rentre-agents/
├── README.md                 ← 이 파일
├── CLAUDE.md.template        ← 프로젝트 컨텍스트 템플릿
├── config.example.json       ← 설정 예시
├── org-chart.md              ← 조직도 (에이전트 정의)
├── executive/                ← CEO, 비서 에이전트
├── tech/                     ← CTO, Backend, Frontend, Data/AI, DevOps
├── business/                 ← COO, PM, Agile, Marketing, Sales, Ops
├── templates/                ← BMAD 구조화 템플릿
│   ├── prd.md               ← PRD 문서
│   ├── architecture.md       ← 아키텍처 문서
│   ├── story.md             ← 유저 스토리
│   └── checklist.md         ← Validation Gate 체크리스트
├── shared-commands/
│   ├── install.sh           ← 설치 스크립트
│   ├── quick-install.sh     ← 원클릭 설치
│   └── rentre/              ← 글로벌 커맨드 (17개)
├── cron-prompts/             ← 크론 자동화 프롬프트
└── scripts/                  ← 시작/갱신/크론 스크립트
```

## 업데이트

```bash
cd ~/.rentre-agents && git pull && ./shared-commands/install.sh
```

## 제거

```bash
~/.rentre-agents/shared-commands/install.sh --remove
rm -rf ~/.rentre-agents
```

## 요구 사항

- [Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code) (Claude Team/Enterprise 플랜)
- Node.js (Claude Code 설치 시 포함)
- MCP 연결 (Slack, Notion, Google Calendar, Gmail — 선택)

## 라이선스

이 프로젝트는 Rentre 내부용으로 개발되었습니다.
