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
  "additionalContext": "Exhale. You just committed a feature/fix. Review the changes for simplicity, duplication, and design quality. If cleanup is needed, run /simplify-with-analysis. Do not skip this step."
}
JSON
exit 0
