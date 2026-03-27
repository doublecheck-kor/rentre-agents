# Rentre Agent Commands

Claude Code에서 `/rentre:*` 커맨드로 사용하는 AI 에이전트 시스템입니다.

> 전체 프로젝트 문서는 [루트 README.md](../README.md)를 참고하세요.

## 설치

### 방법 1: Claude Code에서 (추천)

Claude Code를 열고:
```
https://github.com/doublecheck-kor/rentre-agents 클론하고 설치해줘
```

### 방법 2: 원클릭

```bash
curl -sL https://raw.githubusercontent.com/doublecheck-kor/rentre-agents/main/shared-commands/quick-install.sh | bash
```

### 방법 3: 수동

```bash
git clone https://github.com/doublecheck-kor/rentre-agents.git ~/.rentre-agents
bash ~/.rentre-agents/shared-commands/install.sh
```

설치 후 Claude Code에서 `/rentre:setup` 실행 — MCP로 Slack/Notion/Gmail 자동 감지.

## 커맨드 목록 (19개)

### Daily Assistant
| 커맨드 | 설명 |
|--------|------|
| `/rentre:assistant` | 만능 비서 (일정, 정보 조회, 요약, 커뮤니케이션) |
| `/rentre:schedule` | Google Calendar 일정 조회 |
| `/rentre:email` | 이메일 조회, 드래프트 작성 |
| `/rentre:market` | 마켓/뉴스 모닝 브리핑 |

### Development
| 커맨드 | 설명 |
|--------|------|
| `/rentre:develop` | 풀사이클 개발 (토론 → 설계 → TDD → E2E → PR) |
| `/rentre:quickdev` | 빠른 개발 (소규모 작업용) |
| `/rentre:agile` | 애자일 프로세스 (토론 → PRD → Architecture → 백로그) |
| `/rentre:adr` | ADR 다중 관점 분석 |

### Quality & Review
| 커맨드 | 설명 |
|--------|------|
| `/rentre:qa` | QA 코드리뷰, 품질 검증 |
| `/rentre:edge` | 엣지케이스 탐색 |
| `/rentre:challenge` | 적대적 리뷰 (스트레스 테스트) |

### Planning & Discussion
| 커맨드 | 설명 |
|--------|------|
| `/rentre:brainstorm` | 브레인스토밍 (아이디어 → 요구사항) |
| `/rentre:party` | 멀티에이전트 자유형 토론 |

### Integrations
| 커맨드 | 설명 |
|--------|------|
| `/rentre:slack` | Slack 메시지 조회/전송 |
| `/rentre:notion` | Notion 문서 검색/조회 |
| `/rentre:ailab` | AI Lab 쇼케이스 등록 |
| `/rentre:pr-notion` | Notion 기반 PR 자동 생성 |
| `/rentre:pr-split` | 큰 변경사항 PR 분리 (600줄 미만) |

### System
| 커맨드 | 설명 |
|--------|------|
| `/rentre:help` | 가이드, 워크플로우 안내 |
| `/rentre:setup` | 초기 설정 (MCP 자동 감지) |

## 커맨드 추가/수정

1. `shared-commands/rentre/` 디렉토리에 `.md` 파일 추가
2. PR 올리고 리뷰
3. merge 후: `cd ~/.rentre-agents && git pull && ./shared-commands/install.sh`

## 업데이트

```bash
cd ~/.rentre-agents && git pull && ./shared-commands/install.sh
```

## 제거

```bash
~/.rentre-agents/shared-commands/install.sh --remove
rm -rf ~/.rentre-agents
```
