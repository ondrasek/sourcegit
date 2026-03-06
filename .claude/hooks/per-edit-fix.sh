#!/bin/bash
# Per-edit hook: auto-fix formatting on changed C# files
# Triggered by PostToolUse on Edit|Write
# Exit 0 = success, Exit 2 = unfixable issue fed back to Claude

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.filePath // empty')

# Only process C# files
if [[ -z "$FILE_PATH" ]] || [[ "$FILE_PATH" != *.cs ]]; then
    exit 0
fi

# Verify file exists
if [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

PROJECT="src/SourceGit.csproj"

fail() {
    local name="$1" cmd="$2" output="$3" hint="$4"
    echo "" >&2
    echo "PER-EDIT CHECK FAILED [$name] in ${FILE_PATH}:" >&2
    echo "Command: $cmd" >&2
    echo "" >&2
    echo "$output" >&2
    echo "" >&2
    if [ -n "$hint" ]; then
        echo "Hint: $hint" >&2
        echo "" >&2
    fi
    echo "ACTION REQUIRED: You MUST fix the issue shown above. Read the file at the reported line, edit the source code to resolve it, and the check will re-run on next edit." >&2
    exit 2
}

cd "${CLAUDE_PROJECT_DIR:-.}"

# Auto-fix formatting for the edited file
FORMAT_OUTPUT=$(dotnet format "$PROJECT" --include "$FILE_PATH" --verbosity quiet 2>&1)
FORMAT_EXIT=$?
if [ $FORMAT_EXIT -ne 0 ]; then
    fail "dotnet-format" "dotnet format $PROJECT --include $FILE_PATH" "$FORMAT_OUTPUT" \
        "dotnet format failed to apply formatting. Check for syntax errors in the file that prevent formatting. Run 'dotnet build $PROJECT' to see compilation errors."
fi

# Verify formatting was fully applied
VERIFY_OUTPUT=$(dotnet format "$PROJECT" --include "$FILE_PATH" --verify-no-changes --verbosity quiet 2>&1)
if [ $? -ne 0 ]; then
    fail "dotnet-format-verify" "dotnet format $PROJECT --include $FILE_PATH --verify-no-changes" "$VERIFY_OUTPUT" \
        "dotnet format ran but formatting differences remain. This may indicate conflicting .editorconfig rules. Read the file and fix formatting manually, or check .editorconfig for conflicting settings."
fi

exit 0
