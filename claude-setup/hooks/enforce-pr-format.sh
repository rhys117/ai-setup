#!/bin/bash
# enforce-pr-format.sh - Block gh pr create unless body follows the required format
# Reminds to use /create-pull-request skill

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

echo "$COMMAND" | grep -qE '(^|(&&|\|\||;|\|)[[:space:]]*)gh[[:space:]]+pr[[:space:]]+create([[:space:]]|$)' || exit 0

# Check the command includes --body with required sections
if echo "$COMMAND" | grep -q "## Description" && echo "$COMMAND" | grep -q "## Testing"; then
  exit 0
fi

cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "PR body must include '## Description' and '## Testing' sections. Use the /create-pull-request skill to generate the correct format."
  }
}
JSON
exit 2
