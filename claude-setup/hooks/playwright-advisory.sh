#!/bin/bash
# playwright-advisory.sh - Load manual testing skill when Playwright is used

SENTINEL="$CLAUDE_PROJECT_DIR/tmp/.claude-advisory-playwright"
[ -f "$SENTINEL" ] && exit 0
mkdir -p "$(dirname "$SENTINEL")" && touch "$SENTINEL"

DIR_NAME=$(basename "$CLAUDE_PROJECT_DIR")
HOST="${DIR_NAME}.test"

cat <<JSON
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "IMPORTANT: You are about to use Playwright for browser testing. You MUST first load the /manual-testing skill using the Skill tool before proceeding with any browser interactions. This ensures you follow the project's manual testing strategy.\n\nQuick reference while skill loads:\n- App URL: http://${HOST}\n- Auto-login: generate a token with \`rake 'dev:auto_login_token[EVENT_ID]'\` and append \`?auto_login_token=<TOKEN>\` to any URL\n- Manual login fallback: /users/sign_in with any seeded user from db/seeds.rb\n- You may be in a worktree with a different directory name — the hostname matches the directory name."
  }
}
JSON
exit 0
