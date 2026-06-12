# rentre-agents 마이그레이션 가이드 (v2 → v3)

> BMAD 서브모듈 + 프로젝트별 스킬 심링크 방식(v2)에서
> **superpowers 글로벌 플러그인** 방식(v3)으로 전환하는 가이드

## 변경 요약

| 항목 | v2 (BMAD 서브모듈) | v3 (superpowers 플러그인) |
|------|-------------------|--------------------------|
| 개발 스킬 출처 | `bmad-submodule`(nested submodule) 안의 심링크 | obra/superpowers 플러그인 (글로벌) |
| 스킬 설치 위치 | 프로젝트 `.claude/skills/bmad-*` 등 (심링크) | `~/.claude/plugins/` (글로벌, 1회) |
| 프레임워크 선택 | `--preset` 메뉴 (BMAD/GDS/WDS/FSD) | 없음 (superpowers 단일) |
| 설정 파일 | `.claude/bmad-profile.json` | 없음 |
| `_bmad` 심링크 | 있음 | 없음 |
| Rentre 커맨드 | 동일 | 동일 |

> ⚠️ v3는 BMAD/GDS/WDS/FSD 스킬을 **더 이상 제공하지 않습니다.** 개발 규율 스킬은
> superpowers(브레인스토밍, 플랜 작성/실행, TDD, 체계적 디버깅, 코드리뷰 등)로 대체됩니다.

---

## 1. 사전 준비

### Bash 버전 확인

```bash
bash --version
```

**Bash 4.3 이상**이 필요합니다. macOS 기본 Bash는 3.2이므로 업그레이드하세요.

```bash
brew install bash
/opt/homebrew/bin/bash rentre-agents/install.sh   # Intel Mac은 /usr/local/bin/bash
```

### Claude Code CLI 플러그인 명령 확인

```bash
claude plugin --help
```

`marketplace`, `install` 서브커맨드가 보이면 v3 설치가 가능합니다.

---

## 2. 마이그레이션 절차

### Step 1: rentre-agents 서브모듈을 v3로 업데이트

```bash
cd ~/my-project/rentre-agents
git fetch origin
git checkout main
git pull
cat VERSION   # 0.10.0 이상이면 v3
cd ..
```

> 💡 v3에는 더 이상 nested `bmad-submodule`이 없습니다. 업데이트 후
> `rentre-agents/bmad-submodule` 디렉토리는 사라집니다.

### Step 2: 죽은 BMAD 잔재 정리

v2에서 생성된 심링크/설정은 이제 깨진 링크입니다. 제거하세요.

```bash
cd ~/my-project

# 프로젝트 스킬 심링크 제거 (bmad/gds/wds/fsd)
rm -rf .claude/skills/bmad-* .claude/skills/gds-* .claude/skills/wds* \
       .claude/skills/applying-fsd-architecture 2>/dev/null

# _bmad 심링크, 프로파일 제거
rm -rf _bmad _bmad-output .claude/bmad-profile.json 2>/dev/null
```

확인:

```bash
# 깨진 심링크가 남아있지 않은지
find .claude/skills -type l ! -exec test -e {} \; -print 2>/dev/null
```

### Step 3: v3 install.sh 실행

```bash
bash rentre-agents/install.sh
```

install.sh가 수행하는 작업:
1. **superpowers 플러그인 글로벌 설치** — `obra/superpowers-marketplace` 마켓플레이스 등록 + `superpowers` 플러그인 설치(user 스코프). 이미 있으면 건너뜀.
2. 프로젝트 커맨드 설치 (`.claude/commands/rentre/`)
3. 업데이트 체크 hook 등록

> 프리셋/프레임워크 선택 메뉴는 더 이상 없습니다. (`--preset`은 무시됨)

### Step 4: .gitignore 정리

v2에서 추가했던 BMAD 관련 항목을 제거합니다.

```gitignore
# 아래 항목 삭제 (v3에서 불필요)
# .claude/skills/bmad-*
# .claude/skills/gds-*
# .claude/skills/wds*
# .claude/skills/applying-fsd-architecture
# .claude/bmad-profile.json
# _bmad
# _bmad-output
```

### Step 5: 변경사항 커밋

```bash
git add .gitignore .gitmodules rentre-agents
git commit -m "chore: rentre-agents v3 마이그레이션 (BMAD → superpowers 플러그인)"
```

### Step 6: 스킬 활성화

Claude Code에서 직접 입력:

```
/reload-plugins
```

(또는 Claude Code 재시작) → `/superpowers:*` 스킬이 활성화됩니다.

---

## 3. 신규 설치 (v3 처음부터)

```bash
cd ~/my-project
git submodule add https://github.com/doublecheck-kor/rentre-agents
git submodule update --init
bash rentre-agents/install.sh
# Claude Code에서 /reload-plugins
```

---

## 4. 문제 해결 (FAQ)

### Q: superpowers 플러그인이 설치되지 않습니다

install.sh가 실패 메시지와 함께 수동 명령을 안내합니다. 직접 실행하세요.

```bash
claude plugin marketplace add obra/superpowers-marketplace
claude plugin install superpowers@superpowers-marketplace --scope user
```

설치 확인:

```bash
claude plugin list | grep superpowers
```

### Q: macOS에서 "Bash 4.3 이상 필요" 에러가 발생합니다

```bash
brew install bash
/opt/homebrew/bin/bash rentre-agents/install.sh   # Intel Mac은 /usr/local/bin/bash
```

### Q: 기존 BMAD 스킬(`/bmad-*`)이 사라졌습니다

v3는 의도적으로 BMAD/GDS/WDS/FSD를 제거했습니다. 개발 워크플로우는 superpowers로 대체됩니다.
대응표:

| v2 (BMAD) | v3 (superpowers) |
|-----------|------------------|
| `/bmad-brainstorming` | `/superpowers:brainstorming` |
| `/bmad-create-prd`, `/bmad-create-epics-and-stories` | `/superpowers:writing-plans` |
| `/bmad-dev-story`, `/bmad-quick-dev` | `/superpowers:executing-plans` + `/superpowers:test-driven-development` |
| `/bmad-code-review` | `/superpowers:requesting-code-review` |
| (디버깅) | `/superpowers:systematic-debugging` |

> BMAD가 계속 필요하면 v3로 올리지 말고 v2 태그에 머무르거나, BMAD 플러그인을 별도 마켓플레이스로 직접 설치하세요.

### Q: 팀원이 저장소를 클론하면?

```bash
git clone <repo>           # rentre-agents는 단순 서브모듈 (nested submodule 없음)
git submodule update --init
bash rentre-agents/install.sh
# /reload-plugins
```

---

## 참고 사항

- 서브모듈 업데이트: `cd rentre-agents && git pull` (v3는 nested submodule이 없어 `--recurse-submodules` 불필요)
- superpowers 플러그인은 **글로벌 공용**이라 모든 프로젝트가 한 번의 설치를 공유합니다.
- 글로벌 커맨드(assistant, help, setup)는 `--with-global` 시에만 `~/.claude/commands/rentre/`에 설치됩니다.
