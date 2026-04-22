#!/bin/bash
# service-design-advisory.sh - Enforce DDD service design rules when touching app/services/

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

case "$FILE_PATH" in
  */app/services/*)
    ;;
  *)
    exit 0
    ;;
esac

SENTINEL="$CLAUDE_PROJECT_DIR/tmp/.claude-advisory-service-design"
[ -f "$SENTINEL" ] && exit 0
mkdir -p "$(dirname "$SENTINEL")" && touch "$SENTINEL"

cat <<'JSON'
{
  "additionalContext": "You are creating or editing a service object. STOP and verify this belongs here. Services in app/services/ must encapsulate meaningful cross-aggregate domain operations (DDD). If this service only wraps .save, .update, or .create on a single model, it belongs in the model or controller — not here. Ask: does this coordinate behavior across multiple aggregates? If not, move the logic closer to the model. Also consider: could this be a model method, a callback, or a concern instead?"
}
JSON
exit 0
