---
name: code-reviewer
description: Review code changes using different expert personalities. Use when the user asks to review code, review changes, review commits, or analyze diffs. Defaults to comparing current branch against master.
---

# Code Reviewer Skill

Expert code review with personality-driven perspectives from software engineering thought leaders.

## Overview

This skill provides code reviews from the perspective of different software engineering experts. Personalities are defined by markdown files in the `resources/` directory and can be extended by adding new personality files.

## Instructions

When the user requests a code review:

1. **Discover available personalities**:
  - List all `.md` files in the `resources/` directory
  - Extract personality names from filenames (e.g., `martin-fowler.md` → "martin-fowler")
  - Keep this list to match against user requests

2. **Determine the scope of review**:
  - If user specifies "latest commit" or "last commit": Review `git diff HEAD~1`
  - If user specifies "uncommitted changes" or "current changes": Review `git diff`
  - If user specifies a specific branch comparison: Use that comparison
  - **Default**: Compare current branch against master using `git diff master...HEAD`

3. **Determine the reviewer personality**:
  - Check if user specified a personality name (match against discovered personalities)
  - If user asks to compare multiple perspectives: Use all requested personalities
  - If user asks "what reviewers are available": List all discovered personalities with brief descriptions
  - **Default**: Use the first available personality alphabetically

4. **Load the personality resource**:
  - Read the appropriate `.md` file from `resources/` directory
  - Use the guidelines in that resource to shape your review
  - Follow the personality's specific focus areas and communication style

5. **Gather the changes**:
  - Run the appropriate git diff command
  - If no changes found, inform the user

6. **Perform the review**:
  - Analyze the changes through the lens of the chosen personality
  - Focus on the specific concerns and values of that expert
  - Provide actionable feedback with specific file/line references
  - Include both positive observations and areas for improvement
  - Stay in character with the personality's communication style

7. **Format the output**:
   ```
   # Code Review: [Personality Name]

   **Scope**: [Description of what was reviewed]

   ## Summary
   [High-level overview of the changes]

   ## Key Observations
   [Main findings organized by theme]

   ## Detailed Feedback
   [Specific comments with file:line references]

   ## Recommendations
   [Actionable next steps]
   ```

## Examples

**User**: "Review my code"
**Action**: Compare current branch against master using default personality

**User**: "Review the latest commit using sandi metz"
**Action**: Review `git diff HEAD~1` using Sandi Metz personality (from `resources/sandi-metz.md`)

**User**: "What reviewers are available?"
**Action**: List all personalities found in `resources/` directory

**User**: "Review uncommitted changes from the gof perspective"
**Action**: Review `git diff` using GoF personality (from `resources/gof.md`)

**User**: "Compare dhh and fowler reviews of my branch"
**Action**: Review current branch against master using both DHH and Martin Fowler personalities

## Notes

- Always reference specific files and line numbers when providing feedback
- Criticism is ok
- IF there are good practices, recognise them as well
- Tailor the depth of review to the size of changes
- If changes are very large (>500 lines), offer to focus on specific areas
- New personalities can be added by simply adding new `.md` files to `resources/`
