#!/bin/bash
# ui-screenshot-check.sh - Require screenshot validation when committing UI changes
#
# Flow:
# 1. Commit with UI changes → denied, asks for screenshot
# 2. Claude takes screenshot and verifies → creates .ui-verified flag
# 3. Commit retried → flag found, commit allowed, flag removed

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command')

# Only apply to git commit commands
echo "$COMMAND" | grep -qE '(^|(&&|\|\||;|\|)[[:space:]]*)git[[:space:]]+commit([[:space:]]|$)' || exit 0

cd "$CLAUDE_PROJECT_DIR" || exit 1

FLAG_FILE="$CLAUDE_PROJECT_DIR/tmp/.ui-verified"

# Check staged files for UI-related changes
UI_PATTERNS="app/components/ app/views/ app/assets/ app/javascript/ app/adapters/"
STAGED_FILES=$(git diff --cached --name-only 2>/dev/null)

HAS_UI_CHANGES=false
for pattern in $UI_PATTERNS; do
  if echo "$STAGED_FILES" | grep -q "^$pattern"; then
    HAS_UI_CHANGES=true
    break
  fi
done

# Also check for tailwind/CSS changes
if echo "$STAGED_FILES" | grep -qE "\.(css|scss|erb)$"; then
  HAS_UI_CHANGES=true
fi

if [ "$HAS_UI_CHANGES" = true ]; then
  # If verified flag exists, allow the commit and clean up
  if [ -f "$FLAG_FILE" ]; then
    rm -f "$FLAG_FILE"
    exit 0
  fi

  UI_FILES=$(echo "$STAGED_FILES" | grep -E "(app/components/|app/views/|app/assets/|app/javascript/|app/adapters/|\.css$|\.scss$|\.erb$)" | head -10)
  cat <<JSON
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "UI changes detected in staged files. Take a screenshot of the affected page(s) and verify the visual output before committing. After verifying, run: touch $FLAG_FILE\n\nUI files changed:\n${UI_FILES}"
  }
}
JSON
  exit 2
fi

exit 0
