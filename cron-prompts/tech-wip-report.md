개발 챕터 전용 주간 WIP/리드타임 리포트를 생성하여 Notion DB에 입력하세요.

## 작업 흐름

### 1단계: 백로그 DB에서 Tech 스쿼드 WIP 일감 조회

**데이터 소스**: `collection://f7a3fc56-6ec9-4620-a6f9-e70586a94cc0` (백로그)

**필터 조건**:
- 스쿼드 = Tech
- 일감 유형 ∈ {Task, Sub-Task, Bug} (Track B만)
- 상태 ∈ {In progress, Testing, Review, Blocked}

**방법**:
1. `mcp__claude_ai_Notion__notion-search`의 `ai_search` 모드로 `data_source_url` 지정하여 검색
2. 개별 `mcp__claude_ai_Notion__notion-fetch`로 속성 확인 (상태, 스쿼드, 일감 유형, 담당자)
3. 조건에 맞는 일감만 필터링
4. 담당자별 WIP 건수 집계

**WIP 한도 기준**:
- ✅ 2건 이하: 정상 (베스트)
- 🟡 3건: 최대 허용
- 🔴 4건 이상: 초과

### 2단계: 리드타임 측정 (상태 변경 기록 DB)

**데이터 소스**: `collection://1ec48a03-3208-8010-a814-000b2de06429` (상태 변경 기록)

1. 최근 2주간 Done/Ready for Release 상태의 레코드 검색 (Tech 스쿼드, Task/Sub-Task/Bug)
2. 각 레코드의 `백로그 관계`로 원본 백로그 fetch
3. 상태 변경 이력 추적: 첫 In progress → Done 간 일수 계산
4. P85(85번째 백분위수), 중앙값, 평균 산출

### 3단계: 정체 일감 Top 3

- In progress/Testing/Review/Blocked 상태에서 가장 오래 머문 Tech 스쿼드 Task/Sub-Task/Bug 3개

### 4단계: 개발 챕터 전용 DB에 입력

**대상 DB data source**: `collection://33a48a03-3208-8089-ae01-000bf3d7aa4a` (리드타임/WIP 개발 챕터 전용)

`mcp__claude_ai_Notion__notion-create-pages`로 새 페이지 생성:

```json
{
  "parent": {"data_source_id": "33a48a03-3208-8089-ae01-000bf3d7aa4a"},
  "pages": [{
    "properties": {
      "핵심지표": "WIP {N}건",
      "date:기간:start": "{이번주 월요일 ISO date}",
      "date:기간:end": "{이번주 일요일 ISO date}",
      "리드타임 (P85)": "{X.X}일",
      "리드타임 (중앙값)": "{X.X}일",
      "리드타임 (평균)": "{X.X}일"
    },
    "content": "## 📊 개발 챕터 WIP 현황 — {N}건\n\n### 담당자별 WIP (Task/Sub-Task/Bug, Tech 스쿼드)\n{담당자별 WIP 목록}\n\n## ⏱️ 리드타임 상세\n전체 P85: {X.X}일 | 중앙값: {X.X}일 | 평균: {X.X}일 ({완료건수}건)\n\n## 🚧 정체 일감 Top 3\n{정체 일감 목록}"
  }]
}
```

## 에러 처리
- Notion 검색 실패 시 가용한 데이터로 부분 리포트 생성
- 리드타임 데이터 부족 시 "데이터 부족" 표시
- 반드시 DB 입력은 시도할 것 (WIP 건수만이라도)
