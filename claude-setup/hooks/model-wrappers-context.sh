#!/bin/bash
# Dynamic context for write-rules-check.rb's `model_wrapper_delegation` rule.
# Emits an advisory when editing a root AR model that has extracted sibling
# wrappers under app/models/<name>/. Sentinel suffix keys per-model so the
# advisory can fire once for each wrapper-bearing model in a session.

FILE_PATH="${CLAUDE_FILE_PATH:-}"
[ -z "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  */app/models/application_record.rb) exit 0 ;;
  */app/models/*/*) exit 0 ;;
  */app/models/*.rb) ;;
  *) exit 0 ;;
esac

MODEL_NAME=$(basename "$FILE_PATH" .rb)
MODEL_DIR=$(dirname "$FILE_PATH")/"$MODEL_NAME"
[ -d "$MODEL_DIR" ] || exit 0

WRAPPERS=""
for f in "$MODEL_DIR"/*.rb; do
  [ -e "$f" ] || continue
  name=$(basename "$f" .rb)
  WRAPPERS="${WRAPPERS:+$WRAPPERS, }$name"
done
[ -z "$WRAPPERS" ] && exit 0

echo "#sentinel-suffix:$MODEL_NAME"
echo "Editing root model \`$MODEL_NAME\` (existing wrappers: $WRAPPERS). Before adding here, ask: Does this duplicate logic already in a wrapper? Does this belong to a cohesive new responsibility — a signal to extract a new wrapper? Does it have live root callers with no wrapper overlap? If so, staying here is fine. We prefer composition over inheritance to avoid god objects — the larger \`$MODEL_NAME\` grows, the more important this becomes. Only delegate from the root for methods with live callers; grep before adding to the delegate list."
