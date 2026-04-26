#!/bin/bash
# inject-domain-map.sh - Inject a compact model graph as additional context
# when the user invokes /plan. Regenerates artefacts if missing.
#
# Models are the primary signal for /plan reasoning; a filtered + compacted
# rails-erd graph fits inline under the harness's ~10KB additionalContext cap.
# Routes are kept as an on-disk artefact with a pointer — Claude greps
# tmp/routes.json when a specific endpoint matters, rather than scanning ~160
# route lines on every /plan.

INPUT=$(cat)
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')

# Only fire on /plan at the start of the prompt (argument form allowed).
echo "$PROMPT" | grep -qE '^/plan(\s|$)' || exit 0

ERD_PATH="tmp/domain-erd.dot"
RAILROADY_PATH="tmp/railroady-models.dot"
ROUTES_PATH="tmp/routes.json"
WRAPPERS_PATH="tmp/model-wrappers.json"

# Regenerate only if any artefact is missing — Rails env + rails-erd load
# is expensive, and the /domain-map command handles staleness on-demand.
if [ ! -f "$ERD_PATH" ] || [ ! -f "$RAILROADY_PATH" ] || [ ! -f "$ROUTES_PATH" ] || [ ! -f "$WRAPPERS_PATH" ]; then
  bundle exec rake domain:refresh > /dev/null 2>&1 || exit 0
fi

[ -f "$ERD_PATH" ] && [ -f "$ROUTES_PATH" ] || exit 0

# Parse rails-erd dot into three compact markdown sections:
#   - has_many/has_one edges (solid arrows)
#   - polymorphic/through edges (dotted, constraint=false)
#   - STI hierarchies (arrowtail=onormal), grouped by parent
#
# Filters out noise namespaces (ActiveAdmin, ActiveStorage, ActionText,
# ActionMailbox, GoodJob, PaperTrail, Ahoy) and the universal
# `ApplicationRecord -> *` STI edges — both are infrastructure, not domain.
ERD=$(ruby -e '
  NOISE_RE = /\b(ActionMailbox|ActionText|ActiveAdmin|ActiveStorage|GoodJob|PaperTrail|Ahoy)::/

  def noisy?(name)
    name =~ NOISE_RE || name == "ApplicationRecord"
  end

  s = STDIN.read
  # Collapse rails-erd HTML table labels to plain label="Name".
  s.gsub!(/label = <\{.*?<font[^>]+point-size="11">([^<]+)<\/font>.*?\}>/m) { %Q(label="#{$1}") }

  nodes = []
  has_many = []
  polymorphic = []
  sti = Hash.new { |h, k| h[k] = [] }

  s.each_line do |line|
    if m = line.match(/"?m_(?<a>[\w:]+)"?\s*->\s*"?m_(?<b>[\w:]+)"?\s*\[(?<attrs>[^\]]*)\]/)
      a, b, attrs = m[:a], m[:b], m[:attrs]
      next if noisy?(a) || noisy?(b)
      if attrs.include?(%q(constraint = "false"))
        polymorphic << [a, b]
      elsif attrs.include?(%q(arrowtail = "onormal"))
        sti[a] << b
      else
        has_many << [a, b]
      end
    elsif m = line.match(/"?m_[\w:]+"?\s*\[.*label="([^"]+)"/)
      name = m[1]
      nodes << name unless noisy?(name)
    end
  end

  out = []
  out << "### Models\n"
  out << nodes.uniq.sort.join(", ") + "\n"
  out << "\n### has_many / has_one  (A -> B means A has_many/has_one B; B belongs_to A)\n"
  has_many.sort.uniq.each { |a, b| out << "#{a} -> #{b}\n" }
  unless polymorphic.empty?
    out << "\n### Polymorphic / through  (-.->)\n"
    polymorphic.sort.uniq.each { |a, b| out << "#{a} -.-> #{b}\n" }
  end
  unless sti.empty?
    out << "\n### STI / inheritance  (parent ==> children)\n"
    sti.sort.each { |parent, children| out << "#{parent} ==> #{children.sort.uniq.join(", ")}\n" }
  end
  print out.join
' < "$ERD_PATH") || exit 0

# Flatten model-wrappers.json to one `Model: Wrapper1, Wrapper2, ...` line per
# AR model that has extracted sibling POROs/concerns in `app/models/<model>/`.
# These are invisible to rails-erd (not ActiveRecord descendants) but are where
# most of the domain logic is actually encapsulated.
if [ -f "$WRAPPERS_PATH" ]; then
  WRAPPERS=$(jq -r 'to_entries[] | "- \(.key): \(.value | join(", "))"' "$WRAPPERS_PATH")
else
  WRAPPERS=""
fi

[ -z "$ERD" ] && exit 0

jq -n --arg erd "$ERD" --arg wrappers "$WRAPPERS" --arg railroady "$RAILROADY_PATH" '{
  hookSpecificOutput: {
    hookEventName: "UserPromptSubmit",
    additionalContext: (
      "# Domain context — AUTHORITATIVE for this /plan. Read before exploring.\n\n" +
      "Extracted from the running Rails app via `bundle exec rake domain:refresh`. Infrastructure noise (ActiveAdmin, ActiveStorage, ActionText, ActionMailbox, GoodJob, PaperTrail, Ahoy) is filtered; only app domain remains.\n\n" +
      "**Use this as primary source for domain shape.** Before Grep/Glob/Read over `app/models/**`, consult this block — it already answers \"where does X live\" and \"what associates with Y\". Drop to file reads only for behavioural detail (validations, callbacks, scopes, instance methods).\n\n" +
      "If this conflicts with recent code, run `bundle exec rake domain:refresh`.\n\n" +
      "## Model graph\n" + $erd + "\n" +
      "## Extracted sibling POROs/concerns per AR model\n" +
      "These live at `app/models/<model>/*.rb` and hold most of the domain logic — wrappers like `Participant::ContactCapabilities` (accessed via `participant.contact_capabilities`) and concerns included into the root model. **Rails-erd does not capture them.** Before adding a new predicate, query, or helper method directly to the root model, scan this list and check whether one of these is the right home, or whether a new sibling class should be created here instead.\n" +
      "```\n" + $wrappers + "\n```\n\n" +
      "## On-disk artefacts (read when needed, not upfront)\n" +
      "- `tmp/routes.json` — all HTTP routes (`VERB path controller#action name`). Grep this when asked about a specific endpoint; do not inline upfront.\n" +
      "- `" + $railroady + "` — model public methods. Grep for method-level questions (\"which model exposes X\").\n" +
      "- `tmp/railroady-controllers.dot` — controllers + public actions.\n" +
      "- `tmp/domain-erd.dot` — full rails-erd dot with column tables (PNG render: `dot -Tpng`)."
    )
  }
}'
exit 0
