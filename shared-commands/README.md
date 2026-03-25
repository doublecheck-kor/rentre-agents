# Rentre Agent Commands

Claude Code에서 사용할 수 있는 Rentre 전사 공용 에이전트 커맨드입니다.
BMAD Method의 구조화된 워크플로우와 Rentre의 10라운드 토론을 결합한 시스템입니다.

## 설치 (1분)

```bash
# 1. 이 repo를 clone
git clone git@github.com:rentre/rentre-agents.git
cd rentre-agents/shared-commands

# 2. 설치 스크립트 실행
chmod +x install.sh
./install.sh
```

끝. 이제 어떤 프로젝트에서든 `/rentre:*` 커맨드를 사용할 수 있습니다.

## 원클릭 설치

```bash
curl -sL https://raw.githubusercontent.com/rentre-kr/rentre-agents/main/shared-commands/quick-install.sh | bash
```

## 업데이트

```bash
cd rentre-agents
git pull
# 심볼릭 링크이므로 자동 반영됩니다.
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
| `/rentre:schedule` | 일정 조회 | `/rentre:schedule 박재만님 오늘 스케줄` |
| `/rentre:market` | 마켓/뉴스 | `/rentre:market 오늘 시장 브리핑` |
| `/rentre:slack` | Slack 연동 | `/rentre:slack #general 최근 메시지` |
| `/rentre:notion` | Notion 검색 | `/rentre:notion 스프린트 백로그` |
| `/rentre:email` | 이메일 관리 | `/rentre:email 오늘 온 메일 요약` |
| `/rentre:help` | 가이드 | `/rentre:help 다음에 뭘 해야 하지?` |

### 개발 프로세스 (BMAD-Enhanced)
| 커맨드 | 설명 | 예시 |
|--------|------|------|
| `/rentre:agile` | 애자일 프로세스 | `/rentre:agile [PRD] 스프린트 플래닝` |
| `/rentre:develop` | 풀사이클 개발 | `/rentre:develop [PRD] TDD+E2E+PR` |
| `/rentre:quickdev` | 빠른 개발 | `/rentre:quickdev 로그인 버그 수정` |
| `/rentre:adr` | ADR 분석 | `/rentre:adr 상조 서비스 ADR` |

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

프로젝트 타입별 자동 조절:
- **Greenfield**: 전체 10라운드 + 전체 문서 생성
- **Brownfield**: 10라운드 + 기존 코드 분석 + 영향도 분석
- **Hotfix**: 축약 3라운드 + 간소화된 게이트

## 템플릿

`templates/` 디렉토리에 구조화된 문서 템플릿:

| 템플릿 | 용도 | 사용 시점 |
|--------|------|-----------|
| `prd.md` | 요구사항 정의 | 토론 후 PRD 문서화 |
| `architecture.md` | 기술 설계 | PRD 확정 후 아키텍처 설계 |
| `story.md` | 개발 가이드 | 백로그 → 상세 Story 분해 |
| `checklist.md` | 품질 검증 | 각 Stage 전환 시 Gate 체크 |

## 커맨드 추가/수정

1. `shared-commands/rentre/` 디렉토리에 `.md` 파일 추가
2. PR 올리고 리뷰
3. merge 후 팀원들은 `git pull`만 하면 자동 반영

## 프로젝트별 커맨드

프로젝트 전용 커맨드는 각 프로젝트 repo의 `.claude/commands/` 디렉토리에 추가하세요.
해당 프로젝트에서만 사용 가능합니다.

```
my-project/
  .claude/
    commands/
      my-project-specific-command.md
```
