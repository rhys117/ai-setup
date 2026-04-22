Read the domain artefacts to reason about the Rails domain (models + associations + HTTP surface) for architectural questions.

Use this command when the user's question spans multiple aggregates or the answer depends on understanding the shape of the domain — "where does Event touch," "is this service at the right boundary," "what route handles this action," onboarding into an unfamiliar subgraph. Do **not** use it for single-model questions — read the model file directly.

Follow these steps:

1. Regenerate artefacts if any are missing or older than the newest `app/models/**/*.rb` / `app/controllers/**/*.rb` / `config/routes.rb`:
   ```
   bundle exec rake domain:refresh
   ```
   This runs rails-erd, railroady, and a routes dump. Outputs:
   - `tmp/domain-erd.dot` — rails-erd (models + associations in GraphViz dot: entities, FK/PK attrs, polymorphism, inheritance).
   - `tmp/railroady-models.dot` — railroady (columns per model).
   - `tmp/railroady-controllers.dot` — railroady (controllers + their public actions; private/protected hidden).
   - `tmp/routes.json` — filtered HTTP surface (`verb`, `path`, `controller`, `action`, `name`). Rails internal routes (`rails/`, `active_storage/`, etc.) are excluded.

2. Read the relevant artefact(s) once. Don't re-read per entity — hold the relevant artefact in context for this turn:
   - **`tmp/domain-erd.dot`** (rails-erd) — models + associations, FK/PK attrs, polymorphism, inheritance. Primary source for structural reasoning.
   - **`tmp/routes.json`** — HTTP surface. Use when the question is about endpoints.
   - **`tmp/railroady-models.dot`** (railroady) — columns per model. Grep when you need to confirm a column exists without opening the model file.
   - **`tmp/railroady-controllers.dot`** (railroady) — controllers with their *public* actions (private/protected hidden). Use when the question is "which controller has action X" or "what's the shape of controller Y" — faster than reading the controller file.

3. Answer the user's question using the artefacts. Favour structural reasoning:
   - **Aggregate boundaries** — `belongs_to` + `has_many` pairs (in dot edge labels) reveal parent/child vs. peer.
   - **Through associations** — often mark where the real domain logic lives (join models frequently hide business rules).
   - **Polymorphic associations** — flag cross-cutting concerns; useful for deciding shared vs. per-aggregate behaviour.
   - **STI / inheritance** — rails-erd renders this as a specialisation edge; shared behaviour lives in the base class.
   - **Routes** — map `controller#action` → URL. Useful when the user asks "what endpoint creates X" or "is this reachable."

4. Read specific model / controller files only if the artefacts are insufficient (validations, callbacks, scopes, custom methods). The artefacts are for shape, not detail.

Rules:
- Do not dump the full artefact back to the user unless they explicitly ask. Summarise the relevant subgraph.
- If the artefacts predate recent code changes, regenerate them — don't reason from stale structure.
- Controllers are not in a structured map — if you need the controller surface, run `bin/rails routes --json` or read the controller file directly.

---

## Visualisation (human-facing)

`bundle exec rake domain:refresh` (already run in step 1) produces the dot files. To render:

- With graphviz (`brew install graphviz`): `dot -Tpng tmp/domain-erd.dot -o tmp/domain-erd.png` (or `-Tsvg` / `-Tpdf`).
- Without graphviz: paste the dot contents into https://dreampuf.github.io/GraphvizOnline/.

### Scoping the diagram

The full 35-model diagram is noisy. Filter:

- rails-erd: `bundle exec erd --only Event,Activity,Participant --filetype=dot --filename=tmp/subset-erd`
- railroady: `bundle exec railroady -M -s app/models/event.rb,app/models/activity.rb -o tmp/subset.dot`

### When to use which

- **rails-erd** — richer ERD semantics (cardinality, polymorphism, inheritance), prettier output. Use for docs, presentations.
- **railroady** — terser, includes column lists, also does controller diagrams (`bundle exec railroady -C -o tmp/controllers.dot`). Use for whole-codebase overviews.
