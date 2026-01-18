---
name: complex-task-workflow
description: Orchestrates complex or architectural code changes through a structured workflow. Use when the user requests multi-file changes, new features, architectural refactoring, database schema changes, new API endpoints, or any task requiring significant planning. Triggers context gathering, planning, code review, TDD execution, and manual testing.
---

# Complex Task Workflow

This skill orchestrates large or architectural code changes through a structured, quality-focused workflow.

## When to Use This Skill

Activate this workflow when the user's request involves:
- New feature implementations
- Architectural changes or new patterns
- Database migrations or schema changes
- New controllers, models, or services
- Significant refactoring
- API endpoint additions
- Any task where "getting it wrong" would be costly

Do NOT use for:
- Simple bug fixes (single file, obvious solution)
- Documentation updates
- Minor styling tweaks
- Direct questions or research tasks

---

## Phase 1: Context Gathering

Before planning, thoroughly understand the landscape.

### Actions
1. Use the `Explore` agent to investigate:
   - Existing patterns relevant to the task
   - Similar implementations in the codebase
   - Affected files and dependencies
   - Current test coverage in the area

2. Identify and note:
   - Conventions this codebase follows
   - Potential integration points
   - Edge cases to consider
   - Any technical debt that might complicate the work

3. If the request is ambiguous, ask clarifying questions NOW before planning.

---

## Phase 2: Planning

Create a detailed, reviewable plan.

### Actions
1. Create a plan file at `docs/claude-plans/{descriptive-task-name}.md`

2. The plan MUST include:

```markdown
# Plan: {Task Name}

## Objective
{One sentence describing what we're building and why}

## Context Summary
{Key findings from Phase 1 - patterns found, conventions to follow}

## Implementation Steps

### Step 1: {Description}
- **Files**: {files to create/modify}
- **Test**: {what test will verify this step}
- **Acceptance**: {how we know this step is done}

### Step 2: {Description}
...

## Risks & Mitigations
- {Risk}: {How we'll handle it}

## Out of Scope
- {Things we're explicitly NOT doing}
```

3. Keep steps small and independently testable.

---

## Phase 3: Plan Review

Get architectural feedback before executing.

### Actions
1. Invoke the code reviewer with the Fowler personality:
   ```
   /code-reviewer fowler docs/claude-plans/{task-name}.md
   ```

2. The reviewer will assess:
   - SOLID principle adherence
   - Potential code smells in the design
   - Over-engineering risks
   - Missing considerations

3. Document the review feedback in the plan file under a new section:
   ```markdown
   ## Review Feedback
   - {Feedback point 1}
   - {Feedback point 2}

   ## Plan Adjustments
   - {How we're addressing the feedback}
   ```

4. If feedback raises questions without clear answers, **ask the user** for guidance.

5. **Present the final plan to the user for approval before proceeding.**

---

## Phase 4: Execution (Red-Green-Refactor)

Implement using strict TDD discipline.

### For Each Step in the Plan:

#### RED Phase
1. Write the failing test FIRST
2. Run the test to confirm it fails
3. The test should fail for the RIGHT reason (not syntax errors)

#### GREEN Phase
1. Write the MINIMAL code to make the test pass
2. Do not over-engineer - just make it green
3. Run the test to confirm it passes

#### REFACTOR Phase
1. Now improve the code while keeping tests green
2. Apply patterns identified in planning
3. Run tests after each refactor to ensure nothing breaks

### Handling Failures
- If a test fails unexpectedly, attempt to fix it
- If the fix requires changing the original plan significantly, **stop and consult the user**
- Document any deviations from the plan

### Progress Tracking
Use the TodoWrite tool to track each step:
```
[ ] Step 1: Create migration for X
[→] Step 2: Add model with validations
[✓] Step 3: Write service object
```

---

## Phase 5: Manual Testing (Frontend Changes Only)

If any frontend code was touched, verify visually.

### Actions
1. Launch the manual-verifier agent with the affected pages/features to test
2. Fix any visual issues found before proceeding

---

## Phase 6: Summary

Provide a clear summary of what was accomplished.

### Output Format

```markdown
## Task Complete: {Task Name}

### Files Changed
- `path/to/file.rb` - {what changed}
- `path/to/file_spec.rb` - {tests added}

### Key Decisions Made
- {Decision 1}: {Rationale}
- {Decision 2}: {Rationale}

### Limitations & Known Issues
- {Any limitations discovered}
- {Edge cases not handled}

### Suggested Follow-ups
- {Future improvements}
- {Related refactoring opportunities}
```

---

## Checkpoints & User Interaction

| Phase | User Approval Required? |
|-------|------------------------|
| Context Gathering | No (unless clarification needed) |
| Planning | No |
| Plan Review | **YES - must get approval before execution** |
| Execution | No (unless plan needs changing) |
| Manual Testing | No |
| Summary | No |

---

## Example Invocation

User: "Add a feature to let guests upload dietary requirements"

Claude activates this workflow:
1. Explores existing Guest model, file upload patterns, form handling
2. Creates `docs/claude-plans/guest-dietary-upload.md`
3. Runs `/code-reviewer fowler` on the plan
4. Incorporates feedback, asks user about storage (ActiveStorage vs external?)
5. Presents plan for approval
6. Executes with TDD: migration → model → controller → view → tests
7. Manual tests the upload flow in browser
8. Summarizes changes and notes any file size limitations
