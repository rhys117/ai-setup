#!/bin/bash
# pre-pr-review.sh - Run tests before allowing PR creation

set -e

cd "$CLAUDE_PROJECT_DIR" || exit 1

echo "Running test suite before PR creation..." >&2
OUTPUT=$(bundle exec parallel_rspec 2>&1) || true
echo "$OUTPUT" >&2

# Check the summary line for actual test failures (not SimpleCov errors)
SUMMARY=$(echo "$OUTPUT" | grep -E "[0-9]+ examples, [0-9]+ failures" | tail -1)

if echo "$SUMMARY" | grep -qE " 0 failures"; then
  echo "All tests passed." >&2
  exit 0
else
  cat <<'JSON'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Tests are failing. Fix failing tests before opening a PR."
  }
}
JSON
  exit 2
fi
