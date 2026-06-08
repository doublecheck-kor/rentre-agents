# 워크플로우 발굴 에이전트 — 설계 문서

| 항목 | 값 |
|------|---|
| 작성일 | 2026-06-08 |
| 작성자 | Stephen (stephen@rentre.kr) |
| 상태 | Draft (브레인스토밍 산출물) |
| 관련 Epic | [AX 챌린지 업무 자동화](https://www.notion.so/33448a03320880bb9cb2e4a24fe706e7) |
| 선행 인프라 | [Harness Observability MVP](./2026-05-21-harness-observability-design.md) |

## 요약

직원들의 실제 업무 활동(Slack·Notion·캘린더·Git)을 주 1회 관찰하여 **반복 업무 패턴**을 자동 발굴하고, "자동화 후보"를 ROI(절감 시간) 추정과 함께 Slack 리포트로 제안하는 멀티에이전트 시스템.

소스별 **스캐너 서브에이전트**가 병렬로 신호를 수집(fan-out)하고, **오케스트레이터**가 신호를 클러스터링·우선순위화하여 리포트를 생성(synthesis)한다. 구현·배포는 사람이 결정한다 (제안만, HITL 100%).

### 배경 — 왜 이 방향인가

- **목표**: 전사 AI 확산(AX) + 멀티에이전트 협업 체계 구축
- **병목**: "유스케이스 부족" — 설치는 했으나 매일 쓸 만한 자동화가 없음
- **근거**: 2026 상반기 트렌드 조사에서 MIT NANDA 결론 — GenAI 파일럿 95%가 ROI 미달, 성공한 5%의 공통점은 "챗봇이 아니라 실데이터 연결 + 백오피스 자동화". → 유스케이스를 사람이 짜내지 않고 **실데이터에서 솟아오르게** 한다.
- **트렌드 정합**: fan-out→synthesis 멀티에이전트, HITL 게이트(제안만), 기존 observability 편입은 OpenAI AgentKit·MS Foundry·Google A2A가 공통 채택한 2026 패턴과 일치.

---

## §1. 아키텍처 개요

```
[크론: 매주 금요일 16:00]
   │
   ▼
[harness-run workflow-discovery -- claude -p workflow-discovery.rendered.md]
   │   = 오케스트레이터(종합) 에이전트
   │
   ├─ Task 병렬 dispatch (fan-out) ──────────────┐
   │    ├─ slack-scanner     → 신호[] (JSON)      │
   │    ├─ notion-scanner    → 신호[] (JSON)      │  각자 자기 소스만 관찰,
   │    ├─ calendar-scanner  → 신호[] (JSON)      │  고정 스키마로 반환
   │    └─ git-scanner       → 신호[] (JSON)      │
   │                                              ┘
   ├─ 신호 취합 → 클러스터링 → 우선순위 점수화 (synthesis)
   ├─ 중복 추적 (discovery-history.jsonl) → "N주 연속" 표기
   ├─ Top 5 자동화 후보 리포트 생성
   ├─ Slack 전송 (정재우 DM)
   └─ harness-heartbeat report (관측성 자기보고)
```

### 핵심 설계 결정

| 결정 | 선택 | 근거 |
|------|------|------|
| 실행 형태 | 기존 cron-prompts 패턴 (`*.md` → `*.rendered.md` → `setup-cron-agents.sh`) | 기존 인프라 100% 재사용, 유지보수 일관성 |
| fan-out 메커니즘 | 오케스트레이터가 `Task` 도구로 4개 스캐너 병렬 호출 | 멀티에이전트 협업 목표 충족, 소스별 분석 깊이↑ |
| 스캐너↔오케스트레이터 인터페이스 | 고정 JSON 신호 스키마 | 관심사 분리(스캐너=수집, 오케스트레이터=판단) |
| 자율성 수준 | 제안만 (HITL 100%) | 신뢰 축적 전 자동 배포 배제 (YAGNI) |
| 관측성 | `harness-run` 래핑 + heartbeat | 기존 observability MVP에 편입 |

---

## §2. 스캐너 에이전트 & 신호 정의

각 스캐너는 **자기 소스만 관찰 → 고정 스키마 JSON 반환**하는 단일 책임 서브에이전트다. 판단·우선순위는 하지 않는다 (사실 수집만).

### 신호(signal) 공통 스키마

```json
{
  "source": "slack|notion|calendar|git",
  "pattern": "반복되는 업무에 대한 한 줄 서술",
  "evidence": ["근거 1 (링크/인용)", "근거 2"],
  "frequency": 5,                    // 7일 내 발생 횟수
  "actors_count": 3,                 // 관련 인원 수 (실명 아님 — 집계용)
  "team_hint": "마케팅|개발|...",     // 영향 팀 추정 (선택)
  "est_minutes_each": 15             // 1회당 추정 소요시간
}
```

> **익명화 원칙**: 스캐너는 실명을 수집할 수 있으나 신호 스키마에는 `actors_count`(집계)만 남긴다. 실명은 `evidence` 링크를 통해서만 drill-down 가능.

### 소스별 "반복" 판정 기준

| 스캐너 | 반복 신호로 보는 것 | 주요 도구 |
|--------|--------------------|----------|
| **slack-scanner** | 동일·유사 질문 반복, "이거 누가 해줘"류 수동 요청, 같은 정보 반복 검색/공유 | `slack_search_*`, `slack_read_channel` |
| **notion-scanner** | 동일 템플릿 문서 반복 생성, 정형 리포트·백로그 수기 작성, 같은 속성 반복 업데이트 | `notion-search`, `notion-fetch` |
| **calendar-scanner** | 반복 회의(특히 정보 동기화성), 정형 일정 조율 패턴 | `Calendar list_events` |
| **git-scanner** | 반복되는 PR 유형, 같은 리뷰 코멘트 반복, 정형 커밋 관습 | `gh` CLI (조직 레포 PR/리뷰 조회) |

- 각 스캐너에는 **프롬프트 지시로** 최소권한 부여 (slack-scanner는 Slack 도구만 사용하도록 지시)
- 신호가 0개여도 빈 배열 반환 (실패 아님)

---

## §3. 관찰 범위 & 프라이버시

### 관찰 범위 — 공개 영역 전사

| 포함 | 제외 |
|------|------|
| 공개 Slack 채널 | DM, 비공개 채널 |
| 회사 Notion 워크스페이스 | 개인 메일 |
| 회사 GitHub 조직 레포 | 비공개/개인 레포 |
| 정재우 본인 캘린더 | 타인 캘린더 |

**근거**: 공개 영역은 "이미 전사에 공유된" 데이터라 관찰 정당성이 높고 동의 리스크가 낮다. 비공개 영역을 동의 없이 보면 신뢰가 깨지고 AX 자체가 무너진다.

### 개인 식별 — 집계/익명

- 리포트 본문은 **팀·역할 단위 집계**로만 표기 ("마케팅팀 N명이 X 반복")
- 목적은 사람 평가가 아니라 자동화 후보 발굴 → 감시처럼 읽히지 않도록 함
- 필요 시 `evidence` 링크로 원본 추적(drill-down) 가능

---

## §4. 우선순위 점수화 & 리포트

### 점수 공식

```
weekly_minutes_saved = frequency × est_minutes_each      # 핵심 ROI 지표
priority_score       = weekly_minutes_saved
                       × reach_factor       # 영향 범위: 1명 < 1팀 < 전사 (AX 확산 가치)
                       × feasibility_factor # 구현 난이도: 상(기존 패턴 재사용) > 중(신규 커맨드) > 하(외부 연동)
```

- MIT 결론(백오피스 반복 업무 = 최대 ROI)을 `weekly_minutes_saved`로 직접 반영
- `reach_factor`로 전사 확산 가치를 점수에 녹임
- `feasibility_factor`는 오케스트레이터가 "기존 MCP/커맨드/크론으로 만들 수 있나"로 판정

### Slack 리포트 포맷 (mrkdwn, 정재우 DM)

```
:mag: *워크플로우 발굴 리포트* | 2026.06.12 (금) | 지난 7일
스캔 신호 23개 → 자동화 후보 5건 | 총 절감 추정 ~4.2시간/주

*1. [반복 PR 라벨링·리뷰어 지정]*  ⏱ ~90분/주  👥 개발팀 3명  🔧 난이도: 하
   → 같은 유형 PR에 수동으로 라벨/리뷰어 지정 반복. 기존 pr-notion 커맨드 확장으로 자동화 가능
   📎 evidence: <링크1> <링크2>  | 🔁 2주 연속 등장

... (Top 5)

:bulb: 만들고 싶은 후보가 있으면 알려주세요 — 레시피 초안을 만들어 드립니다.
```

- **"총 절감 추정 시간"을 리포트 전면에 배치** → AX 챔피언이 ROI를 한눈에 파악

### 중복 추적 (역활용)

- 지난 리포트의 제안 패턴을 `~/.harness/discovery-history.jsonl`에 기록
- 재등장 시 `🔁 N주 연속 등장`으로 표기
- 무시가 아니라 **"계속 나온다 = 자동화 시급"** 신호로 역활용 (adr-monitor 중복추적 패턴 재사용)

---

## §5. 구현 산출물 & 실행/관측성 통합

### 산출물 파일

```
cron-prompts/workflow-discovery.md            # 오케스트레이터 프롬프트 (placeholder 포함)
cron-prompts/workflow-discovery.rendered.md   # setup 시 생성 (SLACK_DM_CHANNEL 등 치환)
scripts/setup-cron-agents.sh                  # 금요일 16:00 항목 1줄 추가
```

> 스캐너는 별도 파일로 분리하지 않고 오케스트레이터 프롬프트 안에 4개 스캐너 지시문을 인라인으로 담아 `Task`로 병렬 dispatch한다 (단일 프롬프트 파일 = 기존 패턴 일관성).

### 크론 등록

```bash
0 16 * * 5  cd $AGENT_DIR && harness-run workflow-discovery -- \
   $CLAUDE_BIN -p "$(cat $PROMPTS_DIR/workflow-discovery.rendered.md)" \
   --allowedTools 'Task,Bash(git log:*),Bash(gh:*),mcp__claude_ai_Slack__*,mcp__claude_ai_Notion__*,mcp__claude_ai_Google_Calendar__*,Read,Write' \
   >> $LOGS_DIR/workflow-discovery.log 2>&1  # rentre-cron-discovery
```

### 권한 트레이드오프 (명시)

크론은 단일 프로세스라 서브에이전트가 부모 `--allowedTools`를 상속한다. 따라서 프로세스 레벨에선 전 도구를 허용하고, **논리적 최소권한은 프롬프트 지시로 강제**한다(slack-scanner엔 Slack 도구만 쓰라고 지시). OS 레벨 격리(샌드박싱)는 "자동 배포" 단계로 미룬다 (YAGNI).

### 관측성

- `harness-run`으로 감싸 실행 추적 (exit code, duration)
- 프롬프트 말미에 `harness-heartbeat report --status ok --summary ...` → 기존 observability MVP에 자연 편입

---

## §6. 검증 & 실패 처리

- **드라이런**: 프롬프트에 `{{DRY_RUN}}` 토글 — Slack 전송 대신 stdout 출력으로 첫 실행 확인
- **스캐너 독립 검증**: 각 스캐너를 단독 호출해 신호 JSON 스키마 적합성 확인 (단일 책임이라 격리 테스트 용이)
- **graceful degradation**: 소스 한 개가 실패(권한·타임아웃)해도 나머지로 리포트 생성 → `⚠️ git 신호 수집 실패` 주석. 전체 실패 아님
- **evals 씨앗 (미래)**: 리포트에 :+1:/:-1: 리액션으로 유용성 라벨 축적 → 다음 개선 입력. MVP는 수동 피드백만

---

## 범위 밖 (Out of Scope)

- **자동 레시피 생성/배포**: MVP는 제안만. 초안 생성·카탈로그 자동 등록은 신뢰 축적 후 다음 단계
- **OS 레벨 샌드박싱**: 프롬프트 지시 기반 논리적 격리로 대체
- **비공개 영역 관찰**: 동의 절차 선행 필요
- **자동 evals 루프**: 수동 피드백(리액션)으로 시작
- **직군별 27개 페르소나 에이전트화**: 본 시스템은 그 발판일 뿐, 직접 구현 대상 아님

---

## 향후 단계 (참고)

1. **신뢰 축적 후**: 자율성을 "제안 + 초안 생성"으로 상향 (레시피 draft 자동 생성)
2. **빈도 조정**: 유용성 검증 후 주 1회 → 주 3회/매일 조정 (7일 윈도우는 유지)
3. **자동 배포**: 승인 시 카탈로그/크론 자동 등록 (이때 OS 레벨 격리 도입)
4. **스캐너 풀 확장**: 조직도 27개 페르소나를 소스별/직군별 스캐너로 확장

---
> 이 가이드는 "AX 챌린지" 프로젝트의 일환으로 작성되었습니다.
