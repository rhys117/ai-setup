#!/bin/bash
# clear-advisory-sentinels.sh - Reset once-per-session guards for advisory hooks.
# Advisory scripts touch $CLAUDE_PROJECT_DIR/tmp/.claude-advisory-<name> the first
# time they emit context. Wiping those files on SessionStart means each fresh
# session gets the reminder again at the moment it first becomes relevant.

rm -f "$CLAUDE_PROJECT_DIR"/tmp/.claude-advisory-*
exit 0
