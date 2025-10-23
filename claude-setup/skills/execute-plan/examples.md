# Execute Plan Examples

## Example 1: Executing a Small Workflow

### Initial State

Plan file: `.llms/dev-plan-add-search-filter.md`
```markdown
# Development Plan: Add Search Filter

## Overview
**Task**: Add search filter to user list
**Workflow**: small
**Status**: Active
**Branch**: feature/add-search-filter

## Phase 1: Scope Analysis
**Status**: Completed ✓

### Findings
**Complexity**: small
**Files Affected**: 3
- UserList.tsx
- useSearch.ts
- UserAPI.ts

## Phase 2: Implementation
**Status**: In Progress

### Objectives
- [ ] Add search input component
- [ ] Implement filter logic
- [ ] Connect to API

## Phase 3: Validation
**Status**: Pending
```

### Execution

```
User: skill execute-plan
Assistant: I found an active plan: dev-plan-add-search-filter.md
Currently in Phase 2: Implementation

Executing implementation objectives:
1. Adding search input component...
   - Created SearchInput.tsx
   - Added to UserList.tsx
   ✓ Complete

2. Implementing filter logic...
   - Created useSearch hook
   - Added debounce for performance
   ✓ Complete

3. Connecting to API...
   - Updated UserAPI.ts with search parameter
   - Integrated with UserList component
   ✓ Complete

Phase 2 completed. Committing changes...
Committed: "feat: add search filter to user list"

Moving to Phase 3: Validation. Shall I continue?
```

## Example 2: Handling Validation Failures

### When Validation Finds Issues

```markdown
## Phase 5: Validation
**Status**: In Progress

### Test Results
- [x] Unit tests pass (45/45)
- [ ] Integration tests pass (8/10 failing)
- [ ] Manual testing complete

### Issues Found
1. Search doesn't handle special characters
2. API returns 500 on empty search term

### Fix Cycles
#### Cycle 1
**Issues**: Special characters, empty search
**Status**: In Progress
```

### Execution Response

```
Validation phase revealed 2 issues. Creating fix cycle...

Fix Cycle 1:
1. Escaping special characters in search query
   - Updated useSearch hook with escapeRegex
   - Added input sanitization

2. Handling empty search term
   - Added early return for empty string
   - Updated API validation

Re-running tests...
✓ All tests now passing (10/10)

Validation phase completed successfully after 1 fix cycle.
```

## Example 3: Epic with Subtasks

### Parent Plan Structure

```markdown
# Development Plan: Implement User Authentication

## Overview
**Workflow**: epic
**Status**: Active

## Subtasks
1. [User Model Updates](subtasks/dev-plan-auth-user-model.md) - Status: Completed ✓
2. [JWT Service](subtasks/dev-plan-auth-jwt-service.md) - Status: In Progress
3. [Auth Middleware](subtasks/dev-plan-auth-middleware.md) - Status: Pending
4. [Login/Logout Endpoints](subtasks/dev-plan-auth-endpoints.md) - Status: Pending
```

### Executing Subtask

```
User: skill execute-plan
Assistant: Found multiple plans. The main plan "Implement User Authentication" has active subtasks.

Currently active: JWT Service (subtask 2 of 4)
Would you like to:
1. Continue with JWT Service subtask
2. View main plan progress
3. Switch to different subtask

User: 1
Assistant: Executing JWT Service subtask...
Current phase: Implementation

Working through checklist:
- [x] Create token generation method
- [x] Create token verification method
- [ ] Add refresh token support
...
```

## Example 4: Phase Progression with Git

### Complete Phase Workflow

```
Phase: Solution Design
Status: In Progress

Actions:
1. Read existing code patterns
2. Design new component architecture
3. Create implementation checklist
4. Document design decisions

Updating plan with design artifacts...
✓ Design approach documented
✓ Implementation checklist created (8 tasks)
✓ Interface definitions added

Committing phase completion:
git add .llms/dev-plan-feature.md
git commit -m "docs: complete solution design for feature"

Phase 3 completed. Moving to Phase 4: Implementation
The implementation checklist has 8 tasks. Ready to proceed?
```

## Example 5: Knowledge Capture Phase

### Executing Knowledge Capture

```markdown
## Phase 7: Knowledge Capture
**Status**: In Progress

### Objectives
- [ ] Extract learnings
- [ ] Document patterns
- [ ] Identify improvements
```

### Execution Output

```
Completing Knowledge Capture phase...

Analyzing implementation for learnings:
1. Repository pattern simplified testing
2. Dependency injection improved modularity
3. Event-driven updates reduced coupling

Documenting patterns:
- Service layer abstraction
- Error boundary implementation
- Optimistic UI updates

Identifying improvements:
- Consider caching for frequently accessed data
- Add request debouncing globally
- Implement retry logic for failed requests

✓ Knowledge capture complete
✓ Plan fully executed

Final status:
- 7 phases completed
- 3 subtasks completed
- 12 commits created
- 0 unresolved issues

The feature implementation is complete.
Ready to create a pull request? (Note: I won't push or merge)
```

## Example 6: Workflow Size Auto-Detection

### When Executing Without Active Phase

```
User: skill execute-plan
Assistant: Found plan: dev-plan-refactor-api.md
⚠️ No phase is marked as "In Progress"

Analyzing plan to determine next phase:
- Phase 1: Scope Analysis - Completed ✓
- Phase 2: Context Gathering - Completed ✓
- Phase 3: Solution Design - Pending

Resuming from Phase 3: Solution Design
Would you like me to proceed?
```

## Common Execution Patterns

### 1. Checkpoint Pattern
```
After each major change:
- Run relevant tests
- Commit if successful
- Update plan progress
- Continue to next task
```

### 2. Incremental Progress
```
For long checklists:
- Work on 2-3 items
- Commit progress
- Update plan
- Ask user to continue
```

### 3. Validation Loop
```
Run tests → Find issues → Fix → Re-test → Update plan
```

### 4. Subtask Coordination
```
Complete subtask → Update parent → Check dependencies → Start next subtask
```