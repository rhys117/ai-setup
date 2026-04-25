#!/bin/bash
# exhale-reminder.sh - Remind to review for simplicity after committing

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

echo "$COMMAND" | grep -qE '(^|(&&|\|\||;|\|)[[:space:]]*)git[[:space:]]+commit([[:space:]]|$)' || exit 0

# Extract the commit message to check if this was already a refactor/simplify pass
if echo "$COMMAND" | grep -qiE "(refactor|simplify|exhale)"; then
  exit 0
fi

cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "Exhale. You just committed a feature/fix. Review the changes for simplicity, duplication, and design quality. Run `bin/diff-quality` to check for rubycritic regressions and run related specs against main. For a deeper design review (higher token cost), the user can run /simplify-with-analysis explicitly. Do not skip this step."
  }
}
JSON
exit 0
