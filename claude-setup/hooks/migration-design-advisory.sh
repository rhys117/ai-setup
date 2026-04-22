#!/bin/bash
# migration-design-advisory.sh - Pause before writing a migration to confirm
# persistence is actually needed and the column design holds up.

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""')

case "$FILE_PATH" in
  */db/migrate/*.rb)
    ;;
  *)
    exit 0
    ;;
esac

SENTINEL="$CLAUDE_PROJECT_DIR/tmp/.claude-advisory-migration-design"
[ -f "$SENTINEL" ] && exit 0
mkdir -p "$(dirname "$SENTINEL")" && touch "$SENTINEL"

cat <<'JSON'
{
  "additionalContext": "Editing a migration. STOP and confirm before proceeding: (1) PERSISTENCE NECESSARY? Walk the data's lifecycle — ephemeral (params), session, user pref (jsonb), or genuine domain state. If it's 1-2, do not persist; ask the user if unsure. (2) BOOLEAN? Only for a real two-state flag with no foreseeable third state. Prefer status enums or timestamps (activated_at, archived_at) — they carry more information and leave room to grow. (3) NAMING — drop table-name prefixes on columns (posts.post_title → posts.title; shared_photo_configurations.poster_prompt_line → .prompt_line). Apply the same rule to associations. (4) ARRAY/JSONB — flexible but not query-friendly; reach for a join table if you'll ever filter/count by individual entries. (5) BACKFILL — never combine a NOT NULL add + data backfill in one migration on an existing table. Run /database-conventions for the full checklist."
}
JSON
exit 0
