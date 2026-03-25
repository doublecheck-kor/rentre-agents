# Rentre Agent Commands

Claude Code에서 사용할 수 있는 Rentre 전사 공용 에이전트 커맨드입니다.
BMAD Method의 구조화된 워크플로우와 Rentre의 10라운드 토론을 결합한 시스템입니다.

## 설치

### 방법 1: Claude Code에서 설치 (추천)

Claude Code를 열고 이렇게 말하세요:

```
rentre-agents 설치해줘.
https://github.com/rentre-kr/rentre-agents 클론하고 설치해줘.
```

### 방법 2: 원클릭 설치

```bash
curl -sL https://raw.githubusercontent.com/rentre-kr/rentre-agents/main/shared-commands/quick-install.sh | bash
```

설치 후 Claude Code에서 `/rentre:setup`을 실행하면 MCP로 Slack/Notion/Gmail 정보를 자동 감지하여 설정합니다.

### 방법 3: 수동 설치

```bash
git clone https://github.com/rentre-kr/rentre-agents.git
cd rentre-agents/shared-commands
chmod +x install.sh
./install.sh
```

## 초기 설정

설치 후 Claude Code에서 `/rentre:setup`을 실행하세요.

- 이름, 이메일만 입력하면 나머지는 MCP로 자동 감지
- Slack ID, Notion ID, Gmail 프로필 자동 수집
- 설정 파일: `~/.claude/rentre-config.json`

## 업데이트

```bash
cd ~/.rentre-agents && git pull && ./shared-commands/install.sh
```

## 제거

```bash
./install.sh --remove
```

## 사용 가능한 커맨드

### 비서/유틸리티
| 커맨드 | 설명 | 예시 |
|--------|------|------|
| `/rentre:assistant` | 만능 비서 | `/rentre:assistant 내일 팀미팅 잡아줘` |
| `/rentre:schedule` | 일정 조회 | `/rentre:schedule 오늘 내 스케줄` |
| `/rentre:market` | 마켓/뉴스 | `/rentre:market 오늘 시장 브리핑` |
| `/rentre:slack` | Slack 연동 | `/rentre:slack #general 최근 메시지` |
| `/rentre:notion` | Notion 검색 | `/rentre:notion 스프린트 백로그` |
| `/rentre:email` | 이메일 관리 | `/rentre:email 오늘 온 메일 요약` |
| `/rentre:help` | 가이드 | `/rentre:help 다음에 뭘 해야 하지?` |
| `/rentre:setup` | 초기 설정 | `/rentre:setup` |

### 개발 프로세스 (BMAD-Enhanced)
| 커맨드 | 설명 | 예시 |
|--------|------|------|
| `/rentre:agile` | 애자일 프로세스 | `/rentre:agile [PRD] 스프린트 플래닝` |
| `/rentre:develop` | 풀사이클 개발 | `/rentre:develop [PRD] TDD+E2E+PR` |
| `/rentre:quickdev` | 빠른 개발 | `/rentre:quickdev 로그인 버그 수정` |
| `/rentre:adr` | ADR 분석 | `/rentre:adr 최근 ADR 리뷰` |

### 품질 & 리뷰
| 커맨드 | 설명 | 예시 |
|--------|------|------|
| `/rentre:qa` | QA 코드리뷰 | `/rentre:qa 이 PR 리뷰해줘` |
| `/rentre:edge` | 엣지케이스 탐색 | `/rentre:edge 결제 플로우 엣지케이스` |
| `/rentre:challenge` | 적대적 리뷰 | `/rentre:challenge 이 아키텍처 검증` |

### 기획 & 토론
| 커맨드 | 설명 | 예시 |
|--------|------|------|
| `/rentre:brainstorm` | 브레인스토밍 | `/rentre:brainstorm AI 추천 기능` |
| `/rentre:party` | 멀티에이전트 토론 | `/rentre:party --tech 캐싱 전략` |

## 개발 파이프라인

`/rentre:develop` 실행 시 9단계 파이프라인:

```
1. 10 Round Debate (5인 패널 토론)
2. Debate Synthesis (토론 결과 통합)
3. PRD Document (구조화된 요구사항)      → Gate 1 검증
4. Architecture Document (기술 설계)     → Gate 2 검증
5. Story Breakdown (유저 스토리 분해)     → Gate 3 검증
6. TDD Development (Red→Green→Refactor) → Gate 4 검증
7. E2E Test (Playwright)               → Gate 5 검증
8. PR Creation
9. Retrospective
```

## 커맨드 추가/수정

1. `shared-commands/rentre/` 디렉토리에 `.md` 파일 추가
2. PR 올리고 리뷰
3. merge 후 팀원들은 `git pull && ./shared-commands/install.sh`
