---
name: database-conventions
description: Database migration conventions. Use when creating or editing database migrations, adding columns, creating tables, or modifying the schema.
---

# Database Conventions

## Before writing a migration: confirm persistence is necessary

A new column is a one-way door — easy to add, expensive to remove once data lives in prod. Before reaching for a migration, walk through the lifecycle of the data and pick the lightest fit:

1. **Ephemeral (per-request)** — just flows through params. Example: poster customisation that's applied at render time and forgotten.
2. **Session-scoped** — survives the request but not beyond. `session[...]` or a signed cookie.
3. **User preference** — persist, but consider a lightweight key-value column (jsonb `preferences`) rather than a dedicated column per setting.
4. **Domain state** — genuine entity data that other records, queries, or business rules depend on. This is where migrations belong.

If the data is 1 or 2, **do not persist**. If you are unsure, ask the user before writing the migration — "does this need to survive across sessions, or can it live in the URL/session?" is a cheap question that prevents expensive rollbacks.

## Column design

- **Avoid booleans for anything with a lifecycle.** Booleans can't grow. Prefer a status enum (`pending`, `active`, `archived`) or a timestamp (`activated_at`, `disabled_at`) — both carry more information and leave room for future states. Only use a boolean for a genuine two-state flag with no foreseeable third state.
- **Avoid columns that repeat the table name.** `posts.post_title` or `shared_photo_configurations.poster_prompt_line` are noise — the table already scopes the meaning. Name fields by their domain role (`title`, `prompt_line`), not by prefixing the table. Same rule applies to associations: `user_id` not `owner_user_id` unless the prefix carries real semantic weight.
- **Array and jsonb columns are flexible but lose queryability and indexability.** Pick the type that matches how the data will be queried, not the one that's easiest to shape today. An array of strings is fine for display-only lists; reach for a join table the moment you need to query, count, or filter by individual entries.
- **Choose the right integer width, string length, and decimal precision.** PostgreSQL doesn't require string limits, but model-level length validations still matter for UI and data hygiene.

## Migration mechanics

- Always create migrations via the Rails generator (`bin/rails generate migration`). You may edit the file after generation.
- **NEVER modify an already-migrated migration** unless you are rolling back the immediate migration YOU just created in this session.
- Never modify `schema.rb` directly — regenerate it via migrations.
- Always add indexes for foreign keys (`add_reference ..., index: true` or an explicit `add_index`).
- Prefer `change` over `up`/`down`. When a migration is not auto-reversible (e.g. data transforms, `remove_column` with a default), write explicit `up`/`down`.
- **Split schema changes from data backfills.** Adding a NOT NULL column with a backfill in a single migration is a production footgun on large tables. Use two migrations: one to add the column nullable with a default, one to backfill, and optionally a third to enforce NOT NULL.
- Defaults on new NOT NULL columns must be set at the DB level (`default:`), not at the app level — otherwise existing rows fail on the constraint.

## Naming

- Tables: plural snake_case (`shared_photo_configurations`).
- Columns: snake_case, no table-name prefix, no Hungarian-style type suffixes (`is_`, `has_`).
- Timestamps: past-tense + `_at` (`published_at`, `activated_at`).
- Foreign keys: `{association}_id`.
