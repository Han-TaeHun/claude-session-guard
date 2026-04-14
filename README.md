# Claude Session Guard

Claude Code 사용 중 토큰 제한으로 세션이 중단되었을 때, 다음 세션에서 빠르게 작업을 재개할 수 있도록 도와주는 셋업 스크립트입니다.

## 해결하는 문제

- 토큰 제한에 걸려 작업이 중단되면 컨텍스트를 잃음
- 다음 세션에서 같은 설명을 반복해야 함
- 어디까지 진행했는지 파악이 어려움

## 구성 파일

| 파일 | 설명 |
|------|------|
| `claude-setup.py` | Windows / Linux / macOS Python 셋업 스크립트 (권장) |
| `claude-setup.ps1` | Windows PowerShell 셋업 스크립트 |
| `claude-setup.sh` | Linux / macOS bash 셋업 스크립트 |
| `CLAUDE.md` | 토큰 절약 규칙 + 작업 추적 + 세션 재개 규칙 (스크립트가 생성) |
| `.claude-prompts/resume.md` | 작업 재개용 프롬프트 템플릿 (스크립트가 생성) |
| `.claude-prompts/start-task.md` | 새 작업 시작용 프롬프트 템플릿 (스크립트가 생성) |

## 사용법

### 1. 셋업

원하는 프로젝트 폴더에서 스크립트를 실행합니다.

**Python (Windows / Linux / macOS — 권장):**
```bash
python claude-setup.py
```

**Windows (PowerShell — 권한 오류 시 위 Python 방식 사용):**
```powershell
powershell -ExecutionPolicy Bypass -File claude-setup.ps1
```

**Linux / macOS:**
```bash
bash claude-setup.sh
```

### 2. 작업 흐름

1. Claude Code 실행 시 `CLAUDE.md`가 자동으로 로드됩니다.
2. 작업 시작 시 Claude가 `CLAUDE.md`의 "현재 작업" 섹션을 업데이트합니다.
3. 세션이 중단되더라도 다음 세션에서 **"이어서 해줘"** 한마디로 재개됩니다.

### 3. 세션 재개 방법

세션이 중단된 후 Claude Code를 다시 실행하고:

```
이어서 해줘
```

또는 `.claude-prompts/resume.md`의 내용을 붙여넣으면 됩니다.

## 주요 기능

### 토큰 절약 규칙
`CLAUDE.md`에 포함된 규칙이 Claude의 응답을 간결하게 유지합니다:
- 불필요한 요약/설명 생략
- 코드 탐색은 subagent에 위임 (메인 컨텍스트 보호)
- 파일 읽기 시 필요한 부분만 읽기

### 작업 상태 추적
`CLAUDE.md`의 "현재 작업" 섹션이 진행 상황을 기록합니다:
```markdown
## 현재 작업
- 상태: 진행중
- 작업: 인증 모듈 리팩토링
- 진행: 3/5 단계 완료
- 다음 단계: 토큰 검증 로직 구현
- plan 파일: ~/.claude/plans/auth-refactor.md
```

### TODO(claude) 마커
코드에 진행 상태를 직접 표시합니다:
```javascript
// TODO(claude): 다음 - 에러 핸들링 추가
```
재개 시 `grep TODO(claude)`로 이어갈 위치를 즉시 파악합니다.

### WIP 커밋
단계 완료마다 체크포인트 커밋을 생성합니다:
```
[WIP] 2/5: 인증 미들웨어 구현
[WIP] 3/5: 라우트 연결
```

## 이미 CLAUDE.md가 있는 프로젝트에서

스크립트는 멱등성을 보장합니다:
- 기존 `CLAUDE.md` 내용을 보존하고, 빠진 섹션만 추가
- 이미 있는 파일은 건너뜀
- 몇 번을 실행해도 동일한 결과

## 다른 컴퓨터에서 사용

```bash
git clone https://github.com/Han-TaeHun/claude-session-guard.git
```

`claude-setup.ps1`과 `claude-setup.sh`를 원하는 프로젝트 폴더에 복사한 뒤 실행하면 됩니다.
