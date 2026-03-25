# Rentre Agents - Project CLAUDE.md

## 프로젝트 개요
Rentre 스타트업(30명 규모)의 AI 에이전트 시스템. Claude Code CLI 기반으로 비서/개발/분석 에이전트를 운영한다.

## 핵심 정보
- 회사: Rentre (렌트리) - 렌탈 플랫폼 스타트업
- CEO: Stephen (정재우, stephen@rentre.kr)
- Slack ID: U07SAAR4B60, DM channel: D07S7RE6TK4
- Notion User ID: 121d872b-594c-81ce-bec2-00027566bb0d
- Notion ADR DB: collection://23248a03-3208-80f5-b6ff-000b3b6dc9ba
- Windows User: LEGION (WSL2 Ubuntu)
- 타임존: Asia/Seoul

## 조직 구조 (rentre-agents/)
```
executive/     CEO, Executive Assistant
tech/          CTO, Backend(3), Frontend(3), Data/AI(3), DevOps(2) = 12명
business/      COO, Product(3), Agile(1), Marketing(3), Sales(3), Ops(3) = 14명
```

## 글로벌 커맨드 (~/.claude/commands/rentre/)
| 커맨드 | 용도 |
|--------|------|
| /rentre:assistant | 만능 비서 |
| /rentre:schedule | 일정 조회 (Google Calendar) |
| /rentre:market | 마켓/뉴스 브리핑 |
| /rentre:agile | 애자일 프로세스 (10라운드 토론 + PRD/Architecture Doc + 백로그) |
| /rentre:develop | 풀사이클 개발 (토론 + PRD + Architecture + Story + TDD + E2E + PR) |
| /rentre:adr | ADR 분석 (5개 관점) |
| /rentre:slack | Slack 연동 |
| /rentre:notion | Notion 검색/조회 |
| /rentre:email | Gmail 관리 |
| /rentre:help | 가이드 (다음 단계 안내, 워크플로우 가이드) |
| /rentre:party | 파티 모드 (자유형 멀티 에이전트 토론) |
| /rentre:qa | QA 에이전트 (코드리뷰, 품질검증, 테스트 커버리지) |
| /rentre:edge | 엣지케이스 헌터 (체계적 엣지케이스 탐색) |
| /rentre:challenge | 적대적 리뷰 (설계/결정 스트레스 테스트) |
| /rentre:brainstorm | 브레인스토밍 (아이디어 → 요구사항 도출) |
| /rentre:quickdev | 빠른 개발 (소규모 작업용 축약 TDD+PR) |

## 크론 자동화 (tmux 백그라운드)
| 시간 | 내용 |
|------|------|
| 평일 08:47 | 마켓/뉴스 브리핑 → Slack DM |
| 평일 09:03 | 데일리 브리핑 (캘린더) → Slack DM |
| 평일 08-20시 매시 | ADR 모니터링 → 멘션 감지 시 Slack DM |

## 자동 복구 체인
```
Windows 부팅 → WSL 자동 시작
  → startup.bat (시작 프로그램)
    → start-agent.sh
      → tmux "rentre-agent" 세션
        → Claude Code + 크론 등록
시스템 crontab: 매주 일요일 08:45 자동 갱신 (renew-agent.sh)
```

## 주요 파일 구조
```
rentre-agents/
├── CLAUDE.md                 ← 이 파일
├── org-chart.md              ← 조직도
├── executive/                ← CEO, 비서 에이전트 정의
├── tech/                     ← Tech 팀 에이전트 정의
├── business/                 ← Business 팀 에이전트 정의
├── templates/                ← BMAD-inspired 구조화 템플릿
│   ├── prd.md               ← PRD 문서 템플릿
│   ├── architecture.md       ← 아키텍처 문서 템플릿
│   ├── story.md             ← 유저 스토리 템플릿
│   └── checklist.md         ← 단계별 검증 게이트
├── scripts/
│   ├── start-agent.sh        ← tmux 세션 시작
│   ├── renew-agent.sh        ← 주간 자동 갱신
│   ├── setup-crontab.sh      ← crontab 등록
│   ├── init-prompt.txt       ← Claude Code 초기 프롬프트
│   └── windows-startup.bat   ← Windows 시작 프로그램
├── cron-prompts/
│   ├── daily-briefing.md     ← 데일리 브리핑 프롬프트
│   ├── adr-monitor.md        ← ADR 모니터링 프롬프트
│   └── market-news.md        ← 마켓/뉴스 프롬프트
└── shared-commands/
    ├── install.sh            ← 전사 설치 스크립트
    ├── quick-install.sh      ← curl 원클릭 설치
    ├── README.md             ← 사용법 가이드
    └── rentre/               ← 글로벌 커맨드 원본 (16개)
```

## 개발 방법론 (BMAD-Enhanced)
- 애자일 (Scrum/Kanban) + BMAD Method 워크플로우
- PRD 수신 시: 10라운드 토론 → PRD Doc → Architecture Doc → Story 분해 → 백로그
- 단계별 Validation Gate (5개 검증 체크포인트 + PO 검증 + QA 리뷰)
- Risk-Based Testing 전략 (리스크 매트릭스 기반 테스트 배치)
- TDD (Test-Driven Development) 필수
- E2E 테스트는 Playwright 필수
- Adversarial Review + Edge Case Hunt 연동
- PR에 토론 결과 + 문서 + 테스트 결과 포함
- 프로젝트 타입: Greenfield(신규) / Brownfield(기존 확장) / Hotfix(긴급)

## 개발 파이프라인 (9 Stages)
```
Stage 1: 10 Round Debate → Stage 2: Synthesis
→ Stage 3: PRD Doc → Gate 1
→ Stage 4: Architecture Doc → Gate 2
→ Stage 5: Story Breakdown → Gate 3
→ Stage 6: TDD Development → Gate 4
→ Stage 7: E2E (Playwright) → Gate 5
→ Stage 8: PR Creation → Stage 9: Retrospective
```

## 템플릿 (templates/)
- prd.md: 문제 정의, JTBD, MoSCoW, AC, 리스크
- architecture.md: 기술 스택, 시스템 구조, 데이터 모델, API, 보안
- story.md: User Story, AC(Gherkin), TDD 계획, 엣지 케이스
- checklist.md: 5개 Validation Gate 체크리스트

## 토론 패널 (5명)
- CTO: 기술 전략, 아키텍처
- Backend Lead: API/DB/성능
- Frontend Lead: UX/UI
- PM: 비즈니스 가치, ROI
- Agile Coach: 일정, 리스크

## 팀원 캘린더 매핑
- stephen@rentre.kr (primary) - 정재우
- jmpark@rentre.kr - 박재만
- hdseo@rentre.kr - 서현동
- Rent're - Meeting: 사내 미팅
- Rent're - Official schedule: 공식 일정

## 전사 배포
- shared-commands/ 폴더를 GitHub repo로 push
- 팀원: curl 한 줄로 설치 (quick-install.sh)
- 심볼릭 링크 방식 → git pull만 하면 자동 업데이트
