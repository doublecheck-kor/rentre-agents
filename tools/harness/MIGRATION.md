# Harness Migration Plan

기존 3 cron(`market-news` / `daily-briefing` / `adr-monitor`)에 harness 적용.

## 사전 조건

- [ ] `pipx install ./tools/harness` 완료
- [ ] `~/.harness/config.toml` 작성 (NOTION_TOKEN + Slack 채널 ID)
- [ ] Notion Heartbeat DB를 NOTION_TOKEN integration과 공유 (UI에서 Connections)
- [ ] `crontab -l > ~/.harness/backup/crontab.$(date +%F).txt`

## Phase 1: Shadow (알림 OFF)

### 변경 패턴

각 cron 라인 앞에 `harness-run <task> --timeout 600 --no-alert --` 를 끼워넣는다.

### crontab 변경 (`crontab -e` 로 직접 편집)

#### market-news (월~금 08:47)

**Before:**
```cron
47 8 * * 1-5 cd /home/stephen/rentre-wip/rentre-agents && /home/stephen/.local/bin/claude -p "$(cat /home/stephen/rentre-wip/rentre-agents/cron-prompts/market-news.rendered.md)" --allowedTools 'WebSearch,mcp__claude_ai_Slack__slack_send_message' >> /home/stephen/rentre-wip/rentre-agents/logs/market-news.log 2>&1 # rentre-cron-market
```

**After (shadow):**
```cron
47 8 * * 1-5 /home/stephen/.local/bin/harness-run market-news --timeout 600 --no-alert -- bash -c 'cd /home/stephen/rentre-wip/rentre-agents && /home/stephen/.local/bin/claude -p "$(cat /home/stephen/rentre-wip/rentre-agents/cron-prompts/market-news.rendered.md)" --allowedTools "WebSearch,mcp__claude_ai_Slack__slack_send_message" >> /home/stephen/rentre-wip/rentre-agents/logs/market-news.log 2>&1' # rentre-cron-market
```

#### daily-briefing (월~금 09:03)

**Before:**
```cron
3 9 * * 1-5 cd /home/stephen/rentre-wip/rentre-agents && /home/stephen/.local/bin/claude -p "$(cat /home/stephen/rentre-wip/rentre-agents/cron-prompts/daily-briefing.rendered.md)" --allowedTools 'WebSearch,mcp__claude_ai_Google_Calendar__*,mcp__claude_ai_Slack__slack_send_message' >> /home/stephen/rentre-wip/rentre-agents/logs/daily-briefing.log 2>&1 # rentre-cron-daily
```

**After (shadow):**
```cron
3 9 * * 1-5 /home/stephen/.local/bin/harness-run daily-briefing --timeout 600 --no-alert -- bash -c 'cd /home/stephen/rentre-wip/rentre-agents && /home/stephen/.local/bin/claude -p "$(cat /home/stephen/rentre-wip/rentre-agents/cron-prompts/daily-briefing.rendered.md)" --allowedTools "WebSearch,mcp__claude_ai_Google_Calendar__*,mcp__claude_ai_Slack__slack_send_message" >> /home/stephen/rentre-wip/rentre-agents/logs/daily-briefing.log 2>&1' # rentre-cron-daily
```

#### adr-monitor (월~금 08-20시 7분)

**Before:**
```cron
7 8-20 * * 1-5 cd /home/stephen/rentre-wip/rentre-agents && /home/stephen/.local/bin/claude -p "$(cat /home/stephen/rentre-wip/rentre-agents/cron-prompts/adr-monitor.rendered.md)" --allowedTools 'mcp__claude_ai_Notion__*,mcp__claude_ai_Slack__slack_send_message' >> /home/stephen/rentre-wip/rentre-agents/logs/adr-monitor.log 2>&1 # rentre-cron-adr
```

**After (shadow):**
```cron
7 8-20 * * 1-5 /home/stephen/.local/bin/harness-run adr-monitor --timeout 600 --no-alert -- bash -c 'cd /home/stephen/rentre-wip/rentre-agents && /home/stephen/.local/bin/claude -p "$(cat /home/stephen/rentre-wip/rentre-agents/cron-prompts/adr-monitor.rendered.md)" --allowedTools "mcp__claude_ai_Notion__*,mcp__claude_ai_Slack__slack_send_message" >> /home/stephen/rentre-wip/rentre-agents/logs/adr-monitor.log 2>&1' # rentre-cron-adr
```

### 적용 일정 (제안)

- Day 1 (월): market-news 적용 → 다음날 08:47 결과 확인
- Day 3 (수): daily-briefing 적용
- Day 4 (목): adr-monitor 적용 (시간당 데이터로 빠르게 검증)
- Day 5 (금): Notion Heartbeat DB 점검

### Shadow 종료 기준

- [ ] 3 작업 모두 매 실행마다 Notion row 생성
- [ ] 기존 Slack 브리핑 변동 없음
- [ ] missing-report 0건 (※ Phase 1에서는 helper 미적용이라 모든 행이 missing-report로 마크됨 — Phase 2에서 해결)

## Phase 2: 도메인 컨텍스트 + 알림 ON (Week 2)

### 2.1 prompt 수정 (도메인 컨텍스트 자기 보고)

각 `cron-prompts/*.rendered.md`의 마지막에 아래 블록 추가:

```markdown

---

## 작업 보고

작업 완료 후 다음 명령을 정확히 한 번 실행하라:

```bash
harness-heartbeat report \
  --status ok \
  --summary "<한 줄 요약: 보낸 채널/처리 건수 포함>" \
  --detail messages_sent=<숫자> \
  --detail target=<채널명>
```

만약 작업 중 일부 실패가 있었으면 `--status warn`, 핵심 실패면 `--status fail`로 보고하라.
```

그리고 crontab의 `--allowedTools` 에 `Bash(harness-heartbeat:*)` 추가.

### 2.2 알림 켜기

`--no-alert` 플래그만 제거:

```cron
47 8 * * 1-5 /home/stephen/.local/bin/harness-run market-news --timeout 600 -- bash -c '...'
```

### 2.3 검증 시나리오

```bash
# 임시 실패 cron 추가
* * * * * /home/stephen/.local/bin/harness-run test-failure -- bash -c 'exit 1'
```

→ 1분 내 Slack DM + #ax-챌린지-feed 알림 확인 후 즉시 라인 삭제.

## 롤백

### Level 1 — 단일 작업
```bash
crontab -e   # 해당 한 줄을 Before 형태로 되돌림
```

### Level 2 — 킬 스위치 (전체 일시 정지)
```bash
touch ~/.harness/disabled    # 모든 harness-run이 transparent passthrough로 동작
rm ~/.harness/disabled       # 복구
```

### Level 3 — 전체 원복
```bash
crontab ~/.harness/backup/crontab.YYYY-MM-DD.txt
```
