# User Story Template

> BMAD-inspired 개발 스토리. 백로그의 각 Task를 상세 구현 가이드로 변환합니다.
> Scrum Master가 PRD + Architecture Doc 기반으로 생성.

---

## Story 정보

| 항목 | 내용 |
|------|------|
| Story ID | {EPIC}-{번호} (예: AUTH-001) |
| 제목 | {스토리 제목} |
| Epic | {소속 Epic} |
| 우선순위 | Must / Should / Could |
| 추정 | {시간 또는 포인트} |
| 의존성 | {선행 Story ID} |
| 상태 | Todo / In Progress / Review / Done |

---

## 1. User Story

**As a** {사용자 유형},
**I want to** {원하는 기능},
**so that** {기대 효과}.

---

## 2. 수용 기준 (Acceptance Criteria)

```gherkin
Scenario: {시나리오명}
  Given {사전 조건}
  When {사용자 액션}
  Then {기대 결과}

Scenario: {에러 시나리오}
  Given {사전 조건}
  When {잘못된 입력}
  Then {에러 처리}
```

---

## 3. 구현 가이드

### 3.1 변경 파일 목록
| 파일 | 변경 유형 | 설명 |
|------|----------|------|
| {파일 경로} | 신규/수정 | {변경 내용} |

### 3.2 데이터 변경
```sql
-- 필요한 DB 변경 (있는 경우)
ALTER TABLE ...
```

### 3.3 API 변경
```
{Method} {Endpoint}
Request: { ... }
Response: { ... }
```

### 3.4 컴포넌트 변경 (Frontend)
```
{컴포넌트명}
  Props: { ... }
  State: { ... }
  Events: { ... }
```

### 3.5 아키텍처 참조
- Architecture Doc 섹션: {관련 섹션 번호}
- 관련 ADR: {ADR 번호}

---

## 4. TDD 계획

### 4.1 Unit Tests
| # | 테스트명 | 대상 | 입력 → 기대 출력 |
|---|----------|------|------------------|
| T-001 | {test_xxx} | {함수/컴포넌트} | {입력} → {출력} |

### 4.2 Integration Tests
| # | 테스트명 | 대상 | 시나리오 |
|---|----------|------|----------|
| IT-001 | {test_api_xxx} | {API 엔드포인트} | {시나리오} |

### 4.3 E2E Tests (Playwright)
| # | 시나리오 | 사용자 여정 |
|---|----------|------------|
| E2E-001 | {시나리오명} | {Step 1 → Step 2 → 검증} |

---

## 5. 엣지 케이스 & 예외 처리

| # | 케이스 | 처리 방법 |
|---|--------|-----------|
| EC-001 | {엣지 케이스} | {처리 방법} |

---

## 6. 검증 체크리스트

### 개발 완료 기준 (Definition of Done)
- [ ] 모든 수용 기준(AC) 충족
- [ ] Unit Tests 작성 및 통과
- [ ] Integration Tests 작성 및 통과
- [ ] E2E Tests 작성 및 통과
- [ ] 기존 테스트 깨지지 않음
- [ ] 코드 컨벤션 준수
- [ ] 보안 요구사항 충족
- [ ] 성능 기준 충족

### QA 검증 항목
- [ ] 수용 기준 시나리오 수동 검증
- [ ] 엣지 케이스 검증
- [ ] 크로스 브라우저 테스트 (해당 시)
- [ ] 접근성 검증 (해당 시)
