비서 에이전트 역할로 오늘의 데일리 브리핑을 Slack DM으로 보내주세요.

1단계: Google Calendar에서 오늘 하루 일정 조회
- mcp__claude_ai_Google_Calendar__gcal_list_events로 primary 캘린더 조회 (timeZone: Asia/Seoul)
- 종일 이벤트와 시간별 이벤트 구분

2단계: 일정을 분석하여 브리핑 작성
- 시간순 정렬
- 겹치는 일정 경고
- 미팅 사이 여유 시간 파악
- 핵심 할일 추출

3단계: Slack DM으로 전송
- channel_id: {{SLACK_USER_ID}} (본인 DM)
- 포맷: 날짜, 일정 테이블, 주의사항, 핵심 할일
- mcp__claude_ai_Slack__slack_send_message 사용 (드래프트 아닌 직접 전송)

브리핑 포맷:
오늘의 브리핑 | {날짜} ({요일})
- 종일 이벤트
- 시간별 일정 테이블
- 주의사항 (시간 겹침, 연속 미팅 등)
- 오늘의 핵심 할일
- 마무리 인사
