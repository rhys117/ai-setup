#!/bin/bash
# protect-main.sh - Block commits and pushes to main branch

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

# Block git commit on main
if echo "$COMMAND" | grep -qE '(^|(&&|\|\||;|\|)[[:space:]]*)git[[:space:]]+commit([[:space:]]|$)' && [ "$CURRENT_BRANCH" = "main" ]; then
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Cannot commit directly to main. Create a feature branch first."
  }
}
JSON
  exit 2
fi

# Block git push to main (any form: git push, git push origin main, git push -u origin main)
if echo "$COMMAND" | grep -qE '(^|(&&|\|\||;|\|)[[:space:]]*)git[[:space:]]+push([[:space:]]|$)' && ([ "$CURRENT_BRANCH" = "main" ] || echo "$COMMAND" | grep -qE "\bmain\b"); then
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Cannot push to main. Use a feature branch and open a PR."
  }
}
JSON
  exit 2
fi

exit 0
