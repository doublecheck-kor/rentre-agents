# PM Weekly 기타 백로그 현황 등록

PM Weekly 회의용 "기타 백로그별 진행현황" DB에 이번 주 주요 백로그를 등록하는 에이전트입니다.

## 사용자 설정

`~/.claude/rentre-config.json`에서 아래 정보를 읽어옵니다:
- `user_name`: PM 이름
- `notion_user_id`: Notion User ID (DRI 설정용)

## 실행 플로우

### Step 1: 이번 주 PM Weekly 페이지 찾기

`notion-search`로 이번 주 "제품팀 PM Weekly" 페이지를 검색합니다.

```
query: "제품팀 PM Weekly"
query_type: internal
filters:
  created_date_range:
    start_date: <이번 주 월요일 (YYYY-MM-DD)>
    end_date: <오늘 + 1일>
page_size: 5
max_highlight_length: 0
```

검색 결과에서 제목이 `YYMMDD - 제품팀 PM Weekly` 패턴인 페이지를 선택합니다.
- 여러 개면 가장 최근 것 사용
- 못 찾으면 사용자에게 PM Weekly 페이지 URL을 직접 입력받기

### Step 2: "기타 백로그별 진행현황" DB 찾기

찾은 PM Weekly 페이지를 `notion-fetch`하여 하위에 있는 "기타 백로그별 진행현황" 데이터베이스의 `data-source` URL을 확인합니다.

```
notion-fetch:
  id: <PM Weekly 페이지 ID>
```

응답에서 `<data-source url="collection://...">` 중 이름이 "기타 백로그별 진행현황"인 것의 data_source_id를 추출합니다.

### Step 3: DB 스키마 확인

해당 data source를 `notion-fetch`하여 정확한 스키마를 확인합니다. 예상 스키마:

| 프로퍼티 | 타입 | 설명 |
|----------|------|------|
| ID (작성 불필요) | title | 백로그 제목 |
| 백로그 구분 | select | 고객 퍼널 개선하기, 고객에게 전문가 서비스 제공하기, 파트너/상담원에게 좋은 도구 제공하기, 내부 운영 자동화/효율화, 기술 기반 강화, 기타 - 사업팀 요청사항 |
| Stage (금주기준) | multi_select | 예비 백로그 수렴, 사전리서치/스터디, 기획, 디자인/개발, QA/배포완료, 드랍, 아카이빙 |
| DRI(PM) | person | Notion User ID |
| 금주 실적 | text | 이번 주 진행 내용 |
| 차주 계획 | text | 다음 주 계획 |
| 비고 | text | 참고 사항 |
| 백로그 (TASK / STORY LEVEL) | relation | 백로그 DB 연결 |

### Step 4: 이번 주 내 활동 검색

사용자의 Notion User ID로 이번 주 생성한 문서를 검색합니다.

```
notion-search:
  query: "백로그"
  query_type: internal
  filters:
    created_by_user_ids: [<notion_user_id>]
    created_date_range:
      start_date: <이번 주 월요일>
      end_date: <오늘 + 1일>
  page_size: 25
  max_highlight_length: 100
```

추가로 "문서 페이지" 등 다른 키워드로도 검색하여 누락을 줄입니다.

### Step 5: 주요 백로그 선별 및 백로그 DB 매칭

검색 결과에서 단순 운영 요청(데이터추출, 정보추가 등)을 제외하고, 개발/기획/설계 성격의 백로그를 선별합니다.

**⚠️ 필수: 백로그 DB 매칭**
각 선별 항목은 반드시 백로그 DB(`collection://f7a3fc56-6ec9-4620-a6f9-e70586a94cc0`)에서 실제 페이지를 찾아 relation으로 연결해야 합니다. `notion-search`에 `data_source_url`을 지정하여 검색:

```
notion-search:
  query: "<백로그 핵심 키워드>"
  query_type: internal
  data_source_url: "collection://f7a3fc56-6ec9-4620-a6f9-e70586a94cc0"
  filters: {}
  page_size: 5
  max_highlight_length: 0
```

- 백로그 DB에서 **정확히 매칭되는 페이지의 URL**을 확보 (ID (작성 불필요) 제목도 매칭 페이지의 일감명과 동일하게 사용)
- 매칭되는 백로그가 없으면 해당 항목은 제외하고 사용자에게 알림 ("백로그 DB에 등록 없음 → 제외" 또는 백로그 선생성 제안)
- URL은 공백/오타 없이 `https://www.notion.so/<32자 ID>` 형식 확인

사용자에게 테이블 형태로 제안합니다:

```
이번 주 주요 백로그를 선별했습니다:

| # | 백로그명 | 백로그 구분 (추천) | Stage (추천) |
|---|---------|-------------------|-------------|
| 1 | ... | ... | ... |
| 2 | ... | ... | ... |

이대로 등록할까요? 수정/추가/제외할 항목이 있으면 말씀해주세요.
```

**백로그 구분 자동 분류 기준**:
- 고객 퍼널, PDP, SEO, 전환율, UX → "고객 퍼널 개선하기"
- 상담, 전문가, CS → "고객에게 전문가 서비스 제공하기"
- 어드민, 파트너, CRM → "파트너/상담원에게 좋은 도구 제공하기"
- 자동화, 효율화, 내부 도구 → "내부 운영 자동화/효율화"
- 인프라, 디자인시스템, API, 리팩토링 → "기술 기반 강화"
- 사업팀 요청, 데이터 요청 → "기타 - 사업팀 요청사항"

**Stage 자동 분류 기준**:
- 아이디어/초기 논의 → "예비 백로그 수렴"
- 리서치/분석/PoC → "사전리서치/스터디"
- 기획서/PRD 작성 중 → "기획"
- 개발/디자인 진행 중 → "디자인/개발"
- QA/배포 완료 → "QA/배포완료"

### Step 6: 사용자 확인 후 등록

사용자가 확인하면 `notion-create-pages`로 등록합니다.

```json
{
  "parent": {"type": "data_source_id", "data_source_id": "<Step 2에서 찾은 ID>"},
  "pages": [
    {
      "properties": {
        "ID (작성 불필요)": "<백로그 제목 = 매칭된 백로그 DB 일감명>",
        "백로그 (TASK / STORY LEVEL)": "[\"<Step 5에서 확보한 백로그 DB 페이지 URL>\"]",
        "백로그 구분": "<선택된 구분>",
        "Stage (금주기준)": "[\"<선택된 Stage>\"]",
        "DRI(PM)": "[\"<notion_user_id>\"]",
        "금주 실적": "- 항목1\n- 항목2\n- 항목3",
        "차주 계획": "- 항목1\n- 항목2"
      }
    }
  ]
}
```

### Step 7: 완료 보고

등록 결과를 테이블로 보여줍니다:

```
✅ PM Weekly 기타 백로그 N건 등록 완료

| 백로그명 | 구분 | Stage | 금주 실적 |
|---------|------|-------|----------|
| ... | ... | ... | ... |

📎 PM Weekly 페이지: <URL>
```

## 주의사항

1. **반드시 사용자 확인 후 등록**: 자동으로 바로 등록하지 말 것
2. **백로그 relation 필수**: `백로그 (TASK / STORY LEVEL)` 필드에 반드시 백로그 DB의 실제 페이지 URL을 relation으로 연결할 것. 백로그 제목(ID)은 매칭된 백로그 일감명을 그대로 사용 (임의 축약/변형 금지)
3. **금주 실적/차주 계획 포맷**: 반드시 항목별 불릿 리스트(`- `) + 개행(`\n`)으로 작성. 콤마로 이어 붙이지 말 것
   - ✅ Right: `"- 오케스트레이터 패턴 도입\n- 타임아웃 정책 정비\n- 비동기 폴링 UX 적용"`
   - ❌ Wrong: `"오케스트레이터 패턴 도입, 타임아웃 정책 정비, 비동기 폴링 UX 적용"`
4. **금주 실적은 구체적으로**: Notion 원본 문서 내용을 참고하여 이번 주 실제 진행 내용을 요약
5. **PM Weekly DB는 매주 다름**: 반드시 이번 주 페이지를 찾아서 해당 DB에 등록
6. **DRI는 실행하는 PM 본인**: config의 notion_user_id 사용
7. **중복 확인**: 이미 등록된 항목이 있는지 DB 내용을 확인하고, 중복 시 사용자에게 알림
8. **URL 오타 주의**: relation URL은 공백/줄바꿈 없이 `https://www.notion.so/<32자 hex ID>` 형식으로 입력. 생성 실패 시 URL 문자열 재검증

## 인자 처리

- `$ARGUMENTS`가 비어있으면: 전체 플로우 실행 (Step 1부터)
- `$ARGUMENTS`에 Notion URL이 있으면: 해당 PM Weekly 페이지를 직접 사용 (Step 2부터)
- `$ARGUMENTS`에 "지난주"가 있으면: 지난주 월요일~일요일 범위로 검색
