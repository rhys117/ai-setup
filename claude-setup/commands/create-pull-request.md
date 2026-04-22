Create a Pull Request for the current branch.

Follow these steps precisely:

1. Run in parallel:
   - `git status` to check for uncommitted changes
   - `git log main..HEAD --oneline` to see all commits on this branch
   - `git diff main...HEAD --stat` to see a summary of changed files
   - `git diff main...HEAD` to see the full diff

2. If there are uncommitted changes, ask whether to commit them first.

3. Check if the branch is pushed to remote. If not, push with `git push -u origin HEAD`.

4. Take screenshots of any UI changes using Playwright MCP (use the auto-login token). Save screenshots to `tmp/screenshots/`.

5. Upload any screenshots using `gh image`:
   ```
   gh image tmp/screenshots/*.png
   ```
   This returns markdown image references like `![image](https://github.com/user-attachments/assets/...)`.

6. Create the PR using `gh pr create`. Use this exact body format:

```
gh pr create --title "<short title under 70 chars>" --body "$(cat <<'EOF'
## Description

<2-3 sentence summary of what changed and why>

<If there are meaningful tradeoffs, add a short paragraph explaining them. Omit this section if there are none.>

## Testing

<1-3 bullet points describing how the changes were tested>

<paste the markdown image references from gh image here, one per line>
EOF
)"
```

Rules:
- Keep the description concise — what and why, not a changelog
- Only include tradeoffs if there's a genuine design decision worth noting
- Testing section should describe what was verified, not repeat commit messages
- Always include screenshots for UI changes
- If no UI changes, omit the screenshot section
