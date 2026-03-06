#!/bin/bash
# Session start hook: dependency hygiene checks
# Non-blocking — reports issues but doesn't prevent session start

cd "${CLAUDE_PROJECT_DIR:-.}"

PROJECT="src/SourceGit.csproj"
WARNINGS=""

# 1. NuGet vulnerability audit — find packages with known CVEs
VULN_OUTPUT=$(dotnet list "$PROJECT" package --vulnerable --include-transitive 2>&1)
if echo "$VULN_OUTPUT" | grep -qi "has the following vulnerable packages"; then
    WARNINGS="${WARNINGS}VULNERABLE PACKAGES:\n${VULN_OUTPUT}\n\n"
fi

# 2. Outdated packages — check for outdated NuGet dependencies
OUTDATED_OUTPUT=$(dotnet list "$PROJECT" package --outdated 2>&1)
if echo "$OUTDATED_OUTPUT" | grep -qi "has the following updates available"; then
    WARNINGS="${WARNINGS}OUTDATED PACKAGES (non-blocking):\n${OUTDATED_OUTPUT}\n\n"
fi

if [ -n "$WARNINGS" ]; then
    echo -e "Session start checks found issues:\n${WARNINGS}" >&2
    echo "These are non-blocking warnings. Consider fixing them during this session." >&2
    echo "Re-run this check with: bash \"\${CLAUDE_PROJECT_DIR:-.}\"/.claude/hooks/session-start.sh" >&2
    exit 0
fi

exit 0
