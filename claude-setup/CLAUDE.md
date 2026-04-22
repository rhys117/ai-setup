# MUST FOLLOW RULES
- NEVER commit to the `main` branch
- Commit changes often. Follow conventional commits pattern.
  - DO NOT co-author commits with Claude or any AI tool
  - ALWAYS include [skip ci] in the commit message to avoid triggering CI on every commit unless asked not to.
- Do not leave comments unless absolutely necessary. Remove all commented-out code before committing.
- Remove all dead code before committing (unless it's intentional WIP methods for future use).

# Project Overview
"They Said Yes" is a Ruby on Rails 8.1 event management and RSVP system.

## Technology Stack
- **Backend**: Ruby 4, Rails 8.1
- **Database**: PostgreSQL
- **Frontend**: Tailwind CSS, Alpine.js, Turbo
- **Background Jobs**: GoodJob
- **Communications**: ClickSend (SMS), ActionMailer (Email) using AWS SES
- **Testing**: RSpec
- **Native**: Application development is done on the native environment (not containerised locally)

# Code Style & Conventions

## Ruby/Rails Conventions
- Follow Rails 8.1 best practices
- Use concerns for shared functionality
- Follow RESTful conventions
  - Where it makes sense build objects that nest off each and use REST rather than custom controller actions
  - Use our ResourceManagement and Adapter patterns to leverage DSLs and self building responses
- Use Rails validations and callbacks appropriately

## Frontend Conventions
- Use Tailwind CSS, Alpine.js, Turbo, BEM naming — see `/ui-components` for full reference including color palette

# Design Philosophy: Beck's Four Rules of Simple Design

All design decisions should be evaluated against these rules, in priority order:

1. **Passes the tests** — correctness is non-negotiable
2. **Reveals intention** — code should communicate its purpose to readers
3. **No duplication** — state everything once and only once (DRY). Eliminating duplication is a powerful way to drive out good design
4. **Fewest elements** — remove anything that doesn't serve the first three rules. No speculative abstractions

Rules 2 and 3 can tension each other — making something DRY can obscure intent. Resolve through refactoring, not by abandoning either rule.

ALWAYS apply these rules. REMIND yourself of them often.

# Development Workflow: Inhale / Exhale

Follow Kent Beck's breathing rhythm for augmented development. The agent (you) excels at adding features but will degrade design quality over time unless the "exhale" is enforced.

ALWAYS keep this rhythm.

## Inhale: Implement (RED → GREEN)
- Write a failing test (RED)
- Make it pass with the simplest implementation (GREEN)
- Commit the passing test + implementation

## Exhale: Simplify (REFACTOR)
- After the feature works, run `/simplify-with-analysis` to review for design quality (wraps `/simplify` with a rubycritic regression check against `main`)
- Look for:
  - Duplicate code, unnecessary abstraction, coupling introduced, naming that drifted
  - **Inline ERB markup that mirrors patterns elsewhere** — palette cards, font cards, decoration buttons, toggle switches, swatch grids, selectable items, panels. Cross-view duplication is the primary signal that a `UI.*` helper is needed. If a helper exists, swap to it; if not, extract one.
  - **ViewComponent helper methods that build Alpine/JS payload shapes duplicated across components** (e.g. `theme_sets_data_for_alpine`, `font_pairings_data`). Push these to the model (`ThemeSet.alpine_payload`, etc.) so callers stop redefining shape.
  - Service objects that just wrap CRUD — push back to model or controller.
- Commit the cleanup separately from the feature

## Rhythm
- Small, focused commits between phases — never mix feature and refactor in one commit
- The exhale is **not optional**. If you skip it, complexity compounds and future work slows down
- For minor changes (typos, config tweaks), the exhale can be skipped

# Architectural Fitness Rules

These structural constraints encode decisions the codebase has already made. Follow them unless you have an explicit reason not to — and if you deviate, justify it in the commit message.

## Controllers MUST use CRUDResource
New controllers that manage a resource MUST include `CRUDResource` and follow the adapter pattern. Use the `/create-resource-controller` skill for scaffolding. Only bypass this for non-resource controllers (e.g., dashboards, static pages, custom API endpoints).

## Views MUST use UI.* components
Before writing structured ERB (cards, grids, buttons, panels, swatches, toggles, selectable items, dropdowns), open `app/components/ui/**/methods.rb` to enumerate available helpers. Use the `/ui-components` skill for full reference.

Decision order:
1. **Use an existing helper** if one fits — even partially. Pass Alpine bindings as props (`alpine_selected:`, `alpine_click:`, etc.).
2. **If a similar pattern already exists in another view** (`app/components/app/**`, `app/views/**`) but no helper yet, *extract it to `UI.*` before adding the second copy*. Duplication across views is a primary smell.
3. **Only fall through to raw HTML** if no helper exists AND the element is too specific to warrant a new component. Justify the call in the commit message.

Alpine/JS payload shapes (e.g. `theme_sets_data_for_alpine`, `font_pairings_data`) belong on the model (`ThemeSet.alpine_payload`, `FontPairing.alpine_payload`), not duplicated as helper methods across multiple ViewComponents.

## Services must model domain behavior
Service objects in `app/services/` must encapsulate meaningful domain operations, not just wrap CRUD. If a service only calls `.save` or `.update` on a model, it belongs in the model or controller. We follow DDD — services coordinate behavior across aggregates, not map data.

# Testing Requirements

- Write tests for all new features
- Use RSpec for model and service specs
- Use RSpec system tests for integration testing
- Maintain test coverage above 80%
- Run tests before committing: `bundle exec rspec @` for targeted tests. Or `bundle exec parallel_rspec` for the entire suite with parallelization for speed.
- For manual testing via Playwright MCP, see `/manual-testing` skill.

## Development Scripts

- `bin/dev` — starts tailwind + worker only (per-worktree processes). This should be your default.
- `bin/dev-full` — starts everything including web server (standalone, no puma-dev). Do not use this unless specifically asked.
- Assume the app is already running (puma-dev + `bin/dev`) unless you encounter connection errors. Do not start `bin/dev` yourself.
