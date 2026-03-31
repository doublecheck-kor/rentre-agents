# Rentre Agents

BMAD Framework + Rentre 업무 자동화 AI 에이전트 시스템.

> 전체 문서는 [루트 README.md](../README.md)를 참고하세요.

## 설치

### Claude Code에서 (추천)

```
rentre-agents(https://github.com/doublecheck-kor/rentre-agents) 설치하고 /rentre:setup 실행해줘
```

### 원클릭

```bash
curl -sL https://raw.githubusercontent.com/doublecheck-kor/rentre-agents/main/shared-commands/quick-install.sh | bash
```

### 수동

```bash
git clone --recurse-submodules https://github.com/doublecheck-kor/rentre-agents.git ~/.rentre-agents
bash ~/.rentre-agents/shared-commands/install.sh
# Claude Code에서 /rentre:setup 실행
```

## 설치 구조

- **글로벌** (1회): Rentre 커맨드 → `~/.claude/commands/rentre/`
- **프로젝트별**: BMAD 스킬 → 현재 프로젝트 `.claude/skills/`

다른 프로젝트에서 BMAD를 쓰려면 해당 프로젝트에서 install.sh를 한 번 더 실행하면 됩니다.

## Rentre 커맨드 (7개)

| 커맨드 | 설명 |
|--------|------|
| `/rentre:assistant` | 만능 비서 (일정, 이메일, Slack, Notion, 마켓 브리핑) |
| `/rentre:adr` | ADR 5개 관점 분석 (Notion 연동) |
| `/rentre:ailab` | AI Lab 쇼케이스 등록 (Notion + Slack) |
| `/rentre:pr-notion` | Notion 기반 PR 자동 생성 |
| `/rentre:pr-split` | 큰 변경사항 PR 분리 (600줄 미만) |
| `/rentre:help` | 통합 가이드 |
| `/rentre:setup` | 초기 설정 (MCP 자동 감지) |

## BMAD 스킬 (109개)

개발 프로세스 전체를 담당. `/bmad-help`로 전체 목록 확인.

## 업데이트

```bash
cd ~/.rentre-agents && git pull --recurse-submodules && ./shared-commands/install.sh
```

## 제거

```bash
~/.rentre-agents/shared-commands/install.sh --remove
rm -rf ~/.rentre-agents
```
