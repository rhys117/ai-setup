---
name: execute-plan
description: Executes development plans from .llms/ directory phase by phase, updating progress, managing git commits, and handling validation cycles. Use to work through existing development plans.
allowed-tools: Read, Write, Edit, Bash, Grep, Glob, Task, TodoWrite, WebFetch, WebSearch
---

# Execute Development Plan

This skill executes structured development plans created by the `create-plan` skill, managing phase progression, progress tracking, and git integration.

## When to Use This Skill

- Executing an existing development plan from `.llms/`
- Continuing work on a plan in progress
- Moving to the next phase of development
- Handling validation failures and fix cycles
- Completing subtasks within a larger plan

## Execution Flow

### Step 1: Identify Plan to Execute

1. Check for active plans in `.llms/`:
   ```bash
   ls -la .llms/*.md
   ```

2. If multiple plans exist, ask user which to execute
3. Read the selected plan file
4. Identify current phase (first phase with "Status: In Progress" or "Status: Pending")

### Step 2: Verify Prerequisites

Before executing a phase:
1. Ensure on correct git branch (as specified in plan)
2. Check that previous phases are complete
3. Verify working directory is clean or commit WIP
4. Load any subtask plans if referenced

### Step 3: Execute Phase via Subagent

**CRITICAL**: Always use the Task tool to spawn the appropriate subagent for each phase. DO NOT execute phases directly - delegate to specialized agents.

#### Phase Execution via Subagents

**IMPORTANT**: Each phase should be executed by spawning the appropriate subagent using the Task tool. This ensures:
- Clear phase boundaries
- Consistent execution patterns
- Proper delegation of responsibilities
- Autonomous operation

**Subagent Mapping:**
| Phase | Subagent | Description |
|-------|----------|-------------|
| Scope Analysis | `execute-plan-scope-analysis` | Analyzes requirements and classifies complexity |
| Context Gathering | `execute-plan-context-gathering` | Explores codebase and documents patterns |
| Solution Design | `execute-plan-solution-design` | Creates technical architecture and checklist |
| Implementation | `execute-plan-implementation` | Executes checklist and writes code |
| Validation | `execute-plan-validation` | Tests changes and fixes issues |
| Documentation | `execute-plan-documentation` | Updates docs and creates guides |
| Knowledge Capture | `execute-plan-knowledge-capture` | Extracts learnings and patterns |

**Execution Pattern:**
```javascript
// Example: Executing the implementation phase
Task({
  subagent_type: "general-purpose",
  description: "Execute implementation phase",
  prompt: `
    You are executing the implementation phase of a development plan.

    Plan file: .llms/dev-plan-jwt-authentication.md
    Current phase: Implementation

    Instructions:
    1. Read the implementation agent from claude-setup/agents/execute-plan-implementation.md
    2. Follow the agent's instructions to execute this phase
    3. The agent will handle:
       - Reading the plan
       - Executing the implementation checklist
       - Writing code and tests
       - Updating the plan with progress
       - Marking the phase as complete

    IMPORTANT: The agent must follow strict phase boundaries and not proceed to validation or other phases.
  `
})
```

**Concrete Example for Each Phase:**
```javascript
// Scope Analysis
Task({
  subagent_type: "general-purpose",
  description: "Analyze scope",
  prompt: "Execute scope analysis phase using claude-setup/agents/execute-plan-scope-analysis.md for plan: .llms/dev-plan-[task].md"
})

// Context Gathering
Task({
  subagent_type: "general-purpose",
  description: "Gather context",
  prompt: "Execute context gathering phase using claude-setup/agents/execute-plan-context-gathering.md for plan: .llms/dev-plan-[task].md"
})

// And so on for other phases...
```

#### Scope Analysis Execution (via execute-plan-scope-analysis agent)

**Agent Responsibilities:**
- Analyze task requirements in detail
- Classify actual complexity
- Identify all affected components
- Decompose into subtasks if needed

**Expected Plan Update:**
```markdown
### Findings
**Complexity**: medium (was: large)
**Files Affected**: 7
**Components**:
- Authentication service
- User controller
- Middleware layer
- Database models
**Risks**:
- Breaking API compatibility
- Session management conflicts
**Decomposition Needed**: No
```

**Commit**: `git commit -m "chore: scope analysis for [task]"`

#### Context Gathering Execution

**Objectives:**
- Explore relevant codebase areas
- Find existing patterns to follow
- Identify reusable components
- Document dependencies

**Actions:**
1. Search for similar implementations
2. Read relevant source files
3. Identify coding patterns
4. List external dependencies

**Update Plan:**
```markdown
### Findings
**Relevant Files**:
- `src/auth/auth.service.ts` - Current auth implementation
- `src/users/user.model.ts` - User data structure
- `src/middleware/auth.middleware.ts` - Auth middleware pattern

**Patterns Found**:
- Service-based architecture for business logic
- Middleware for request validation
- JWT stored in HTTP-only cookies

**Dependencies**:
- jsonwebtoken library
- bcrypt for password hashing
- express-session for session management
```

**Commit**: `git commit -m "docs: context gathering for [task]"`

#### Solution Design Execution

**Objectives:**
- Create technical architecture
- Design component interfaces
- Plan implementation approach
- Create detailed checklist

**Actions:**
1. Design system architecture
2. Define interfaces and data structures
3. Create implementation checklist
4. Document design decisions

**Update Plan:**
```markdown
### Design Approach
JWT-based authentication with refresh tokens:
- Access tokens: 15 min expiry
- Refresh tokens: 7 day expiry
- Token rotation on refresh
- Blacklist for logout

### Implementation Checklist
- [ ] Create JWT service with sign/verify methods
- [ ] Add refresh token model to database
- [ ] Implement auth middleware for protected routes
- [ ] Create login endpoint with token generation
- [ ] Create refresh endpoint with rotation
- [ ] Add logout with token blacklisting
- [ ] Update user model with auth fields
- [ ] Add rate limiting to auth endpoints

### Design Artifacts
```typescript
interface JWTPayload {
  userId: string;
  email: string;
  roles: string[];
}

interface AuthTokens {
  accessToken: string;
  refreshToken: string;
}
```
```

**Commit**: `git commit -m "docs: solution design for [task]"`

#### Implementation Execution

**Objectives:**
- Execute implementation checklist
- Write actual code
- Track all changes made
- Maintain clean commits

**Actions:**
1. Work through checklist items sequentially
2. Check off completed tasks
3. Track modified files
4. Commit logical units of work

**Update Process:**
- After each checklist item:
  ```markdown
  - [x] Create JWT service with sign/verify methods
  ```
- Track changes:
  ```markdown
  ### Changes Made
  - `src/services/jwt.service.ts`: Created JWT service
  - `src/models/refresh-token.model.ts`: Added refresh token model
  ```

**Commits**:
- `git commit -m "feat: add JWT service"`
- `git commit -m "feat: add refresh token model"`
- `git commit -m "feat: implement auth middleware"`

#### Validation Execution

**Objectives:**
- Test all changes
- Verify requirements met
- Identify and fix issues
- Document test results

**Actions:**
1. Run existing tests
2. Write new tests if needed
3. Perform manual testing
4. Fix any issues found

**Update Plan:**
```markdown
### Test Results
- [x] Unit tests pass (37/37)
- [x] Integration tests pass (12/12)
- [x] Manual testing complete
- [ ] Edge cases verified

### Issues Found
1. Token refresh fails with expired refresh token
   - Fixed: Added proper error handling
   - Commit: abc123
2. Rate limiting not applied to refresh endpoint
   - Fixed: Added rate limiter middleware
   - Commit: def456

### Fix Cycles
None required - all issues resolved in phase
```

**Commit**: `git commit -m "test: validate [task] implementation"`

#### Documentation Execution

**Objectives:**
- Update README if needed
- Add code comments
- Create user documentation
- Document API changes

**Actions:**
1. Update relevant documentation
2. Add JSDoc comments to new functions
3. Create usage examples
4. Update API documentation

**Update Plan:**
```markdown
### Created Documents
- Updated `README.md` with auth setup instructions
- Created `docs/authentication.md` with detailed guide
- Added API documentation for auth endpoints
- Updated `.env.example` with new variables
```

**Commit**: `git commit -m "docs: add documentation for [task]"`

#### Knowledge Capture Execution

**Objectives:**
- Extract learnings
- Document patterns discovered
- Note improvement opportunities
- Create knowledge artifacts

**Actions:**
1. Reflect on implementation
2. Document learnings
3. Identify reusable patterns
4. Note future improvements

**Update Plan:**
```markdown
### Learnings
- Refresh token rotation prevents token replay attacks
- HTTP-only cookies more secure than localStorage for tokens
- Rate limiting critical for auth endpoints

### Patterns Identified
- Middleware composition for auth + rate limiting
- Service layer abstraction for auth logic
- Token blacklist using Redis for performance

### Recommendations
- Consider implementing 2FA in future
- Add device tracking for security
- Implement session management UI
```

**Commit**: `git commit -m "docs: knowledge capture for [task]"`

### Step 4: Phase Completion

After completing a phase:

1. **Update Phase Status**:
   ```markdown
   ## Phase N: [Name]

   **Status**: Completed ✓
   ```

2. **Update Next Phase**:
   ```markdown
   ## Phase N+1: [Name]

   **Status**: In Progress
   ```

3. **Update Progress Log**:
   ```markdown
   ## Progress Log

   - [timestamp] Plan created
   - [timestamp] Phase 1 completed
   - [timestamp] Phase 2 started
   ```

4. **Commit Phase Completion**:
   ```bash
   git add .llms/dev-plan-*.md
   git commit -m "chore: complete [phase] phase of [task]"
   ```

### Step 5: Handle Special Cases

#### Validation Failures and Fix Cycles

When the validation agent finds test failures, it will choose one of two approaches:

**Option A: Inline Fixes** (for minor issues):
- Validation agent fixes issues within the validation phase
- Quick fixes (<15 min, single file changes)
- Re-runs tests immediately
- Continues to next phase when passing

**Option B: Fix Subplan** (for major/critical issues):
- Creates an independent fix cycle subplan
- Requires structured workflow to fix properly
- Follows the iterative loop below

### Fix Cycle Workflow

```
┌─────────────────────────────────────┐
│  Validation Phase - Tests Fail      │
│  - Document all issues              │
│  - Classify severity                │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│  Create Fix Subplan                 │
│  1. Create fix-cycle.md file        │
│  2. List all critical/major issues  │
│  3. Link to parent plan             │
│  4. Classify fix workflow size      │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│  Execute Fix Subplan                │
│  - Scope: Analyze issues            │
│  - Implementation: Fix all issues   │
│  - Validation: Verify fixes work    │
└──────────────┬──────────────────────┘
               │
               ↓
┌─────────────────────────────────────┐
│  Return to Parent Validation        │
│  - Re-run full parent test suite   │
│  - Update parent plan with results  │
└──────────────┬──────────────────────┘
               │
         ┌─────┴──────┐
         │            │
      PASS          FAIL
         │            │
         ↓            ↓
    Continue      Create
    to Doc      Cycle N+1
```

### Creating a Fix Subplan

1. **Validation agent identifies issues**:
   ```markdown
   ## Phase 5: Validation
   **Status**: Awaiting Fix Cycle Completion

   ### Issues Found
   **Critical**:
   1. Token rotation not working
   2. Race condition in concurrent requests

   **Major**:
   3. Performance degradation (>2s response)
   ```

2. **Create fix subplan file**:
   - Location: `.llms/subtasks/dev-plan-[parent-task]-fix-cycle-1.md`
   - Use template: `create-plan/templates/fix-cycle.md`
   - Workflow: Classify based on fix complexity (usually micro/small)

3. **Document in parent plan**:
   ```markdown
   ### Fix Cycles

   #### Cycle 1
   **Subplan**: [Fix Validation Issues - Cycle 1](subtasks/dev-plan-jwt-auth-fix-cycle-1.md)
   **Created**: 2024-01-10 15:30:00
   **Status**: Active
   **Workflow**: small
   **Issues to Fix**:
   1. Token rotation security vulnerability
   2. Race condition in concurrent requests
   3. Performance degradation

   **Progress**: Pending
   ```

### Executing a Fix Subplan

1. **Run execute-plan on the fix subplan**:
   ```bash
   # Fix subplan goes through abbreviated workflow:
   # - Scope Analysis (of the bugs)
   # - Implementation (fix the bugs)
   # - Validation (verify fixes work)
   ```

2. **Fix subplan validation must pass**:
   - All originally failing tests now pass
   - No new test failures introduced
   - All regression tests still pass

3. **Update parent plan when fix complete**:
   ```markdown
   #### Cycle 1
   **Status**: Completed ✓
   **Completed**: 2024-01-10 17:45:00

   **Result**: All issues resolved
   - ✓ Token rotation implemented
   - ✓ Race condition fixed
   - ✓ Performance optimized (150ms avg)
   ```

### Re-running Parent Validation

After fix subplan completes:

1. **Execute parent validation agent again**:
   - Re-run complete test suite
   - Verify all originally failing tests now pass
   - Check for any new issues

2. **If validation passes**:
   ```markdown
   ### Re-validation Results
   **After Fix Cycle 1**:
   - Unit Tests: ✓ 59/59 passing (12 new tests added in fix)
   - Integration Tests: ✓ 23/23 passing
   - System Tests: ✓ 8/8 passing

   **Status**: ✓ PASS (after 1 fix cycle)
   **Recommendation**: Ready to proceed to documentation
   ```
   - Mark validation phase complete
   - Continue to next phase

3. **If validation still fails**:
   - Create Fix Cycle 2
   - Repeat the process
   - Continue until all tests pass

### Important Notes

- **Never skip validation**: All tests must pass before proceeding
- **Fix cycles are normal**: Complex features often need 1-2 fix cycles
- **Track everything**: Document all issues and fixes clearly
- **Independent branches**: Fix cycles can use separate git branches
- **Iterative improvement**: Each cycle should reduce remaining issues

#### Subtask Execution

For plans with subtasks:

1. Check subtask dependencies
2. Execute subtasks in order (or parallel if independent)
3. Update parent plan when subtask completes
4. Merge subtask branches if separate

#### Workflow Transitions

When all phases complete:

1. **Update Plan Status**:
   ```markdown
   ## Overview

   **Status**: Completed ✓
   ```

2. **Final Commit**:
   ```bash
   git commit -m "feat: complete [task] implementation"
   ```

3. **Suggest Next Steps**:
   - Create PR (but don't push/merge)
   - Run final test suite
   - Review changes
   - Update project documentation

## Git Integration Rules

**CRITICAL - Never violate these rules:**

1. **Branch Management**:
   - Always work on feature branch specified in plan
   - NEVER commit directly to main/master
   - NEVER merge without user approval
   - NEVER push without explicit permission

2. **Commit Strategy**:
   - Commit after each phase completion
   - Use conventional commits (feat:, fix:, docs:, chore:, test:)
   - Keep commits atomic and logical
   - Include detail in commit messages

3. **Safety Checks**:
   ```bash
   # Before any commits
   git status
   git diff

   # Verify branch
   git branch --show-current

   # Never do these without permission:
   # git push
   # git merge main
   # git checkout main
   ```

## Progress Tracking

### Checkbox Management

Update checkboxes in real-time:
- `- [ ]` → `- [x]` when task completes
- Add timestamp comments if useful
- Never remove completed items

### Status Sections

Maintain clear status indicators:
- `**Status**: Pending`
- `**Status**: In Progress`
- `**Status**: Completed ✓`
- `**Status**: Blocked ⚠️`

### Progress Log

Add entries for significant events:
```markdown
## Progress Log

- 2024-01-10 10:00 - Plan created
- 2024-01-10 10:30 - Scope analysis completed
- 2024-01-10 11:00 - Context gathering completed
- 2024-01-10 14:00 - Solution design completed
- 2024-01-10 16:00 - Implementation started
```

## Example Execution Session

```
User: "skill execute-plan"
Assistant:
1. Found plan: .llms/dev-plan-jwt-authentication.md
2. Current phase: Implementation (Phase 4 of 6)
3. On branch: feature/jwt-authentication
4. Executing implementation checklist...
   - ✓ Created JWT service
   - ✓ Added refresh token model
   - Working on auth middleware...
5. Phase complete, committed changes
6. Moving to Validation phase
7. Would you like to continue with validation?
```

## Integration with create-plan

This skill is designed to work with plans created by `create-plan`:
- Reads standard markdown structure
- Updates using consistent format
- Maintains phase progression
- Preserves plan metadata

## Error Handling

1. **Missing Plan**: Suggest running `create-plan` first
2. **Dirty Working Directory**: Offer to commit or stash changes
3. **Wrong Branch**: Offer to switch to correct branch
4. **Test Failures**: Document in validation phase, create fix cycle
5. **Merge Conflicts**: Never auto-resolve, alert user

## Best Practices

1. **Complete Phases Fully**: Don't skip ahead
2. **Document Everything**: Update findings and notes
3. **Test Continuously**: Run tests after each significant change
4. **Commit Regularly**: Don't batch too many changes
5. **Communicate Status**: Keep progress log updated