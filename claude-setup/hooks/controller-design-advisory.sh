#!/bin/bash
# controller-design-advisory.sh - Nudge validation/eligibility logic into the model
# when editing controllers, rather than overriding CRUDResource actions.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

case "$FILE_PATH" in
  */app/controllers/*.rb|*/app/controllers/**/*.rb)
    ;;
  *)
    exit 0
    ;;
esac

SENTINEL="$CLAUDE_PROJECT_DIR/tmp/.claude-advisory-controller-design"
[ -f "$SENTINEL" ] && exit 0
mkdir -p "$(dirname "$SENTINEL")" && touch "$SENTINEL"

cat <<'JSON'
{
  "additionalContext": "Editing a controller. If you're about to override a CRUDResource action (create/update/destroy) to add a precondition, stop and ask: can this be a validation on the model? Controllers including CRUDResource route invalid records through handle_failed_save, which already renders form errors with a flash. A validate :foo on the model covers every save path (form, API, console, other controllers) — a controller override only covers this one. Reserve controller overrides for request-specific concerns (auth, params shaping, response format)."
}
JSON
exit 0
