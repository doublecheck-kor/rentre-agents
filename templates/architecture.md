# Architecture Document Template

> BMAD-inspired 아키텍처 문서. PRD 확정 후 작성합니다.
> Greenfield(신규)와 Brownfield(기존 시스템 확장) 모두 사용 가능.

---

## 1. 개요

| 항목 | 내용 |
|------|------|
| 프로젝트명 | {프로젝트명} |
| PRD 참조 | {PRD 링크/위치} |
| 타입 | Greenfield / Brownfield |
| 작성일 | {YYYY-MM-DD} |
| 상태 | Draft / Review / Approved |

### 1.1 아키텍처 목표
- {핵심 아키텍처 결정 사항}
- {달성해야 할 품질 속성}

### 1.2 기술 스택
| 레이어 | 기술 | 버전 | 선택 근거 |
|--------|------|------|-----------|
| Frontend | {React/Next.js 등} | {버전} | {이유} |
| Backend | {Node/Python 등} | {버전} | {이유} |
| Database | {PostgreSQL 등} | {버전} | {이유} |
| Infra | {AWS/GCP 등} | - | {이유} |
| CI/CD | {GitHub Actions 등} | - | {이유} |

---

## 2. 시스템 아키텍처

### 2.1 전체 구조
```
[Client] → [API Gateway] → [Service Layer] → [Database]
                         ↘ [Cache] ↗
                         → [Message Queue] → [Worker]
```
> 실제 프로젝트에 맞게 다이어그램 수정

### 2.2 컴포넌트 목록
| 컴포넌트 | 책임 | 기술 | 통신 방식 |
|----------|------|------|-----------|
| {컴포넌트명} | {역할} | {기술} | REST/gRPC/Event |

### 2.3 Brownfield 영향도 (기존 시스템 확장 시)
| 기존 컴포넌트 | 변경 유형 | 영향 범위 | 리스크 |
|--------------|----------|-----------|--------|
| {컴포넌트} | 수정/확장/교체 | {범위} | H/M/L |

---

## 3. 데이터 아키텍처

### 3.1 데이터 모델 (ERD)
```
[Entity A] 1──N [Entity B] N──M [Entity C]
  - field1: type
  - field2: type
```

### 3.2 API 설계
| Method | Endpoint | 설명 | Request | Response |
|--------|----------|------|---------|----------|
| POST | /api/v1/{resource} | {설명} | {Body} | {Response} |
| GET | /api/v1/{resource}/:id | {설명} | {Params} | {Response} |

### 3.3 데이터 흐름
```
User Action → API Request → Validation → Business Logic → DB Write → Response
                                       → Event Publish → Worker Process
```

---

## 4. 프론트엔드 아키텍처 (해당 시)

### 4.1 페이지/화면 구조
```
App
├── Layout
│   ├── Header
│   ├── Sidebar
│   └── Main Content
│       ├── Page A
│       │   ├── Component A1
│       │   └── Component A2
│       └── Page B
```

### 4.2 상태 관리
| 상태 유형 | 관리 방식 | 범위 |
|-----------|-----------|------|
| Server State | {React Query 등} | Global |
| UI State | {useState 등} | Local |
| Form State | {React Hook Form 등} | Component |

### 4.3 라우팅
| 경로 | 페이지 | 인증 필요 |
|------|--------|-----------|

---

## 5. 인프라 & 배포

### 5.1 환경 구성
| 환경 | 용도 | URL | 특이사항 |
|------|------|-----|----------|
| Local | 개발 | localhost | Docker Compose |
| Staging | QA | {URL} | {설정} |
| Production | 서비스 | {URL} | {설정} |

### 5.2 배포 파이프라인
```
Push → Lint/Type Check → Unit Test → Build → Integration Test → Deploy → E2E Test
```

---

## 6. 보안 설계

| 영역 | 방안 | 구현 방법 |
|------|------|-----------|
| 인증 | {JWT/OAuth 등} | {상세} |
| 인가 | {RBAC/ABAC 등} | {상세} |
| 데이터 보호 | {암호화 등} | {상세} |
| API 보안 | {Rate Limit 등} | {상세} |

---

## 7. 성능 & 확장성

| 항목 | 목표 | 전략 |
|------|------|------|
| API 응답시간 | < {N}ms (p95) | {캐싱, 인덱스 등} |
| 동시 사용자 | {N}명 | {스케일링 전략} |
| DB 쿼리 | < {N}ms | {최적화 방안} |

---

## 8. 테스트 전략

| 레벨 | 범위 | 도구 | 커버리지 목표 |
|------|------|------|--------------|
| Unit | 함수/컴포넌트 | Jest/Vitest | > 80% |
| Integration | API/서비스 | Supertest 등 | 핵심 플로우 |
| E2E | 사용자 여정 | Playwright | 핵심 시나리오 |

---

## 9. ADR (Architecture Decision Records)

| # | 결정 | 선택지 | 선택 | 근거 |
|---|------|--------|------|------|
| ADR-001 | {결정 사항} | A, B, C | {선택} | {토론 근거} |

---

## Checklist
- [ ] 기술 스택이 기존 시스템과 호환되는가?
- [ ] 데이터 모델이 요구사항을 모두 충족하는가?
- [ ] API 설계가 RESTful/일관적인가?
- [ ] 보안 요구사항이 반영되었는가?
- [ ] 성능 목표가 달성 가능한가?
- [ ] 테스트 전략이 수립되었는가?
- [ ] Brownfield인 경우 기존 시스템 영향도가 분석되었는가?
- [ ] 토론 Round 3-4 결과가 반영되었는가?
