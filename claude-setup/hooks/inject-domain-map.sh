#!/bin/bash
# inject-domain-map.sh - Inject a compact rails-erd dot + flat routes list as
# additional context when the user invokes /plan. Regenerates artefacts if
# missing. The raw rails-erd dot embeds ~30KB of HTML <table> label markup
# per run; we strip that inline so the payload fits under the harness's
# additionalContext cap (raw + routes.json together blow past ~100KB and get
# persisted to a file instead of injected).

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Only fire on /plan at the start of the prompt (argument form allowed).
echo "$PROMPT" | grep -qE '^/plan(\s|$)' || exit 0

ERD_PATH="tmp/domain-erd.dot"
RAILROADY_PATH="tmp/railroady-models.dot"
ROUTES_PATH="tmp/routes.json"

# Regenerate only if any artefact is missing — Rails env + rails-erd load
# is expensive, and the /domain-map command handles staleness on-demand.
if [ ! -f "$ERD_PATH" ] || [ ! -f "$RAILROADY_PATH" ] || [ ! -f "$ROUTES_PATH" ]; then
  bundle exec rake domain:refresh > /dev/null 2>&1 || exit 0
fi

[ -f "$ERD_PATH" ] && [ -f "$ROUTES_PATH" ] || exit 0

# Strip rails-erd HTML table labels down to plain `label="ModelName"`. The
# tables carry per-column PK/FK markup that's useful for PNG rendering but
# pure noise for structural reasoning — the edges below encode the domain.
ERD=$(ruby -e '
  s = STDIN.read
  s.gsub!(/label = <\{.*?<font[^>]+point-size="11">([^<]+)<\/font>.*?\}>/m) { %Q(label="#{$1}") }
  print s
' < "$ERD_PATH") || exit 0

# Flatten routes.json to one `VERB PATH controller#action` line per route.
ROUTES=$(jq -r '.[] | "\(.verb // "ANY") \(.path) \(.controller)#\(.action)"' "$ROUTES_PATH") || exit 0

[ -z "$ERD" ] && exit 0

jq -n --arg erd "$ERD" --arg routes "$ROUTES" --arg railroady "$RAILROADY_PATH" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: (
      "# STOP — if this appears as a truncated preview\n\n" +
      "If the harness has wrapped this context in a `<persisted-output>` block with \"Output too large\" and a \"Full output saved to:\" pointer, your VERY NEXT action MUST be to Read that file. The preview cuts off mid-graph — you will miss most model edges and the entire routes list. Do NOT spawn Explore/Agent subagents, do NOT run Grep/Glob/Read over `app/models/**` or `config/routes.rb`, and do NOT answer the user until you have read the full persisted file.\n\n" +
      "---\n\n" +
      "# Domain context — AUTHORITATIVE for this /plan. Read before exploring.\n\n" +
      "The rails-erd dot and routes list below are extracted from the running Rails app via `bundle exec rake domain:refresh`. They encode every ApplicationRecord model, its associations (edges), and every non-internal HTTP route.\n\n" +
      "**Use this block as your primary source of truth for domain shape and HTTP surface.** Before spawning Explore/Agent subagents or running Grep/Glob/Read over `app/models/**` or `config/routes.rb` to answer \"where does X live\", \"what associates with Y\", or \"what endpoint serves Z\", consult this block first — it already answers those. Only drop to file reads for behavioural detail the dot does not expose: validations, callbacks, scopes, column types, instance methods, controller action bodies.\n\n" +
      "If this block conflicts with recent code changes, run `bundle exec rake domain:refresh` and retry.\n\n" +
      "Edge reading guide (rails-erd conventions):\n" +
      "- `A -> B` solid arrow = `A has_many/has_one B` (B `belongs_to` A).\n" +
      "- `A -> B` dotted (`constraint = \"false\"`) = through or polymorphic association.\n" +
      "- `A -> B` grey with `arrowtail = \"onormal\"` = B inherits from A (STI / abstract parent).\n\n" +
      "## Models + associations (rails-erd dot, HTML column tables stripped)\n```dot\n" + $erd + "\n```\n\n" +
      "## HTTP surface (VERB PATH controller#action)\n```\n" + $routes + "\n```\n\n" +
      "## Richer artefacts — on demand only, do NOT read upfront\n" +
      "- `" + $railroady + "` — railroady dot with public methods per model. Grep when the question is method-level (\"which model exposes X\", \"what does controller Y call on model Z\").\n" +
      "- `tmp/railroady-controllers.dot` — controllers + public actions.\n" +
      "- `tmp/domain-erd.dot` — original rails-erd dot with per-column PK/FK tables, for PNG rendering (`dot -Tpng …`).\n" +
      "- `tmp/routes.json` — structured route entries including `name` (URL helper)."
    )
  }
}'
exit 0
