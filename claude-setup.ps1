# Claude Code 세션 중단 대응 시스템 - 셋업 스크립트 (Windows PowerShell)
# 사용법: powershell -ExecutionPolicy Bypass -File claude-setup.ps1

$ErrorActionPreference = "Stop"
$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
$LF = "`n"

$CLAUDE_MD = "CLAUDE.md"
$PROMPTS_DIR = ".claude-prompts"

# --- 템플릿 문자열 ---
$SECTION_RULES = "## 규칙" + $LF +
    "- 응답은 간결하게. 불필요한 요약/설명 생략" + $LF +
    "- 코드 탐색은 subagent(Explore)에 위임하여 메인 컨텍스트 보호" + $LF +
    "- 파일 읽기 시 offset/limit 사용하여 필요한 부분만 읽기" + $LF +
    "- 큰 작업은 반드시 plan 모드로 시작" + $LF +
    "- 단계 완료마다 즉시 git commit (WIP 허용)"

$SECTION_TASK = "## 현재 작업" + $LF +
    "- 상태: 없음" + $LF +
    "- 작업:" + $LF +
    "- 진행:" + $LF +
    "- 다음 단계:" + $LF +
    "- plan 파일:"

$SECTION_RESUME = "## 세션 재개" + $LF +
    '- "이어서" 또는 "계속"이라고 하면 위 ' + "'현재 작업'" + ' 섹션을 참고하여 작업 재개' + $LF +
    "- plan 파일이 있으면 해당 plan의 미완료 항목부터 실행" + $LF +
    "- TODO(claude) 주석이 코드에 있으면 해당 위치부터 작업"

$FULL_TEMPLATE = $SECTION_RULES + $LF + $LF + $SECTION_TASK + $LF + $LF + $SECTION_RESUME

$RESUME_CONTENT = "CLAUDE.md의 '현재 작업' 섹션을 읽고, 중단된 작업을 이어서 진행해줘." + $LF +
    "plan 파일이 있으면 미완료 항목부터 실행." + $LF +
    "코드에 TODO(claude) 주석이 있으면 확인."

$START_TASK_CONTENT = "# 작업: {{작업명}}" + $LF +
    "1. plan 모드로 시작" + $LF +
    "2. plan 완료 후 CLAUDE.md '현재 작업' 섹션 업데이트" + $LF +
    "3. 단계별로 실행하며 완료마다 WIP 커밋" + $LF +
    "4. 모든 단계 완료 시 CLAUDE.md 상태를 '없음'으로 변경"

# --- CLAUDE.md 처리 ---
if (-not (Test-Path $CLAUDE_MD)) {
    Write-Host "CLAUDE.md 생성 중..."
    [System.IO.File]::WriteAllText((Join-Path $PWD $CLAUDE_MD), $FULL_TEMPLATE, $Utf8NoBom)
    Write-Host "  -> CLAUDE.md 생성 완료"
} else {
    Write-Host "CLAUDE.md 이미 존재. 빠진 섹션만 추가..."
    $content = [System.IO.File]::ReadAllText((Join-Path $PWD $CLAUDE_MD))
    $changed = $false

    if ($content -notmatch "## 규칙") {
        $content += $LF + $LF + $SECTION_RULES
        Write-Host "  -> '규칙' 섹션 추가"
        $changed = $true
    }

    if ($content -notmatch "## 현재 작업") {
        $content += $LF + $LF + $SECTION_TASK
        Write-Host "  -> '현재 작업' 섹션 추가"
        $changed = $true
    }

    if ($content -notmatch "## 세션 재개") {
        $content += $LF + $LF + $SECTION_RESUME
        Write-Host "  -> '세션 재개' 섹션 추가"
        $changed = $true
    }

    if ($changed) {
        [System.IO.File]::WriteAllText((Join-Path $PWD $CLAUDE_MD), $content, $Utf8NoBom)
    } else {
        Write-Host "  -> 모든 섹션이 이미 존재. 변경 없음"
    }
}

# --- .claude-prompts/ 처리 ---
if (-not (Test-Path $PROMPTS_DIR)) {
    New-Item -ItemType Directory -Path $PROMPTS_DIR | Out-Null
}

$resumePath = Join-Path $PROMPTS_DIR "resume.md"
if (-not (Test-Path $resumePath)) {
    [System.IO.File]::WriteAllText((Join-Path $PWD $resumePath), $RESUME_CONTENT, $Utf8NoBom)
    Write-Host ".claude-prompts/resume.md 생성 완료"
} else {
    Write-Host ".claude-prompts/resume.md 이미 존재. 건너뜀"
}

$startTaskPath = Join-Path $PROMPTS_DIR "start-task.md"
if (-not (Test-Path $startTaskPath)) {
    [System.IO.File]::WriteAllText((Join-Path $PWD $startTaskPath), $START_TASK_CONTENT, $Utf8NoBom)
    Write-Host ".claude-prompts/start-task.md 생성 완료"
} else {
    Write-Host ".claude-prompts/start-task.md 이미 존재. 건너뜀"
}

# --- git 처리 ---
if (-not (Test-Path ".git")) {
    git init
    Write-Host "git 저장소 초기화 완료"
} else {
    Write-Host "git 저장소 이미 존재. 건너뜀"
}

Write-Host ""
Write-Host "=== 셋업 완료 ===" -ForegroundColor Green
Write-Host "Claude Code를 실행하면 CLAUDE.md가 자동으로 적용됩니다."
Write-Host "작업 재개 시: resume.md 내용을 프롬프트에 붙여넣거나 '이어서 해줘'라고 입력하세요."
