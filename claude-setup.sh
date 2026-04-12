#!/usr/bin/env bash
# Claude Code 세션 중단 대응 시스템 - 셋업 스크립트 (Linux/macOS)
# 사용법: bash claude-setup.sh

set -euo pipefail

CLAUDE_MD="CLAUDE.md"
PROMPTS_DIR=".claude-prompts"

# --- CLAUDE.md 템플릿 섹션 ---
SECTION_RULES='## 규칙
- 응답은 간결하게. 불필요한 요약/설명 생략
- 코드 탐색은 subagent(Explore)에 위임하여 메인 컨텍스트 보호
- 파일 읽기 시 offset/limit 사용하여 필요한 부분만 읽기
- 큰 작업은 반드시 plan 모드로 시작
- 단계 완료마다 즉시 git commit (WIP 허용)'

SECTION_TASK='## 현재 작업
- 상태: 없음
- 작업:
- 진행:
- 다음 단계:
- plan 파일:'

SECTION_RESUME='## 세션 재개
- "이어서" 또는 "계속"이라고 하면 위 '"'"'현재 작업'"'"' 섹션을 참고하여 작업 재개
- plan 파일이 있으면 해당 plan의 미완료 항목부터 실행
- TODO(claude) 주석이 코드에 있으면 해당 위치부터 작업'

# --- CLAUDE.md 처리 ---
if [ ! -f "$CLAUDE_MD" ]; then
    echo "CLAUDE.md 생성 중..."
    cat > "$CLAUDE_MD" << 'EOF'
## 규칙
- 응답은 간결하게. 불필요한 요약/설명 생략
- 코드 탐색은 subagent(Explore)에 위임하여 메인 컨텍스트 보호
- 파일 읽기 시 offset/limit 사용하여 필요한 부분만 읽기
- 큰 작업은 반드시 plan 모드로 시작
- 단계 완료마다 즉시 git commit (WIP 허용)

## 현재 작업
- 상태: 없음
- 작업:
- 진행:
- 다음 단계:
- plan 파일:

## 세션 재개
- "이어서" 또는 "계속"이라고 하면 위 '현재 작업' 섹션을 참고하여 작업 재개
- plan 파일이 있으면 해당 plan의 미완료 항목부터 실행
- TODO(claude) 주석이 코드에 있으면 해당 위치부터 작업
EOF
    echo "  -> CLAUDE.md 생성 완료"
else
    echo "CLAUDE.md 이미 존재. 빠진 섹션만 추가..."
    changed=false

    if ! grep -q "## 규칙" "$CLAUDE_MD"; then
        printf '\n%s\n' "$SECTION_RULES" >> "$CLAUDE_MD"
        echo "  -> '규칙' 섹션 추가"
        changed=true
    fi

    if ! grep -q "## 현재 작업" "$CLAUDE_MD"; then
        printf '\n%s\n' "$SECTION_TASK" >> "$CLAUDE_MD"
        echo "  -> '현재 작업' 섹션 추가"
        changed=true
    fi

    if ! grep -q "## 세션 재개" "$CLAUDE_MD"; then
        printf '\n%s\n' "$SECTION_RESUME" >> "$CLAUDE_MD"
        echo "  -> '세션 재개' 섹션 추가"
        changed=true
    fi

    if [ "$changed" = false ]; then
        echo "  -> 모든 섹션이 이미 존재. 변경 없음"
    fi
fi

# --- .claude-prompts/ 처리 ---
mkdir -p "$PROMPTS_DIR"

if [ ! -f "$PROMPTS_DIR/resume.md" ]; then
    cat > "$PROMPTS_DIR/resume.md" << 'EOF'
CLAUDE.md의 '현재 작업' 섹션을 읽고, 중단된 작업을 이어서 진행해줘.
plan 파일이 있으면 미완료 항목부터 실행.
코드에 TODO(claude) 주석이 있으면 확인.
EOF
    echo ".claude-prompts/resume.md 생성 완료"
else
    echo ".claude-prompts/resume.md 이미 존재. 건너뜀"
fi

if [ ! -f "$PROMPTS_DIR/start-task.md" ]; then
    cat > "$PROMPTS_DIR/start-task.md" << 'EOF'
# 작업: {{작업명}}
1. plan 모드로 시작
2. plan 완료 후 CLAUDE.md '현재 작업' 섹션 업데이트
3. 단계별로 실행하며 완료마다 WIP 커밋
4. 모든 단계 완료 시 CLAUDE.md 상태를 '없음'으로 변경
EOF
    echo ".claude-prompts/start-task.md 생성 완료"
else
    echo ".claude-prompts/start-task.md 이미 존재. 건너뜀"
fi

# --- git 처리 ---
if [ ! -d ".git" ]; then
    git init
    echo "git 저장소 초기화 완료"
else
    echo "git 저장소 이미 존재. 건너뜀"
fi

echo ""
echo "=== 셋업 완료 ==="
echo "Claude Code를 실행하면 CLAUDE.md가 자동으로 적용됩니다."
echo "작업 재개 시: resume.md 내용을 프롬프트에 붙여넣거나 '이어서 해줘'라고 입력하세요."
