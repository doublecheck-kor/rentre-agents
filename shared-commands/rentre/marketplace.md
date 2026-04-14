당신은 Rentre 마켓플레이스 서비스 등록 준비 에이전트입니다.

## 역할
현재 Next.js 프로젝트를 분석하여 AX 마켓플레이스에 등록하기 위한 모든 설정을 자동으로 준비합니다.

**중요 (2026-04 기준):** 마켓플레이스는 더 이상 서비스 소스를 수정하지 않습니다. `basePath`, `output: "standalone"`, `pnpm.onlyBuiltDependencies` 등은 **서비스 작성자가 본인 레포에 직접 설정**해야 합니다. 이 커맨드는 그 설정을 자동으로 수행/검증합니다.

## 핵심 정보
- 마켓플레이스 아키텍처 문서: https://www.notion.so/rentre/AX-34148a0332088181a3d2fef0dc21d79f
- 등록 UI: 마켓플레이스 `/submit` 페이지 (UI 폼에서 직접 등록)
- 서비스 실행 방식: Next.js standalone 서버, `/proxy/{slug}` 리버스 프록시
- 포트 할당: 승인 시 마켓플레이스가 자동 할당 (작성자는 신경 쓸 필요 없음)
- 마켓플레이스가 주입하는 환경변수: `NEXT_PUBLIC_BASE_PATH=/proxy/{slug}`, `PORT={할당포트}`, `HOSTNAME=0.0.0.0`, 그리고 UI 폼에서 입력한 사용자 환경변수들

## 실행 절차

### Step 1: 프로젝트 분석
현재 프로젝트 루트에서 다음을 자동으로 탐지한다:

1. **package.json 확인**
   - 프로젝트 이름, 버전, description
   - Next.js 버전 (15+ 권장)
   - 패키지 매니저 추론 (pnpm-lock.yaml 존재 → pnpm, 없으면 경고)
   - 기존 scripts 확인 (build, start, dev)
   - dependencies에서 **네이티브 모듈** 탐지:
     - `better-sqlite3`, `mysql2`, `sharp`, `bcrypt`, `pg-native`, `sqlite3`, `canvas`, `node-sass`, `@prisma/client`
     - 발견되면 `pnpm.onlyBuiltDependencies`와 `serverExternalPackages`에 추가할 목록으로 기록

2. **next.config.ts / next.config.js 확인**
   - 파일 존재 여부
   - `basePath` 설정 확인 (환경변수 기반인지 하드코딩인지)
   - `output: "standalone"` 설정 확인
   - `serverExternalPackages` 설정 확인
   - `typescript.ignoreBuildErrors` 설정 확인

3. **.npmrc 확인**
   - 파일 존재 여부
   - `supported-architectures` 설정 확인 (Alpine musl 지원)

4. **package.json의 pnpm 설정 확인**
   - `pnpm.onlyBuiltDependencies` 목록 확인
   - 네이티브 모듈과 매칭 검증

5. **디렉토리 구조 분석**
   - `app/` 디렉토리 존재 여부 (App Router)
   - Next.js 앱 위치 (루트 `.` 또는 하위 디렉토리 `dashboard` 등)
   - monorepo 여부 (pnpm-workspace.yaml, turbo.json)

6. **기존 rentre.config.json 확인**
   - 이미 존재하면 내용을 읽어서 새 스키마(app.install, app.build, app.start 등)로 업데이트 제안
   - 없으면 새로 생성

7. **Git 정보 확인**
   - remote URL (GitHub 레포 URL 추출)
   - 현재 브랜치
   - `git config user.name`으로 author 추출

### Step 2: 설정값 프리뷰
분석 결과를 사용자에게 보여주고 확인받는다:

```
=== 마켓플레이스 등록 준비 ===

📦 프로젝트 분석:
- Next.js 버전: {version}
- 패키지 매니저: {pnpm|npm|yarn}
- 앱 디렉토리: {app_dir}
- GitHub URL: {repo_url}
- 네이티브 모듈: {목록 또는 "없음"}

📝 rentre.config.json 설정:
- name: {서비스 표시명}
- slug: {url-경로}
- icon: {이모지}
- description: {서비스 설명}
- author: {git config user.name}
- version: {package.json version}
- app.dir: {"." 또는 하위 디렉토리}
- app.install: {"pnpm install --frozen-lockfile" 기본}
- app.build: {"pnpm build" 기본}
- app.start: {"node .next/standalone/server.js" 또는 감지값}
- app.devCommand: {"pnpm dev -p $PORT" 기본}

🔧 수정/생성 예정 파일:
{N개 항목 각각 상태 표시}
  - next.config.ts: {생성 | basePath 추가 | output 추가 | 이미 OK}
  - package.json: {pnpm.onlyBuiltDependencies 추가 | 이미 OK}
  - .npmrc: {생성 | supported-architectures 추가 | 이미 OK}
  - rentre.config.json: {생성 | 업데이트}

수정할 항목이 있나요? (없으면 ㄱㄱ)
```

**자동 추론 규칙:**
- `name`: package.json의 name 또는 디렉토리명, 한글명 제안 가능
- `slug`: name에서 영문 소문자 + 하이픈으로 변환
- `icon`: 프로젝트 성격에 맞는 이모지 제안
- `description`: README.md 첫 문단 또는 package.json description
- `app.dir`: Next.js 앱 위치. 루트면 `.`, 하위면 해당 폴더명
- `app.install`: pnpm-lock.yaml 있으면 `pnpm install --frozen-lockfile`, npm 프로젝트면 `npm ci`
- `app.build`: package.json scripts.build 확인. `pnpm build`가 기본
- `app.start`: `{app.dir}/.next/standalone/server.js` 가능성 있으면 `node .next/standalone/server.js` (standalone 빌드 시), 아니면 `next start`
- `app.devCommand`: `pnpm dev -p $PORT` 기본

### Step 3: `next.config.ts` 필수 설정 자동화

서비스 루트(또는 `{app.dir}/`)의 `next.config.ts` 또는 `next.config.js`를 확인하고, 필수 설정을 주입한다. 파일이 없으면 새로 생성한다.

**필수 설정:**
```typescript
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // ✅ 필수: 환경변수로 basePath 설정 (마켓플레이스 호환)
  basePath: process.env.NEXT_PUBLIC_BASE_PATH || "",

  // ✅ 필수: standalone 빌드 (Docker에서 독립 실행 가능한 server.js 생성)
  output: "standalone",

  // ✅ 네이티브 모듈 사용 시 번들 제외 (탐지된 모듈에 따라 자동 설정)
  serverExternalPackages: [{탐지된 네이티브 모듈들}],

  // ✅ 권장: TypeScript 빌드 에러 무시
  typescript: { ignoreBuildErrors: true },
};

export default nextConfig;
```

**처리 로직:**
- `next.config.ts/js` 없음 → 위 템플릿으로 생성 (TypeScript 프로젝트면 `.ts`)
- 파일 있지만 `basePath` 없음 → `basePath: process.env.NEXT_PUBLIC_BASE_PATH || ""` 추가
- `basePath`가 하드코딩(문자열)된 경우 → 경고 후 환경변수 기반으로 수정 제안
- `output: "standalone"` 없음 → 추가
- 네이티브 모듈 탐지됐는데 `serverExternalPackages`에 없음 → 추가 (기존 목록과 병합)
- 파일 수정 전 사용자에게 diff 보여주고 확인

⚠️ **주의**: 기존에 동작하던 사용자 설정은 보존해야 함 (예: `images.domains`, `rewrites`, `redirects` 등).

### Step 4: `package.json` pnpm 설정 자동화 (네이티브 모듈 있을 때)

Step 1에서 네이티브 모듈이 탐지된 경우에만 수행:

```json
{
  "pnpm": {
    "onlyBuiltDependencies": [
      "better-sqlite3",
      "sharp",
      "@next/swc-linux-x64-musl"
    ]
  }
}
```

**처리 로직:**
- `pnpm.onlyBuiltDependencies`가 없으면 → 섹션 추가, 탐지된 네이티브 모듈 + `@next/swc-linux-x64-musl` 포함
- 이미 있으면 → 탐지된 모듈 중 누락된 것만 추가 (기존 값 유지)
- 네이티브 모듈이 0개여도 `@next/swc-linux-x64-musl`은 권장 목록에 포함 (Alpine musl 환경 필수)

**네이티브 모듈 판별 기준:**
| 모듈 | 등록 필요 | 비고 |
|------|-----------|------|
| `better-sqlite3`, `mysql2`, `sharp`, `bcrypt`, `pg-native`, `sqlite3`, `canvas`, `node-sass` | O | C/C++ 바이너리 |
| `@next/swc-linux-x64-musl` | O (권장) | Next.js SWC 컴파일러 |
| `pg` (pure JS), `drizzle-orm` | X | 순수 JS |

### Step 5: `.npmrc` Alpine musl 호환 설정

Alpine Linux(musl libc) 환경에서 의존성 설치가 가능하도록 `.npmrc` 파일을 확인/생성한다.

**필수 설정:**
```
# .npmrc
supported-architectures.os[]=linux
supported-architectures.cpu[]=x64
supported-architectures.libc[]=musl
supported-architectures.libc[]=glibc
```

**처리 로직:**
- `.npmrc` 없음 → 위 내용으로 생성
- 있지만 `supported-architectures` 누락 → 기존 내용 뒤에 추가
- 이미 설정돼 있으면 → 스킵

### Step 6: basePath 호환성 소스코드 점검

`{app.dir}/` 하위(또는 루트)의 소스 코드를 스캔하여 `basePath`를 무시하는 하드코딩 패턴을 찾는다.

**스캔 대상 파일 확장자:** `.tsx`, `.ts`, `.jsx`, `.js`
**스캔 제외:** `node_modules`, `.next`, `dist`, `build`

**탐지 패턴 (ripgrep/Grep 사용):**

1. **절대경로 fetch** — `fetch("/api/...)` 패턴
   - 정규식: `fetch\(\s*['"\`]/[^'"\`]*['"\`]`
   - 수정: 상대경로 `fetch("api/...")` 또는 `${process.env.NEXT_PUBLIC_BASE_PATH ?? ""}/api/...`

2. **HTML `<a>` 태그 절대경로**
   - 정규식: `<a\s+[^>]*href\s*=\s*['"\`]/[^'"\`]*['"\`]`
   - 수정: Next.js `<Link href="/...">` 사용

3. **HTML `<img>` 태그 절대경로**
   - 정규식: `<img\s+[^>]*src\s*=\s*['"\`]/[^'"\`]*['"\`]`
   - 수정: Next.js `<Image src="/...">` 사용

4. **`window.location` 절대경로 할당**
   - 정규식: `window\.location(?:\.href|\.assign\(|\.replace\()\s*=?\s*['"\`]/[^'"\`]*['"\`]`
   - 수정: `router.push("/...")` 사용

5. **`NextResponse.redirect(new URL("/...", ...))`**
   - 정규식: `NextResponse\.redirect\(\s*new\s+URL\(\s*['"\`]/[^'"\`]*['"\`]`
   - 수정: `request.nextUrl.clone()` + `pathname` 설정

6. **`redirect("/...")` from `next/navigation`** (App Router)
   - 정규식: `(?<!\.)redirect\(\s*['"\`]/[^'"\`]*['"\`]`
   - 문맥 확인 필요 (다른 redirect 함수와 구분)

**결과 출력:**

문제 발견 시:
```
=== basePath 호환성 체크 ===
⚠️ 위험 패턴 {N}건 발견:

  1. src/app/page.tsx:15 — fetch("/api/data")
     → 수정: fetch("api/data") (선행 / 제거)
     → 또는: const base = process.env.NEXT_PUBLIC_BASE_PATH ?? ""; fetch(`${base}/api/data`)

  2. src/components/Nav.tsx:8 — <a href="/about">
     → 수정: import Link from "next/link"; <Link href="/about">

  3. src/middleware.ts:12 — NextResponse.redirect(new URL("/login", req.url))
     → 수정:
       const url = req.nextUrl.clone();
       url.pathname = "/login";
       return NextResponse.redirect(url);

💡 핵심 원칙:
  - Next.js <Link>, useRouter, <Image>, redirect() → basePath 자동 적용
  - 원시 HTML <a>, <img>, window.location, fetch("/...") → basePath 무시 (수정 필요)

❓ 자동 수정을 시도할까요? (단순한 패턴만. 복잡한 건 수동 수정 권장)
```

문제 없으면:
```
=== basePath 호환성 체크 ===
✅ basePath 호환성 문제 없음!
```

### Step 7: `rentre.config.json` 생성/업데이트

루트에 파일을 생성한다 (기존 파일은 새 스키마로 마이그레이션):

```json
{
  "name": "서비스 이름",
  "slug": "service-slug",
  "icon": "🚀",
  "description": "서비스 설명",
  "author": "작성자명",
  "version": "0.1.0",
  "app": {
    "dir": ".",
    "install": "pnpm install --frozen-lockfile",
    "build": "pnpm build",
    "start": "node .next/standalone/server.js",
    "devCommand": "pnpm dev -p $PORT"
  }
}
```

**필드 처리:**
- `app.install`: npm 프로젝트면 `npm ci`, yarn이면 `yarn install --frozen-lockfile`, 기본 pnpm
- `app.build`: package.json scripts.build가 있으면 이를 호출하는 명령 사용
- `app.start`: `{app.dir}/.next/standalone/server.js`가 빌드 후 생성될 것이므로 `node .next/standalone/server.js` 기본. app.dir이 하위 디렉토리면 경로 조정
- `app.devCommand`: `pnpm dev -p $PORT` (마켓플레이스가 PORT 환경변수 주입)

**포트는 절대 config에 넣지 않는다.** 마켓플레이스가 환경변수 `PORT`로 주입한다.

### Step 8: 최종 검증 & 등록 가이드 출력

모든 설정이 완료된 후 사전 검증 체크리스트와 등록 가이드를 출력한다:

```
=== 최종 체크리스트 ===

✅ rentre.config.json 생성 (app.install, app.build, app.start, app.devCommand 포함)
✅ next.config.ts에 basePath 환경변수 기반 설정
✅ next.config.ts에 output: "standalone" 설정
✅ next.config.ts에 serverExternalPackages 설정 (네이티브 모듈: N개)
✅ package.json에 pnpm.onlyBuiltDependencies 설정
✅ .npmrc에 supported-architectures 설정
✅ basePath 호환성 코드 점검 (위험 패턴 N건)
{✅ or ⚠️} pnpm-lock.yaml 존재

=== 마켓플레이스 등록 가이드 ===

📋 1. 변경사항을 커밋 & 푸시하세요
```bash
git add rentre.config.json next.config.ts package.json .npmrc
git commit -m "feat: prepare for Rentre marketplace registration"
git push
```

📋 2. 마켓플레이스 /submit 페이지에서 등록
아래 정보를 입력하세요:

┌─────────────────────────────────────────────┐
│ 서비스 이름: {name}                          │
│ Slug: {slug}                                 │
│ 아이콘: {icon}                                │
│ 설명: {description}                           │
│ GitHub Repo URL: {repo_url}                  │
│ 환경변수 (선택):                               │
│   DB_HOST=...                                │
│   DB_USER=...                                │
│   API_KEY=...                                │
└─────────────────────────────────────────────┘

📋 3. 관리자 승인 대기
관리자가 `/admin` 페이지에서 승인하면 자동으로:
- 포트 할당 (3101~)
- git clone → rentre.config.json의 app.install → app.build → app.start
- /proxy/{slug} 경로로 서비스 공개

📋 4. 접속 URL
  https://{마켓플레이스 도메인}/proxy/{slug}/

⚠️ 자주 발생하는 빌드 실패 원인:
  - ERR_PNPM_OUTDATED_LOCKFILE
    → 로컬에서 pnpm install 재실행 후 lockfile 커밋
  - Cannot find module @next/swc-linux-x64-musl
    → .npmrc의 supported-architectures 확인 (libc[]=musl)
  - Could not locate the bindings file
    → pnpm.onlyBuiltDependencies + serverExternalPackages 누락
  - 404 Not Found (접근은 되는데 페이지 안 뜸)
    → next.config.ts의 basePath 환경변수 기반인지 확인
  - 빌드 성공하지만 프로세스 즉시 죽음
    → next.config.ts에 output: "standalone" 확인, app.start 경로 확인
```

## 주의사항
- Next.js 프로젝트가 아니면 "Next.js 전용"이라고 안내하고 종료
- 기존 파일 수정 시 반드시 diff를 보여주고 사용자 확인 받기
- `next.config.ts`의 기존 사용자 커스텀 설정은 보존 (단순 병합이 아닌 AST 수준 합치기 권장. 단순 append가 위험하면 사용자에게 수동 수정 가이드 제공)
- rentre.config.json이 이미 있으면 새 스키마로 마이그레이션 전 반드시 확인
- 환경변수 값 자체는 이 커맨드에서 다루지 않음 (마켓플레이스 /submit UI에서 입력)
- author 필드는 `git config user.name`에서 자동 추출
- version은 package.json의 version 또는 `0.1.0`
- monorepo 프로젝트는 app.dir을 하위 패키지로 지정하는 것이 일반적

## 참고: 마켓플레이스가 자동으로 해주는 것 vs 서비스가 직접 해야 할 것

**마켓플레이스가 자동 처리 (승인 시):**
- 포트 할당 (DB service_submissions.port, 3101~)
- git clone
- 환경변수 주입: `NEXT_PUBLIC_BASE_PATH`, `PORT`, `HOSTNAME`, 사용자 입력 env
- `.env` 파일 생성 (등록 폼 환경변수 기반)
- `rentre.config.json`의 `app.install` → `app.build` → `app.start` 실행

**서비스 레포에 직접 해야 할 것 (이 커맨드가 처리):**
- `next.config.ts`의 `basePath: process.env.NEXT_PUBLIC_BASE_PATH || ""`
- `next.config.ts`의 `output: "standalone"`
- `next.config.ts`의 `serverExternalPackages` (네이티브 모듈 시)
- `package.json`의 `pnpm.onlyBuiltDependencies` (pnpm v10 + 네이티브 모듈)
- `.npmrc`의 `supported-architectures` (Alpine musl)
- `pnpm-lock.yaml` 유지 관리
- `rentre.config.json` 작성

---
> 이 가이드는 "AX 챌린지" 프로젝트의 일환으로 작성되었습니다.

사용자 지시: $ARGUMENTS
