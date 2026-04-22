---
description: Manual testing strategy using Playwright MCP. Use when performing browser-based testing, verifying UI changes, or checking features manually.
---

# Manual Testing via Playwright MCP

## STOP: delegate to a subagent before running Playwright

You MUST delegate browser testing to a subagent (`Agent` tool, typically `subagent_type: "manual-verifier"` or `general-purpose`). Do NOT run `mcp__playwright__*` tools yourself in the main conversation. This is non-negotiable, and applies even for "quick" one-off checks like a single screenshot or navigation.

**Why this rule exists:** Playwright tool results (page snapshots, console logs, screenshots, network traces) are large and pollute the main context fast. A subagent absorbs that cost and returns only the summary you actually need. Skipping the subagent has burned context in past sessions, so the rule is enforced regardless of how trivial the test feels.

**The only exception** is when the user explicitly says to run Playwright in the main conversation (e.g. "don't use a subagent", "do it inline"). User convenience phrasing like "just take a screenshot" does NOT count as an exception. Still delegate.

**How to delegate well:**
- Brief the subagent with the full context: URL(s), what to verify, what to capture, where to save screenshots, and what to report back.
- Ask for a concise structured report (e.g. "summarise in under 150 words; list any console errors; return the screenshot file paths").
- Do not ask the subagent to make decisions you should make yourself; it tests, you interpret.

If you find yourself about to call `mcp__playwright__browser_navigate` directly, stop and spawn an `Agent` instead.

## Auto-login Token (recommended)

Skip the login step by appending `?auto_login_token=<TOKEN>` to any URL.

Generate a token locally: `rake 'dev:auto_login_token[EVENT_ID]'`

Then append it: `http://<directory-name>.test/app/dashboard?auto_login_token=<TOKEN>`

## Manual Login Fallback

- Path: `/users/sign_in`
- Use any seeded user from `db/seeds.rb`

## App URL

The app uses puma-dev. Access it at `http://<directory-name>.test` (e.g. `http://let_me_know.test`). The directory name is the hostname — you may be in a worktree with a different directory name.
