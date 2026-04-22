---
name: address-review-comments
description: Read unresolved review conversations from the current branch's pull request, make code changes, run tests, manually verify, push, and reply to each thread. Use when the user asks to address PR feedback, fix review comments, or resolve review threads.
---

# Address Review Comments

End-to-end workflow: fetch unresolved PR review threads, address them with code changes, verify, push, and reply.

## Instructions

### 1. Identify the PR and repo

Run these in parallel:

```bash
gh pr view --json number,url,headRefName --jq '{number, url, branch: .headRefName}'
gh repo view --json owner,name --jq '.owner.login + " " + .name'
```

If no PR exists for the current branch, inform the user and stop.

### 2. Fetch unresolved review threads

Use the GitHub GraphQL API. Include `databaseId` on comments — this is required for replying later.

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          isOutdated
          id
          path
          line
          startLine
          diffSide
          comments(first: 50) {
            nodes {
              author { login }
              body
              createdAt
              url
              databaseId
            }
          }
        }
      }
    }
  }
}' -f owner=OWNER -f repo=REPO -F number=NUMBER
```

### 3. Filter to actionable threads

Keep only threads where `isResolved` is `false`. Mention `isOutdated` threads to the user but deprioritize them.

### 4. Present a summary

Before making changes, present a numbered list:

```
## Unresolved Review Threads (N total)

1. **path/to/file.rb:42** - @reviewer: "Summary of comment..."
2. **path/to/other.rb:15** - @reviewer: "Summary of comment..."
```

### 5. Address each thread

For each unresolved thread:

1. **Read the file** at the referenced path and line to understand the current code
2. **Understand the full conversation** — read all comments in the thread, not just the first
3. **Determine the appropriate action**:
   - **Code change needed**: Make the change, then move to the next thread
   - **Clarification/discussion needed**: Flag it to the user with your assessment and a suggested response
   - **Disagreement**: Present both sides and let the user decide
4. **Group related threads** that touch the same file/area and address them together
5. **Commit each fix individually** using conventional commits, referencing the review comment context

### 6. Run tests

Run the relevant test files for changed code. If tests fail, fix before proceeding.

### 7. Manual verification

Use a manual-verifier subagent with Playwright MCP to visually verify any UI changes in the browser. This catches rendering issues that tests alone miss.

### 8. Push changes

```bash
git push
```

Note the commit SHAs for referencing in replies.

### 9. Reply to PR comments

Before replying, check for and submit any pending reviews — these block the reply API:

```bash
# Check for pending reviews
gh api repos/OWNER/REPO/pulls/NUMBER/reviews --jq '.[] | select(.state == "PENDING") | {id}'

# Submit any pending review (if found)
gh api repos/OWNER/REPO/pulls/NUMBER/reviews/REVIEW_ID/events -X POST -f event=COMMENT -f body=""
```

Then reply to each thread using the **first comment's `databaseId`** from step 2:

```bash
gh api repos/OWNER/REPO/pulls/NUMBER/comments/DATABASE_ID/replies -f body="REPLY"
```

Reply guidelines:
- **For code changes**: Reference the commit SHA and briefly describe what changed
- **For discussion items**: Explain the trade-offs, suggest a path forward, let the reviewer decide
- Do NOT resolve threads — let the reviewer verify and resolve them

### 10. Final summary

```
## Results

### Addressed (N)
- thread summary + what was done + commit ref

### Needs Discussion (N)
- thread summary + why it needs user input

### Skipped/Outdated (N)
- thread summary + reason
```

## Notes

- Always read surrounding code context before making changes — review comments often reference broader patterns
- If a reviewer's suggestion conflicts with project conventions (CLAUDE.md, UI components, etc.), flag the conflict rather than blindly applying
- Run tests before pushing, not after
- The GraphQL API is for fetching threads; the REST API is for replying. They use different ID formats — use `databaseId` for REST replies
