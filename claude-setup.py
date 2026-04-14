#!/usr/bin/env python3
# Claude Code 세션 중단 대응 시스템 - 셋업 스크립트 (Python)
# 사용법: python claude-setup.py

import subprocess
import sys
from pathlib import Path

CLAUDE_MD = Path("CLAUDE.md")
PROMPTS_DIR = Path(".claude-prompts")

SECTION_RULES = """\
## 규칙
- 응답은 간결하게. 불필요한 요약/설명 생략
- 코드 탐색은 subagent(Explore)에 위임하여 메인 컨텍스트 보호
- 파일 읽기 시 offset/limit 사용하여 필요한 부분만 읽기
- 큰 작업은 반드시 plan 모드로 시작
- 단계 완료마다 즉시 git commit (WIP 허용)"""

SECTION_TASK = """\
## 현재 작업
- 상태: 없음
- 작업:
- 진행:
- 다음 단계:
- plan 파일:"""

SECTION_RESUME = """\
## 세션 재개
- "이어서" 또는 "계속"이라고 하면 위 '현재 작업' 섹션을 참고하여 작업 재개
- plan 파일이 있으면 해당 plan의 미완료 항목부터 실행
- TODO(claude) 주석이 코드에 있으면 해당 위치부터 작업"""

FULL_TEMPLATE = f"{SECTION_RULES}\n\n{SECTION_TASK}\n\n{SECTION_RESUME}\n"

RESUME_CONTENT = """\
CLAUDE.md의 '현재 작업' 섹션을 읽고, 중단된 작업을 이어서 진행해줘.
plan 파일이 있으면 미완료 항목부터 실행.
코드에 TODO(claude) 주석이 있으면 확인.
"""

START_TASK_CONTENT = """\
# 작업: {{작업명}}
1. plan 모드로 시작
2. plan 완료 후 CLAUDE.md '현재 작업' 섹션 업데이트
3. 단계별로 실행하며 완료마다 WIP 커밋
4. 모든 단계 완료 시 CLAUDE.md 상태를 '없음'으로 변경
"""


def write_utf8(path: Path, content: str) -> None:
    path.write_text(content, encoding="utf-8")


def setup_claude_md() -> None:
    if not CLAUDE_MD.exists():
        print("CLAUDE.md 생성 중...")
        write_utf8(CLAUDE_MD, FULL_TEMPLATE)
        print("  -> CLAUDE.md 생성 완료")
        return

    print("CLAUDE.md 이미 존재. 빠진 섹션만 추가...")
    content = CLAUDE_MD.read_text(encoding="utf-8")
    changed = False

    if "## 규칙" not in content:
        content += f"\n\n{SECTION_RULES}"
        print("  -> '규칙' 섹션 추가")
        changed = True

    if "## 현재 작업" not in content:
        content += f"\n\n{SECTION_TASK}"
        print("  -> '현재 작업' 섹션 추가")
        changed = True

    if "## 세션 재개" not in content:
        content += f"\n\n{SECTION_RESUME}"
        print("  -> '세션 재개' 섹션 추가")
        changed = True

    if changed:
        write_utf8(CLAUDE_MD, content)
    else:
        print("  -> 모든 섹션이 이미 존재. 변경 없음")


def setup_prompts() -> None:
    PROMPTS_DIR.mkdir(exist_ok=True)

    resume_path = PROMPTS_DIR / "resume.md"
    if not resume_path.exists():
        write_utf8(resume_path, RESUME_CONTENT)
        print(".claude-prompts/resume.md 생성 완료")
    else:
        print(".claude-prompts/resume.md 이미 존재. 건너뜀")

    start_task_path = PROMPTS_DIR / "start-task.md"
    if not start_task_path.exists():
        write_utf8(start_task_path, START_TASK_CONTENT)
        print(".claude-prompts/start-task.md 생성 완료")
    else:
        print(".claude-prompts/start-task.md 이미 존재. 건너뜀")


def setup_git() -> None:
    if not Path(".git").exists():
        subprocess.run(["git", "init"], check=True)
        print("git 저장소 초기화 완료")
    else:
        print("git 저장소 이미 존재. 건너뜀")


if __name__ == "__main__":
    try:
        setup_claude_md()
        setup_prompts()
        setup_git()
        print("\n=== 셋업 완료 ===")
        print("Claude Code를 실행하면 CLAUDE.md가 자동으로 적용됩니다.")
        print("작업 재개 시: resume.md 내용을 프롬프트에 붙여넣거나 '이어서 해줘'라고 입력하세요.")
    except Exception as e:
        print(f"오류 발생: {e}", file=sys.stderr)
        sys.exit(1)
