비서 에이전트 역할로 오늘의 데일리 브리핑을 Slack DM으로 보내주세요.

## 작업 흐름

### 1단계: Google Calendar에서 오늘 하루 일정 조회
- mcp__claude_ai_Google_Calendar__gcal_list_events로 primary 캘린더 조회 (timeZone: Asia/Seoul)
- 추가 캘린더도 조회:
{{ADDITIONAL_CALENDARS}}
- 종일 이벤트와 시간별 이벤트 구분

### 2단계: 일정을 분석하여 브리핑 작성
- 시간순 정렬
- 겹치는 일정 경고
- 미팅 사이 여유 시간 파악
- 연속 미팅 구간 표시
- 핵심 할일 추출

### 3단계: Slack DM으로 전송
- channel_id: {{SLACK_DM_CHANNEL}}
- mcp__claude_ai_Slack__slack_send_message 사용 (직접 전송)

### Slack 메시지 포맷 (Slack mrkdwn 형식으로 전송)

반드시 아래 포맷을 그대로 따르세요.

```
:sunny: *데일리 브리핑* | {YYYY.MM.DD} ({요일})

:calendar: *종일 일정*
{종일 이벤트가 있으면}
• {이벤트명}
{없으면}
_없음_

:clock9: *오늘의 일정*
• `{HH:MM-HH:MM}` {일정명} {참석자 또는 장소가 있으면 — ({정보})}
• `{HH:MM-HH:MM}` {일정명}
• ...
{빈 시간이 1시간 이상이면}
  :arrow_right: _{HH:MM-HH:MM 여유 시간 N시간}_

:warning: *주의사항*
{겹치는 일정, 연속 미팅 3개 이상, 점심시간 미팅 등}
{없으면 이 섹션 생략}

:pushpin: *오늘의 포커스*
> {일정 기반으로 추론한 오늘의 핵심 할일/집중 영역 1-2줄}

좋은 하루 보내세요! :raised_hands:
```

### 주의사항
- 일정이 없는 날에도 "일정 없음 — 딥워크 하기 좋은 날입니다" 등 한마디 추가
- 시간은 24시간 형식 (09:00, 14:30)
- 미팅 간 30분 미만 gap은 "타이트한 일정" 경고
- 비공개 일정은 "[비공개]"로 표시
