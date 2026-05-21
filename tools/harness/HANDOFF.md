# Harness — 핸드오프 (당신이 할 일)

대부분 빌드가 끝났습니다. 아래 4단계만 사람이 직접 해주면 운영에 들어갑니다.

| 단계 | 소요 | 위험도 |
|------|------|--------|
| 1. Notion 권한 부여 | 1분 | 매우 낮음 |
| 2. Slack 자격증명 설정 | 5분 | 낮음 |
| 3. Shadow 마이그레이션 (월요일) | 5분 + 1주 관찰 | 낮음 (롤백 간단) |
| 4. Active 전환 (다음주 월요일) | 1분 + 1주 관찰 | 낮음 |

---

## 1. Notion Heartbeat DB를 integration과 공유

**왜 필요한가**: `harness-run`은 `NOTION_TOKEN`(custom integration)으로 Notion API를 호출하는데, 새로 만든 DB는 기본으로 integration과 공유되지 않습니다. 현재 401 Unauthorized.

**할 일**:

1. 브라우저로 열기: https://www.notion.so/245fb77268724fd49af093403543883e
2. 우상단 `···` → **Connections** (또는 한국어 UI에서 "연결")
3. `NOTION_TOKEN`이 가리키는 integration 선택 → "Add" / "추가"
4. 검증:
   ```bash
   source ~/.env && NOTION_TOKEN=$NOTION_TOKEN harness-run smoke-test --no-alert -- echo "권한 확인"
   ```
   → `[notion] open failed` 메시지가 사라지면 OK.

> 어떤 integration 이름을 골라야 할지 모르겠으면 `~/.env`의 `NOTION_TOKEN` 값 앞 8자리를 Notion 설정 → "내 통합"에서 확인할 수 있습니다.

---

## 2. Slack 자격증명 설정

**왜 필요한가**: 알림 발송용. 두 가지 옵션이 있고 **bot token 권장** (디바운싱 in-place 업데이트가 됨).

### Option A — Bot Token (권장)

1. https://api.slack.com/apps → "Create New App" → "From scratch"
2. App name: `Harness Alerter` (또는 원하는 이름) / Workspace: 렌트리
3. **OAuth & Permissions** → Bot Token Scopes 추가:
   - `chat:write` (메시지 발송)
   - `chat:write.public` (안 들어간 채널에도 발송)
4. "Install to Workspace" → Bot User OAuth Token (`xoxb-...`) 복사
5. `#ax-챌린지-feed` 채널에 봇 초대: `/invite @Harness Alerter`
6. `~/.harness/config.toml` 편집:
   ```toml
   [alerter.slack]
   bot_token = "xoxb-..."
   dm_channel = "D07S7RE6TK4"
   broadcast_channel = "C0AMRSL1QSJ"
   ```

### Option B — Webhook (간단, 디바운싱 갱신 X)

이미 `~/.env`에 `SLACK_WEBHOOK_URL_PROD` / `SLACK_WEBHOOK_URL_DEV` 가 있습니다.

```toml
[alerter.slack]
webhook_url = "<PROD or DEV 둘 중 하나>"
dm_channel = "D07S7RE6TK4"
broadcast_channel = "C0AMRSL1QSJ"
```

> Webhook은 채널이 하나로 고정됩니다. DM + broadcast를 별도로 보내고 싶으면 Option A를 쓰세요.

### 검증

의도적 실패로 알림 동작 확인:

```bash
source ~/.env && NOTION_TOKEN=$NOTION_TOKEN \
  harness-run alert-test --grace-secs 0 -- bash -c 'exit 1'
```

→ Slack DM (Stephen) + #ax-챌린지-feed 양쪽에 🔴 알림 도착하면 OK.

---

## 3. Shadow 마이그레이션 (Week 1 — 알림 OFF)

`tools/harness/MIGRATION.md` 의 **Phase 1** 섹션을 보고 `crontab -e`로 3개 라인을 차례차례 변경.

권장 일정:

- **다음 월요일**: market-news 라인 변경
- **다음 수요일**: daily-briefing 변경
- **다음 목요일**: adr-monitor 변경 (시간당 데이터로 빠른 검증)
- **금요일**: Notion Heartbeat DB의 "최근 실행" 뷰 점검 → 3종이 모두 매번 row를 만드는지 확인

> Phase 1에서는 helper(harness-heartbeat) 호출이 없어서 모든 row가 `missing-report` 상태로 나옵니다. 정상입니다 — Phase 2에서 helper 호출을 prompt에 넣어서 해결합니다.

---

## 4. Active 전환 (Week 2 — 알림 ON)

`MIGRATION.md` 의 **Phase 2** 를 보고:

1. **2.1**: 각 `cron-prompts/*.rendered.md` 끝에 helper 호출 블록 추가 + `--allowedTools`에 `Bash(harness-heartbeat:*)` 추가
2. **2.2**: crontab 3 라인에서 `--no-alert` 제거
3. **2.3**: 임시 cron `test-failure`로 알림 도착 확인 → 즉시 삭제

---

## 종료 후 회고 (Sub-Task #7)

운영 1주 후, Notion DB 데이터로:
- 놓친 실패 / 오탐 / 알림 피로도 정량화
- 필요한 follow-up Sub-Task 등록
- `docs/superpowers/specs/2026-05-21-harness-observability-design.md` 에 "운영 결과" 섹션 추가
- PR 생성 (`/rentre:pr-notion`) → 머지 → push (이때 VERSION 업데이트 + #ax-챌린지-feed 사례 공유)

---

## 자료

| 항목 | 위치 |
|------|------|
| 설계 문서 | `docs/superpowers/specs/2026-05-21-harness-observability-design.md` |
| harness 패키지 | `tools/harness/` |
| 설치 스크립트 | `tools/harness/install-harness.sh` |
| 마이그레이션 가이드 | `tools/harness/MIGRATION.md` |
| Notion Heartbeat DB | https://www.notion.so/245fb77268724fd49af093403543883e |
| Story (Notion) | https://www.notion.so/36748a0332088114b0dde25e7d84465d |
| Epic (Notion) | https://www.notion.so/33448a03320880bb9cb2e4a24fe706e7 |

## 비상 시

```bash
# 전체 일시 정지 (모든 자동화는 그대로 돌고, 관측만 끔)
touch ~/.harness/disabled

# 복구
rm ~/.harness/disabled

# 완전 원복 (crontab을 변경 전으로)
crontab ~/.harness/backup/crontab.<YYYY-MM-DD>.txt
```
