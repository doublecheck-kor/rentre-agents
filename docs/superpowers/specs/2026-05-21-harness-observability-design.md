# Harness Observability — 자동화 헬스 체크 MVP 설계

| 항목 | 값 |
|------|---|
| 작성일 | 2026-05-21 |
| 작성자 | Stephen (stephen@rentre.kr) |
| 상태 | Draft (Sub-Task #1 산출물) |
| 관련 Story | [자동화 헬스 체크 MVP](https://www.notion.so/36748a0332088114b0dde25e7d84465d) |
| 관련 Epic | [RPB-6923 AX 챌린지 업무 자동화](https://www.notion.so/33448a03320880bb9cb2e4a24fe706e7) |

## 요약

Rentre의 cron 자동화(morning-brief / daily-brief / adr-monitor)와 임시 자동화 실행을 **외부 시그널(exit code, duration) + 자기 보고(self-report)**로 동시에 관측하고, 실패/누락 시 Slack으로 즉시 알리는 시스템. 엔진은 generic(`harness-*`), 백엔드/알림은 인터페이스로 분리해 Rentre 외에서도 재활용 가능.

---

## §1. 아키텍처 개요

### 컴포넌트

| 이름 | 형태 | 역할 |
|------|------|------|
| `harness-run` | Python CLI | 자동화를 감싸는 외부 래퍼. 시작/종료/exit code/duration을 baseline으로 기록 |
| `harness-heartbeat` | Python CLI + SDK | 자동화 **내부**에서 호출하는 자기 보고 helper |
| Heartbeat DB | Notion DB (신규) | 모든 실행 기록의 중앙 저장소 + 대시보드 |
| 로컬 미러 | `~/.harness/state.jsonl` | append-only 로그. Notion 장애 시 fallback |
| Alert dispatcher | `harness-run` 내부 모듈 | 실패 감지 시 Slack DM/채널 푸시 |

### 데이터 흐름

```
[cron / 사용자]
   │
   ▼
[harness-run morning-brief -- /path/to/script.sh]
   ├─ Notion DB에 baseline row 생성 (status=running)
   ├─ ~/.harness/state.jsonl 에 open 라인 append
   ├─ env export → 자식 spawn
   │     └─ /path/to/script.sh
   │           └─ (스크립트 끝) harness-heartbeat report --status ok --summary ...
   │                 └─ Backend.patch_report() → Notion row 갱신
   ├─ 자식 종료 → exit code 캡처
   ├─ GRACE 5초 (self-report 폴링)
   ├─ FINALIZE: row 업데이트 + JSONL close 라인
   └─ ALERT: 실패 상태면 Slack 발송
```

### 추상화 레이어

```
┌──────────────────────────────────────────────────────┐
│  harness engine (generic)                            │
│  state machine + Backend protocol + Alerter protocol │
└──────────────────────────────────────────────────────┘
            ▲                       ▲
   ┌────────┴────────┐     ┌────────┴────────┐
   │ NotionBackend   │     │ SlackAlerter    │
   │ (Rentre config) │     │ (Rentre config) │
   └─────────────────┘     └─────────────────┘
```

`harness/` 패키지는 향후 별도 repo로 추출 가능. v1은 `rentre-agents/tools/harness/`에 동거.

---

## §2. Notion Heartbeat DB 스키마

### 컬럼 정의

| # | 속성명 | 타입 | MVP | 설명 |
|---|-------|------|-----|------|
| 1 | **실행** (Title) | Title | ✅ | `{작업명} — {시작시각KST} — {상태}` |
| 2 | 작업 종류 | Select | ✅ | `morning-brief` / `daily-brief` / `adr-monitor` / `manual-*` / `ad-hoc` |
| 3 | 상태 | Select | ✅ | `running` / `ok` / `warn` / `fail` / `missing-report` / `timeout` |
| 4 | 시작 시각 | Date(with time) | ✅ | KST |
| 5 | 종료 시각 | Date(with time) | ✅ | running 중이면 빈 값 |
| 6 | 소요(초) | Number | ✅ | `end - start` |
| 7 | Exit Code | Number | ✅ | wrapper 캡처 (timeout=124) |
| 8 | 사용자 | Text | ✅ | `stephen@rentre.kr` (멀티유저 대비) |
| 9 | 호스트 | Text | ✅ | hostname |
| 10 | 트리거 | Select | ✅ | `cron` / `manual` / `schedule` / `event` |
| 11 | 요약 | Rich Text | ✅ | helper `--summary` 값 |
| 12 | 도메인 컨텍스트 | Rich Text | ⚪ | helper `--detail` JSON |
| 13 | stdout 마지막 5줄 | Rich Text | ✅ | wrapper 캡처. 실패 진단용 |
| 14 | 로그 파일 | URL | ⚪ | `file://~/.harness/logs/{task}/{ts}.log` |
| 15 | Slack 알림 ID | Text | ⚪ | 디바운싱 update용 |
| 16 | rentre-agents 버전 | Text | ⚪ | git SHA short |

### Select 색상

```
상태:  running=gray / ok=green / warn=yellow / fail=red / missing-report=orange / timeout=red
트리거: cron=blue / manual=purple / schedule=blue / event=gray
```

### 뷰 (4개)

| 뷰 | 필터 | 정렬 | 그룹 |
|------|------|------|------|
| 오늘 | 시작 시각 = today | 시작 시각 DESC | — |
| 최근 7일 | 시작 시각 ≥ today − 7d | 시작 시각 DESC | 작업 종류 |
| 실패만 | 상태 ∈ {fail, missing-report, timeout} AND 시작 시각 ≥ today − 30d | 시작 시각 DESC | — |
| 작업별 | 시작 시각 ≥ today − 14d | 시작 시각 DESC | 작업 종류 |

### 보존 정책

- Notion row: 주 1회 정리 cron이 `시작 시각 < today − 90d` 행 archive
- 로컬 JSONL: 월 단위 압축 `~/.harness/archive/YYYY-MM.jsonl.gz`

---

## §3. `harness-run` 래퍼 동작 명세

### 3.1 CLI

```
harness-run <task-name> [OPTIONS] -- <command> [args...]
```

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `--timeout SEC` | 없음 | 하드 타임아웃 (SIGTERM → 5s grace → SIGKILL) |
| `--label k=v` | (반복) | 정적 라벨. 도메인 컨텍스트 머지 |
| `--trigger {cron\|manual\|schedule\|event}` | auto | 미지정 시 자동 감지 |
| `--grace-secs N` | 5 | 자식 종료 후 self-report 대기 시간 |
| `--no-notion` | false | Notion write 스킵 (로컬 only) |
| `--no-alert` | false | Alert dispatcher 호출 스킵 |
| `--dry-run` | false | 실행 안 함, 계획 출력 |
| `--config PATH` | `~/.harness/config.toml` | 설정 위치 |

자식 명령은 `--` 뒤에 그대로. `subprocess.Popen`으로 spawn (셸 해석 X).

### 3.2 상태 머신

```
INIT → BASELINE → EXEC → CHILD_EXIT → GRACE → FINALIZE → ALERT → EXIT
```

- **INIT**: argv 파싱, RUN_ID(UUID v7) 생성, config 로드
- **BASELINE**: Notion row 생성 (status=running), JSONL open, env export
- **EXEC**: subprocess.Popen, stdout/stderr tee + 로그 파일, ring buffer 200줄
- **CHILD_EXIT**: exit_code/duration 캡처, status 1차 산정
- **GRACE**: `--grace-secs`동안 self-report 폴링 (1초 간격)
- **FINALIZE**: row 업데이트, JSONL close
- **ALERT**: 실패 상태면 Alerter.notify
- **EXIT**: 자식과 같은 exit_code로 종료 (래퍼 투명)

### 3.3 환경변수 계약

| env | 용도 |
|-----|------|
| `HARNESS_RUN_ID` | row 식별. 없으면 helper standalone |
| `HARNESS_TASK` | mismatch 검증 |
| `HARNESS_START_TS` | 디버깅 |
| `HARNESS_BACKEND_REF` | Notion DB ID. helper가 config 안 읽고 patch 가능 |
| `HARNESS_HOST` | standalone 일관성 |
| `HARNESS_CONFIG_PATH` | config 경로 override |

### 3.4 시그널 처리

| 시그널 | 동작 |
|--------|------|
| SIGINT | 자식 전파, status=fail, exit 130 |
| SIGTERM | 자식 전파, 5s grace, SIGKILL, status=fail, exit 143 |
| SIGHUP | 무시 (cron + nohup 호환) |
| 타임아웃 | SIGTERM → 5s → SIGKILL, status=timeout, exit 124 |

**FINALIZE는 반드시 통과** — row가 영원히 `running`으로 남지 않도록.

### 3.5 로컬 JSONL 미러

`~/.harness/state.jsonl` append-only:

```json
{"type":"open","run_id":"...","task":"morning-brief","start_ts":"...","host":"...","user":"...","trigger":"cron","notion_row_id":"..."}
{"type":"close","run_id":"...","end_ts":"...","duration_s":42,"exit_code":0,"status":"ok","summary":"...","detail":{...},"alert_sent":false}
```

### 3.6 Notion 장애 대응

| 시점 | 장애 | 동작 |
|------|------|------|
| BASELINE | 5xx/timeout | stderr 경고, notion_row_id=null, 자식 실행 계속 |
| FINALIZE | 5xx/timeout | 5초 1회 재시도 → 실패 시 JSONL `pending_sync=true` |
| (v1.1) | — | reconcile cron으로 pending 행 push |

**핵심 원칙**: 관측은 best-effort. 자식 명령의 실행/종료 코드는 영향받지 않음.

### 3.7 구현

- 언어: Python 3.11+
- 위치: `rentre-agents/tools/harness/src/harness/cli.py` (entry: `harness-run`)
- 배포: `install.sh`가 pipx로 설치 → `harness-run`, `harness-heartbeat` PATH 노출
- 의존성: stdlib + `requests`
- 테스트: pytest, 4 케이스 (happy / non-zero / timeout / notion-down)

### 3.8 사용 예

```bash
# cron 변경
47 8 * * 1-5 harness-run morning-brief --timeout 600 -- /home/stephen/rentre-agents/cron/morning-brief.sh

# 수동
harness-run manual-data-import --label source=notion-bulk -- python scripts/import_users.py
```

### 3.9 결정 사항

| 결정 | 내용 |
|------|------|
| stdout tee | 기본 tee (cron 환경에 영향 없음) |
| 멀티호스트 동시 실행 가드 | v1 미포함 (v1.1) |
| 인터프리터 | pipx 설치, entry_points로 노출 |

---

## §4. `harness-heartbeat` self-report 명세

### 4.1 역할

`harness-run`은 외부 시그널(exit/duration)만 잡음. **자동화 내부에서만 알 수 있는 도메인 컨텍스트**(Slack 채널/글자수, API 응답 개수 등)는 자기 보고가 유일한 통로.

### 4.2 CLI

```
harness-heartbeat report [OPTIONS]
```

| 옵션 | 필수 | 설명 |
|------|------|------|
| `--status {ok\|warn\|fail}` | ✅ | 자기 진단 |
| `--summary "..."` | ✅ | 사람이 읽는 한 줄 |
| `--detail k=v` | ⚪ (반복) | 구조화 컨텍스트 |
| `--detail-json '{}'` | ⚪ | 자유 JSON |
| `--task TASK` | (standalone) | RUN_ID 없을 때 작업명 |
| `--config PATH` | ⚪ | wrapper와 동일 |

**status 의미**:
- `ok`: 모든 핵심 단계 성공
- `warn`: 핵심 성공, 부분 실패 있음
- `fail`: 자기 보고 시점에 실패 선언 (drop된 예외 등)

### 4.3 동작 모드

#### Mode A — wrapped

`HARNESS_RUN_ID` 존재 → row patch만.

#### Mode B — standalone

env 없음 → `--task` 필수, 새 row open + close 즉시 (`trigger=manual`).

### 4.4 도메인 컨텍스트 JSON 스키마 (권장)

```json
{
  "counts": { "items_processed": 12, "items_failed": 0, "slack_messages_sent": 2, "notion_pages_created": 1 },
  "targets": ["#ax-챌린지-feed", "D07S7RE6TK4"],
  "duration_breakdown_ms": { "fetch": 1200, "render": 340, "send": 890 },
  "notes": ["adr-monitor: 신규 멘션 0건"]
}
```

Backend는 그대로 Rich Text(코드블록)로 직렬화.

### 4.5 Python SDK

```python
from harness import heartbeat

# 일회성
heartbeat.report(status="ok", summary="...", detail={"slack_messages_sent": 2})

# 컨텍스트 매니저 (예외 → 자동 fail)
with heartbeat.track("data-import") as hb:
    hb.add(items_processed=10)
    do_work()
    hb.summary("총 N건 import 완료")
```

context manager는 wrapper 없는 단독 호출 시 유용.

### 4.6 Multi-report 머지

| 필드 | 정책 |
|------|------|
| status | **악화 방향만**: ok→warn→fail. fail에서 회복 X |
| summary | 최신 덮어쓰기 |
| detail | deep merge: counts 누적, targets union, notes append |
| 보고 이력 | 별도 필드에 timestamp + summary 누적 |

### 4.7 에러 처리

| 케이스 | 동작 |
|--------|------|
| `HARNESS_RUN_ID` 있는데 row 없음 | warning + standalone fallback (--task 필요) |
| Backend timeout | stderr 경고, exit 0 (자동화 보호) |
| `--status fail` + summary 없음 | summary 필수 → exit 1 |
| RUN_ID/HARNESS_TASK mismatch | warning, 계속 |

**원칙**: helper 호출 실패는 자동화를 망치지 않음.

### 4.8 결정 사항

| 결정 | 내용 |
|------|------|
| Traceback 자동 첨부 | 기본 OFF, opt-in (`capture_traceback=True`). PII 누출 우려 |
| `warn` 상태 유지 | 부분 실패 빈도가 충분히 잦음 |

---

## §5. Alert dispatcher / missing-report 정책

### 5.1 트리거 매트릭스

| exit_code | self-report | 최종 status | 알림? |
|-----------|-------------|------------|-------|
| 0 | ok | ok | ❌ |
| 0 | warn | warn | ⚠️ (default ON) |
| 0 | fail | fail | ✅ |
| 0 | (없음) | missing-report | ✅ |
| 124 | any | timeout | ✅ |
| 기타 non-zero | any | fail | ✅ (exit code 우선) |

**원칙**:
1. exit_code != 0 → 무조건 fail (self-report ok여도)
2. exit_code 0 + report 없음 → missing-report
3. self-report fail → 즉시 fail (자기 진단 신뢰)

### 5.2 AlertEvent

```python
@dataclass
class AlertEvent:
    run_id: str
    task: str
    status: Literal["fail", "warn", "missing-report", "timeout"]
    started_at: datetime
    ended_at: datetime
    duration_s: int
    exit_code: int | None
    host: str
    summary: str | None
    detail: dict | None
    stdout_tail: list[str]
    backend_row_url: str
    repeat_count: int
```

### 5.3 Slack 메시지 포맷

```
{emoji} *{task}* — {status}

• 시각: 2026-05-21 08:47:00 KST (42s)
• Host: stephen-wsl
• Exit: 1

> {summary 또는 "(self-report 없음)"}

```
{stdout_tail joined}
```

📊 <{backend_row_url}|Notion row> · 🔁 {repeat_count}건째
```

이모지: fail=🔴 / timeout=⏱️ / missing-report=🟠 / warn=🟡

### 5.4 발송 채널

| 상태 | DM | Broadcast |
|------|----|-----------|
| fail / timeout / missing-report | ✅ | ✅ |
| warn | ✅ | ❌ |

config:
```toml
[alerter.slack]
dm_channel = "D07S7RE6TK4"
broadcast_channel = "<#ax-챌린지-feed 채널 ID — Open Decisions 참조>"
```

### 5.5 디바운싱

- **키**: `(task, status)`
- **윈도우**: 5분
- **저장**: `~/.harness/alerts.json` (flock 보호)

같은 키 5분 내 재발 → `chat.update`로 기존 메시지 in-place 갱신 (count++).

### 5.6 글로벌 rate limit

시간당 max 10건. 초과분은 skip + `alert_skipped=true` 마킹. 1시간 1번 메타 알림 발송.

### 5.7 Alerter 실패

| 케이스 | 동작 |
|--------|------|
| Slack 5xx | 2초 1회 재시도 → 실패 시 stderr + JSONL 마킹 |
| 채널 ID 무효 | broadcast로 폴백 |
| 모두 실패 | `~/.harness/pending-alerts.jsonl` append |
| chat.update 실패 | 새 메시지 fallback |

**자동화 exit code는 영향 X.**

### 5.8 missing-report 감지

별도 워커 불필요. wrapper의 GRACE 단계 폴링이 동기적으로 감지.  
예외: wrapper OOM 시 row 영구 `running`. v1 수동 청소, v1.1 reconcile cron.

### 5.9 회복 알림

v1 비포함 (직전 row lookup 복잡도). v1.1 후보.

### 5.10 결정 사항

| 결정 | 내용 |
|------|------|
| warn broadcast | 기본 OFF, config로 ON 가능 |
| 디바운스 윈도우 | 5분 유지 |
| alerts.json 동시성 | fcntl flock 사용 |

---

## §6. 마이그레이션 플랜

### 6.1 원칙

1. 기존 자동화 코드 0줄 수정 (helper 호출 1줄 추가는 별도)
2. cron 독립 마이그레이션 — 동시 변경 X
3. 항상 롤백 가능 (crontab 1줄 revert)
4. 두 단계 게이트: shadow (알림 OFF) → active (알림 ON)
5. 킬 스위치: `~/.harness/disabled` 파일

### 6.2 Week 0 — 사전 준비

- [ ] `harness-run --help`, `harness-heartbeat --help` 동작
- [ ] Notion Heartbeat DB 생성, write 권한 확인
- [ ] `~/.harness/config.toml` 작성 (backend/alerter)
- [ ] Smoke test:
      - `harness-run smoke-test -- echo hello` → row 생성, 알림 X
      - `harness-run smoke-fail -- bash -c 'exit 1'` → row + DM 1건
- [ ] **cron 인벤토리 채우기** (현재 crontab 라인과 스크립트 위치 확인) → §6.3 표
- [ ] crontab 백업: `crontab -l > ~/.harness/backup/crontab.$(date +%F).txt`

### 6.3 마이그레이션 대상 인벤토리

> Week 0에서 다음 표를 채운다.

| # | 작업명 | 스케줄 | 현재 crontab 라인 | 스크립트 경로 |
|---|--------|--------|-------------------|---------------|
| 1 | morning-brief | 평일 08:47 | TBD | TBD |
| 2 | daily-brief | 평일 09:03 | TBD | TBD |
| 3 | adr-monitor | 평일 08-20 매시 | TBD | TBD |

### 6.4 Phase 1 — Shadow (Week 1, 알림 OFF)

```bash
# crontab 변경 패턴
47 8 * * 1-5 harness-run morning-brief --timeout 600 --no-alert -- /path/to/morning-brief.sh

# 스크립트 끝에 defensive helper 호출
command -v harness-heartbeat >/dev/null 2>&1 && \
  harness-heartbeat report --status ok --summary "마켓/뉴스 브리핑 발송 완료" \
    --detail slack_messages_sent=2 || true
```

**롤아웃 일정**:
- Day 1 (월): morning-brief
- Day 3 (수): daily-brief
- Day 4 (목): adr-monitor
- Day 5 (금): Heartbeat DB 점검

**Shadow 종료 기준**:
- [ ] 3 작업 모두 매 실행마다 row 생성
- [ ] 기존 Slack 브리핑 내용 변동 0
- [ ] 평균 wrapper overhead < 2초
- [ ] missing-report 0건

### 6.5 Phase 2 — Active (Week 2, 알림 ON)

`--no-alert` 제거.

**검증 시나리오 (Week 2 Day 1)**:
1. 임시 cron `test-failure` — 의도적 `exit 1`
2. 1분 내 DM + #ax-챌린지-feed 알림 확인
3. 같은 cron 1분 뒤 재실행 → 디바운스 확인 ("🔁 2건째")
4. helper 누락 시뮬레이션 → 5분 후 missing-report 알림
5. 검증 후 test-failure cron 즉시 제거

**Active 종료 기준** (1주 운영):
- [ ] False positive 0
- [ ] False negative 0
- [ ] 알림 피로도 정량화 (행동 유발 비율)

### 6.6 롤백 절차

**Level 1 — 단일 작업**: crontab 1줄 revert (helper 호출은 가드로 안전)

**Level 2 — 킬 스위치**: `touch ~/.harness/disabled` → wrapper는 transparent passthrough

**Level 3 — 전체**: `crontab ~/.harness/backup/crontab.YYYY-MM-DD.txt`

### 6.7 위험 시나리오

| 위험 | 가능성 | 영향 | 대응 |
|------|--------|------|------|
| wrapper 버그로 자식 실패 | Low | High | smoke test, --no-notion 폴백, kill switch |
| Notion 5xx로 cron 지연 | Medium | Medium | 5초 timeout, 로컬만 기록 |
| helper 호출이 스크립트 break | Low | High | `command -v` 가드 + `\|\| true` |
| Slack rate limit | Low | Low | 디바운싱 + 글로벌 limit |
| alerts.json 손상 | Very Low | Low | flock, 손상 시 리셋 |
| wrapper OOM → 영구 running row | Very Low | Low | v1.1 reconcile, v1은 수동 |

### 6.8 Phase 3 — 회고

Sub-Task #7로 이행:
- Week 1-2 데이터 회고
- 놓친 실패 / 오탐 / 알림 피로도 수치화
- 작은 수정 즉시, 큰 건은 follow-up Sub-Task
- 본 문서에 "운영 결과" 섹션 추가
- PR 머지 + AX 챌린지 채널 사례 공유

### 6.9 결정 사항

| 결정 | 내용 |
|------|------|
| 시작 요일 | 월요일 (즉시 피드백 확보) |
| test-failure cron | 검증 시 임시 추가, 즉시 제거 |
| disabled 파일 stat 비용 | 무시할만함 |

---

## Open Decisions (구현 착수 전 확정 필요)

| ID | 항목 | 차단 대상 |
|----|------|----------|
| OD-1 | Heartbeat DB의 Notion 위치 (AX 챌린지 하위 / `_bmad/` 하위 / 별도) | Sub-Task #2 |
| OD-2 | DB 공개 범위 (workspace 전체 read / Tech 스쿼드만) | Sub-Task #2 |
| OD-3 | Slack 알림 ID 보존 기간 (디바운싱용, 권장 7일) | Sub-Task #3 |
| OD-4 | `#ax-챌린지-feed` 채널 ID 획득 | Sub-Task #5 |

---

## 향후 작업 (v1.1+)

- 추가 Backend 구현 (SQLite / Postgres)
- 추가 Alerter 구현 (Email / Discord)
- Reconcile cron — 영구 `running` row 자동 정리
- 회복 알림 (recovered)
- 멀티호스트 동시 실행 가드
- 자동 추출 → 별도 repo `harness-run`으로 분리

---

> 이 가이드는 "AX 챌린지" 프로젝트의 일환으로 작성되었습니다.
