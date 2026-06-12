제품 부문 주간 WIP/리드타임 리포트를 생성하여 Notion DB 및 Weekly Sync 페이지에 입력하세요.

## 작업 흐름

### 1단계: 백로그 DB에서 Track A WIP 일감 조회

**데이터 소스**: `collection://f7a3fc56-6ec9-4620-a6f9-e70586a94cc0` (백로그)

**필터 조건**:
- 일감 유형 ∈ {Epic, Story, Discovery} (Track A만)
- 상태 ∈ {In progress, Testing, Review, Blocked}

**방법**:
1. `mcp__claude_ai_Notion__notion-search`의 `ai_search` 모드로 `data_source_url` 지정하여 검색
2. 개별 `mcp__claude_ai_Notion__notion-fetch`로 속성 확인 (상태, 스쿼드, 일감 유형, 담당자)
3. 조건에 맞는 일감만 필터링
4. 스쿼드별 WIP 건수 및 SP 합계 집계
5. 스쿼드: Activation, Conversion, Product, Tech, PD

### 2단계: 리드타임 측정 (상태 변경 기록 DB)

**데이터 소스**: `collection://1ec48a03-3208-8010-a814-000b2de06429` (상태 변경 기록)

1. 최근 2주간 Done/Ready for Release 상태의 레코드 검색 (Track A 일감)
2. 각 레코드의 `백로그 관계`로 원본 백로그 fetch
3. 상태 변경 이력 추적: 첫 In progress → Done 간 일수 계산
4. P85(85번째 백분위수), 중앙값, 평균 산출

### 3단계: 주간 처리량

- 이번 주(월~일) Done/Ready for Release 도달한 일감 수
- 스쿼드별 완료 건수 및 SP 합계

### 4단계: 정체 일감 Top 3

- In progress/Testing/Review/Blocked 상태에서 가장 오래 머문 Epic/Story/Discovery 3개

### 5단계: 전달

#### 5-1. Slack DM 전송
- `slack_send_message` 도구 사용
- 채널: D07S7RE6TK4 (정재우 DM)

#### 5-2. Notion Weekly Sync 페이지 업데이트
- 스탠드업 미팅 DB(`collection://2feb5de0-4edf-46bc-a503-26e9483e1470`)에서 해당 주 `[Weekly Sync] 제품 부문` 페이지 검색
- 해당 페이지의 `⚠️ WIP, 리드타임` 섹션에 리포트 삽입
- 페이지 없으면 Slack DM으로만 전송

#### 5-3. Notion 제품 부문 전용 DB 업데이트
- Data source: `collection://33a48a03-3208-8102-908c-000b574072a1` (리드타임/WIP 제품 부문 전용)

```json
{
  "parent": {"data_source_id": "33a48a03-3208-8102-908c-000b574072a1"},
  "pages": [{
    "properties": {
      "핵심지표": "WIP {N}건",
      "date:기간:start": "{이번주 월요일 ISO date}",
      "date:기간:end": "{이번주 일요일 ISO date}",
      "리드타임 (P85)": "{X.X}일",
      "리드타임 (중앙값)": "{X.X}일",
      "리드타임 (평균)": "{X.X}일"
    },
    "content": "## 📊 WIP 현황 — {N}건\n\n### 스쿼드별 (Epic, Story, Discovery)\n{스쿼드별 WIP 목록}\n\n### 담당자별\n{담당자별 WIP 목록}\n\n## ⏱️ 리드타임 상세\n전체 P85: {X.X}일 | 중앙값: {X.X}일 | 평균: {X.X}일 ({완료건수}건)\n\n## 🚧 정체 일감 Top 3\n{정체 일감 목록}"
  }]
}
```

## 에러 처리
- Notion 검색 실패 시 가용한 데이터로 부분 리포트 생성
- 리드타임 데이터 부족 시 "데이터 부족" 표시
- 반드시 DB 입력은 시도할 것 (WIP 건수만이라도)
