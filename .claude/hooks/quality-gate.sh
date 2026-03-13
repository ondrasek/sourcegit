#!/bin/bash
# Quality gate hook for Claude Code Stop event
# Fail-fast: stops at the first failing check, exit 2 feeds stderr to Claude.
# Checks: format → build → security audit

set -o pipefail

HOOK_LOG="${CLAUDE_PROJECT_DIR:-.}/.claude/hooks/hook-debug.log"
WORKTREE_ID="$(basename "${CLAUDE_PROJECT_DIR:-.}")"
debuglog() {
    echo "[quality-gate@${WORKTREE_ID}] $(date '+%Y-%m-%d %H:%M:%S') $1" >> "$HOOK_LOG"
}
debuglog "=== HOOK STARTED (pid=$$) ==="

PROJECT="src/SourceGit.csproj"

get_hint() {
    case "$1" in
        dotnet-format|dotnet-style) echo "Run 'dotnet format ${PROJECT} --include <file>' to auto-fix formatting. Check .editorconfig rules if the fix doesn't apply. Read the file at the reported location." ;;
        dotnet-build) echo "Read the file at the reported line and column number. Fix the compiler error or analyzer warning. Run 'dotnet build ${PROJECT} --no-restore' to re-check after fixing." ;;
        security-audit) echo "Run 'dotnet list ${PROJECT} package --vulnerable --include-transitive' to see all vulnerable packages. Update the affected package version in the .csproj file." ;;
        *) echo "" ;;
    esac
}

fail() {
    local name="$1"
    local cmd="$2"
    local output="$3"
    local hint
    hint=$(get_hint "$name")

    echo "" >&2
    echo "QUALITY GATE FAILED [$name]:" >&2
    echo "Command: $cmd" >&2
    echo "" >&2
    echo "$output" >&2
    echo "" >&2
    if [ -n "$hint" ]; then
        echo "Hint: $hint" >&2
        echo "" >&2
    fi
    echo "ACTION REQUIRED: You MUST fix the issue shown above. Do NOT stop or explain — read the failing file, edit the source code to resolve it, and the quality gate will re-run automatically." >&2
    debuglog "=== FAILED: $name ==="
    exit 2
}

run_check() {
    local name="$1"; shift
    local cmd="$*"
    debuglog "Running $name..."
    OUTPUT=$("$@" 2>&1) || fail "$name" "$cmd" "$OUTPUT"
}

cd "${CLAUDE_PROJECT_DIR:-.}"

# Restore packages once upfront
dotnet restore "$PROJECT" --verbosity quiet 2>/dev/null

# [check:dotnet-format] Dimension 2: Linting & Formatting
# Split into whitespace + style; analyzer warnings are enforced by the build step.
run_check "dotnet-format" dotnet format whitespace "$PROJECT" --verify-no-changes --verbosity quiet
run_check "dotnet-style"  dotnet format style "$PROJECT" --verify-no-changes --verbosity quiet

# [check:dotnet-build] Dimension 3: Type Safety + Dimension 6: Dead Code
# Build without -warnaserror — .editorconfig error-level rules (IDE0005, CS0649, etc.) enforce strictness.
# Nullable warnings are reported but don't block (gradual adoption for 54K LOC codebase).
run_check "dotnet-build" dotnet build "$PROJECT" --no-restore --verbosity quiet

# [check:security-audit] Dimension 4: Security Analysis
debuglog "Running security-audit..."
VULN_OUTPUT=$(dotnet list "$PROJECT" package --vulnerable --include-transitive 2>&1)
if echo "$VULN_OUTPUT" | grep -qi "has the following vulnerable packages"; then
    fail "security-audit" "dotnet list $PROJECT package --vulnerable --include-transitive" "$VULN_OUTPUT"
fi

debuglog "=== ALL CHECKS PASSED ==="
exit 0
