Create a git commit message based on the staged changes in the repository.

Write your commit message to .llms/commit_message.txt

## Conventional Commits Standard

### Structure
```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Core Commit Types
- **feat**: A new feature (MINOR version bump)
- **fix**: A bug fix (PATCH version bump)
- **docs**: Documentation only changes
- **style**: Code style changes (formatting, missing semicolons, etc.)
- **refactor**: Code change that neither fixes a bug nor adds a feature
- **perf**: Performance improvement
- **test**: Adding or updating tests
- **build**: Changes to build system or dependencies
- **ci**: Changes to CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files

### Breaking Changes
Indicate breaking changes (MAJOR version bump) by:
1. Appending '!' after type/scope: 'feat!: description'
2. Including footer: 'BREAKING CHANGE: description'

### Rules
- Type prefix is required (feat, fix, etc.)
- Scope is optional and in parentheses: 'feat(api):'
- Description must be a short summary of code changes
- Body and footers are optional but provide valuable context
- Use present tense: "add feature" not "added feature"

### Examples
```
feat(auth): add JWT token refresh mechanism
fix(api): resolve race condition in user creation
docs: update API documentation for v2 endpoints
feat!: redesign authentication flow
```

### Project-Specific Requirements
- DO NOT include AI co-author tags (no "Co-Authored-By: Claude")
- Commit changes often with clear, focused messages
- Ensure commits are on feature branches, never directly to main
