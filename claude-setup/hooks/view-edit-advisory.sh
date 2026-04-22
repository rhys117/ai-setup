#!/bin/bash
# view-edit-advisory.sh - Remind about UI.* components and color palette when editing view files

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

# Only apply to view/component/erb files
case "$FILE_PATH" in
  */app/views/*|*/app/components/*|*.erb)
    ;;
  *)
    exit 0
    ;;
esac

SENTINEL="$CLAUDE_PROJECT_DIR/tmp/.claude-advisory-view-edit"
[ -f "$SENTINEL" ] && exit 0
mkdir -p "$(dirname "$SENTINEL")" && touch "$SENTINEL"

cat <<'JSON'
{
  "additionalContext": "Editing a view/component file. Rules: (1) Use UI.* components (UI.container, UI.panel, UI.card, etc.) instead of raw HTML. Run /ui-components for full reference. (2) Use semantic color palette names: neutral, warm, app-primary, app-secondary, app-accent, app-danger, warning (shades 50-900). Never use raw Tailwind colors (gray-500, rose-600). Do not confuse with dynamic theming classes (dynamic-primary, bg-dynamic-accent) which are for guest-facing event templates."
}
JSON
exit 0
