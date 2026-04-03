# rentre-agents 마이그레이션 가이드

> 글로벌 설치 방식에서 프로젝트별 서브모듈 방식으로 전환하는 가이드

## 변경 요약

| 항목 | AS-IS (글로벌) | TO-BE (서브모듈) |
|------|---------------|-----------------|
| 설치 위치 | `~/.rentre-agents` 또는 `~/rentre-agents` | 프로젝트 내 `rentre-agents/` |
| 심링크 | 절대 경로 (`~/.rentre-agents/...`) | 상대 경로 (`../../rentre-agents/...`) |
| BMAD 스킬 | 113개 전체 설치 | 역할별 선택 설치 |
| Rentre 커맨드 | 7개 전부 글로벌 | 3개 글로벌 + 4개 프로젝트 레벨 |
| 설정 파일 | 없음 | `.claude/bmad-profile.json` |

---

## 1. 사전 준비

### Bash 버전 확인

```bash
bash --version
```

**Bash 4.3 이상**이 필요합니다. 출력에서 첫 줄의 버전 번호를 확인하세요.

macOS 기본 Bash는 3.2입니다. 아래와 같이 업그레이드하세요.

```bash
# Homebrew로 최신 Bash 설치
brew install bash

# 설치 확인
/opt/homebrew/bin/bash --version

# 기본 셸로 등록 (선택)
echo '/opt/homebrew/bin/bash' | sudo tee -a /etc/shells
chsh -s /opt/homebrew/bin/bash
```

> 💡 셸을 변경하지 않아도 됩니다. install.sh 실행 시 `/opt/homebrew/bin/bash rentre-agents/install.sh`처럼 직접 지정할 수 있습니다.

### 기존 심링크 상태 확인

현재 프로젝트에 설치된 BMAD 심링크를 확인합니다.

```bash
cd ~/my-project

# .claude/skills 내 심링크 확인
ls -la .claude/skills/ 2>/dev/null | grep '^l'

# _bmad 심링크 확인
ls -la _bmad 2>/dev/null
```

절대 경로(`/home/사용자/.rentre-agents/...`)를 가리키고 있다면 글로벌 방식입니다.

---

## 2. 마이그레이션 절차

### Step 1: 기존 설치 정리

현재 프로젝트의 BMAD 심링크를 제거합니다.

```bash
cd ~/my-project
bash ~/.rentre-agents/shared-commands/install.sh --remove
```

> ⚠️ `--remove`는 심링크만 제거합니다. 실제 파일은 삭제되지 않습니다.

제거 후 확인:

```bash
# 심링크가 남아있지 않은지 확인
ls -la .claude/skills/bmad-* 2>/dev/null
ls -la _bmad 2>/dev/null
```

### Step 2: rentre-agents를 프로젝트 서브모듈로 추가

```bash
cd ~/my-project
git submodule add https://github.com/doublecheck-kor/rentre-agents
git submodule update --init --recursive
```

> 💡 서브모듈은 프로젝트 루트에 `rentre-agents/` 디렉토리로 추가됩니다.

### Step 3: 새 install.sh 실행

```bash
bash rentre-agents/install.sh
```

선택형 메뉴가 표시됩니다. 역할에 맞는 프리셋을 선택하거나, 개별 스킬 카테고리를 직접 고르세요.

프리셋을 미리 지정하려면:

```bash
bash rentre-agents/install.sh --preset backend
```

설치 완료 후 `.claude/bmad-profile.json`이 생성됩니다. 이 파일에 선택한 스킬 구성이 저장됩니다.

### Step 4: .gitignore 확인

프로젝트 루트의 `.gitignore`에 아래 항목을 추가합니다.

```gitignore
# BMAD 심링크 (서브모듈 install.sh가 생성)
.claude/skills/bmad-*
.claude/skills/gds-*
.claude/skills/wds*
.claude/skills/applying-fsd-architecture
.claude/bmad-profile.json
_bmad
```

> 💡 이 항목들은 심링크이므로 Git에 커밋할 필요가 없습니다. 각 개발자가 `install.sh`를 실행하면 자동 생성됩니다.

### Step 5: 변경사항 커밋

```bash
git add .gitignore .gitmodules rentre-agents
git commit -m "chore: rentre-agents를 서브모듈로 전환"
```

### Step 6: 글로벌 설치 정리 (선택)

더 이상 글로벌 클론을 사용하는 프로젝트가 없다면 제거합니다.

```bash
# 다른 프로젝트에서 글로벌 심링크를 사용하고 있지 않은지 먼저 확인
grep -r "$HOME/.rentre-agents" ~/.claude/ 2>/dev/null

# 안전하다면 제거
rm -rf ~/.rentre-agents
```

> ⚠️ 아직 마이그레이션하지 않은 프로젝트가 있다면 글로벌 클론을 유지하세요. 해당 프로젝트의 심링크가 깨집니다.

---

## 3. 프리셋별 추천 설정

| 역할 | 프리셋 | 설치 스킬 수 | 포함 내용 |
|------|--------|-------------|----------|
| 백엔드 개발자 | `--preset backend` | ~26개 | 아키텍처, 코드리뷰, 테스트, 스토리 구현 |
| 프론트엔드 개발자 | `--preset frontend` | ~24개 | UX 디자인, FSD 아키텍처, 컴포넌트 개발 |
| PM/기획 | `--preset pm` | ~37개 | PRD, 브레인스토밍, 마켓 리서치, 스프린트 |
| 게임 개발 | `--preset gamedev` | ~30개 | GDD, 게임 아키텍처, 플레이테스트, QA |
| 전체 | `--preset full` | ~113개 | 모든 BMAD + GDS + WDS 스킬 |

> 💡 프리셋은 시작점입니다. 설치 후 `install.sh --add <스킬명>`으로 개별 스킬을 추가할 수 있습니다.

---

## 4. 문제 해결 (FAQ)

### Q: macOS에서 "Bash 4.3 이상 필요" 에러가 발생합니다

macOS 기본 Bash는 3.2입니다. Homebrew로 업그레이드하세요.

```bash
brew install bash
/opt/homebrew/bin/bash rentre-agents/install.sh
```

Intel Mac의 경우 경로가 `/usr/local/bin/bash`입니다.

### Q: 심링크가 깨졌다는 경고가 나옵니다

서브모듈이 초기화되지 않았거나, 경로가 변경된 경우 발생합니다.

```bash
# 서브모듈 상태 확인
git submodule status

# 서브모듈 초기화 및 업데이트
git submodule update --init --recursive

# install.sh 재실행
bash rentre-agents/install.sh
```

심링크를 수동으로 확인하려면:

```bash
# 깨진 심링크 찾기
find .claude/skills -type l ! -exec test -e {} \; -print 2>/dev/null
```

### Q: 이전 설정을 복원하고 싶습니다

서브모듈 방식으로 전환한 뒤 문제가 있다면 롤백할 수 있습니다. 아래 [롤백 방법](#5-롤백-방법) 섹션을 참고하세요.

### Q: 여러 프로젝트에서 동시에 마이그레이션하려면?

프로젝트별로 순서대로 진행하세요.

```bash
# 프로젝트 A
cd ~/project-a
bash ~/.rentre-agents/shared-commands/install.sh --remove
git submodule add https://github.com/doublecheck-kor/rentre-agents
git submodule update --init --recursive
bash rentre-agents/install.sh --preset backend

# 프로젝트 B
cd ~/project-b
bash ~/.rentre-agents/shared-commands/install.sh --remove
git submodule add https://github.com/doublecheck-kor/rentre-agents
git submodule update --init --recursive
bash rentre-agents/install.sh --preset frontend
```

모든 프로젝트 마이그레이션이 끝난 후 글로벌 클론을 제거하세요.

### Q: 팀원이 서브모듈이 포함된 저장소를 클론하면?

서브모듈은 자동으로 받아지지 않습니다. 아래 명령을 안내하세요.

```bash
git clone --recurse-submodules https://github.com/your-org/your-project
# 또는 이미 클론한 경우
git submodule update --init --recursive
```

이후 install.sh를 실행합니다.

```bash
bash rentre-agents/install.sh
```

---

## 5. 롤백 방법

서브모듈 방식에서 다시 글로벌 방식으로 돌아가는 절차입니다.

### Step 1: 서브모듈 심링크 제거

```bash
cd ~/my-project
bash rentre-agents/install.sh --remove
```

### Step 2: 서브모듈 제거

```bash
git submodule deinit -f rentre-agents
git rm -f rentre-agents
rm -rf .git/modules/rentre-agents
```

### Step 3: 글로벌 클론 복원 (필요 시)

```bash
git clone --recurse-submodules https://github.com/doublecheck-kor/rentre-agents ~/.rentre-agents
```

### Step 4: 글로벌 방식으로 재설치

```bash
cd ~/my-project
bash ~/.rentre-agents/shared-commands/install.sh
```

### Step 5: 변경사항 정리

```bash
# .gitmodules 파일이 비어있으면 제거
[ ! -s .gitmodules ] && rm .gitmodules

git add -A
git commit -m "revert: 서브모듈 방식에서 글로벌 방식으로 롤백"
```

---

## 참고 사항

- 서브모듈 업데이트는 `cd rentre-agents && git pull --recurse-submodules`로 수행합니다.
- 글로벌 커맨드(assistant, help, setup)는 `~/.claude/commands/rentre/`에 유지됩니다.
- 프로젝트 레벨 커맨드는 install.sh가 `.claude/commands/` 아래에 심링크합니다.
- `bmad-profile.json`은 개인 설정이므로 `.gitignore`에 포함하세요.
