---
name: create-plan
description: Creates structured development plans with phases, subtasks, and progress tracking using markdown files in .llms/ directory. Use when starting new features or complex tasks that need planning.
allowed-tools: Read, Write, Edit, Bash, AskUserQuestion, TodoWrite
---

# Create Development Plan

This skill creates structured development plans inspired by the MCP plan server, adapted for markdown-based workflow management.

## When to Use This Skill

- Starting a new feature or significant code change
- Breaking down complex tasks into manageable phases
- Planning work that spans multiple files or components
- Organizing tasks that require design, implementation, and validation
- Creating trackable development workflows

## Workflow Classifications

### Workflow Sizes

| Workflow | Phases | Use Case |
|----------|--------|----------|
| **micro** | 1 phase | Single file, trivial changes |
| **small** | 3 phases | 2-3 files, straightforward changes |
| **medium** | 5 phases | Multiple files, moderate complexity |
| **large** | 6 phases | Many files, significant changes |
| **epic** | 7 phases | Major features requiring decomposition |

### Phase Definitions

1. **Scope Analysis** - Analyze requirements, classify complexity, identify components
2. **Context Gathering** - Explore codebase, find patterns, understand dependencies
3. **Solution Design** - Create architecture, design interfaces, plan approach
4. **Implementation** - Write code, make changes, execute checklist
5. **Validation** - Test changes, verify requirements, fix issues
6. **Documentation** - Update docs, add comments, create guides
7. **Knowledge Capture** - Extract learnings, document insights

## Plan Creation Process

### Step 1: Gather Information

Ask the user:
1. What is the task or feature to implement?
2. What is the expected scope? (if unclear, analyze to determine)
3. What is the priority level? (high/medium/low)
4. Are there specific constraints or requirements?

### Step 2: Analyze Complexity

Examine the task to determine:
- Number of files likely to be modified
- Whether new architecture is needed
- Testing requirements
- Documentation needs
- If task should be decomposed into subtasks

### Step 3: Create Plan Structure

Select the appropriate template from the `templates/` directory based on workflow size:

- `templates/micro.md` - Single file, trivial changes (1 phase)
- `templates/small.md` - 2-3 files, straightforward (3 phases)
- `templates/medium.md` - Multiple files, moderate complexity (5 phases)
- `templates/large.md` - Many files, significant changes (6 phases)
- `templates/epic.md` - Major features with subtasks (7 phases)
- `templates/subtask.md` - For epic workflow subtasks

Load the selected template and replace placeholders:
- `[Task Name]` - Main task description
- `[Description]` - Detailed task description
- `[ISO timestamp]` - Current ISO 8601 timestamp
- `[priority]` - User-specified or determined priority
- `[slug]` - URL-friendly task identifier

The templates provide consistent structure across all plan sizes while including workflow-specific phases and sections.

### Step 4: File Naming Convention

- Main plans: `.llms/dev-plan-[task-slug].md`
- Subtasks: `.llms/subtasks/dev-plan-[parent-slug]-[subtask-slug].md`
- Slug = lowercase, hyphen-separated version of task name

### Step 5: Handle Subtasks (for large/epic)

For complex tasks:
1. Identify logical components that can be worked on independently
2. Create subtask plans in `.llms/subtasks/` directory
3. Each subtask gets its own workflow classification
4. Link subtasks in main plan

### Step 6: Git Branch Setup

**CRITICAL Git Rules:**
- Create a feature branch: `feature/[task-slug]`
- **NEVER** work directly on main/master
- **NEVER** push without explicit permission
- **NEVER** merge without user approval
- Include branch name in plan for reference

## Phase-Specific Sections

### Scope Analysis Output
```markdown
### Findings
**Complexity**: [micro/small/medium/large/epic]
**Files Affected**: [estimated count]
**Components**: [list of components]
**Risks**: [potential challenges]
**Decomposition Needed**: [yes/no]
```

### Context Gathering Output
```markdown
### Findings
**Relevant Files**:
- file1.ts - [purpose]
- file2.ts - [purpose]

**Patterns Found**:
- Pattern 1 description
- Pattern 2 description

**Dependencies**:
- External library 1
- Internal module 2
```

### Solution Design Output
```markdown
### Design Approach
[Architecture description]

### Implementation Checklist
- [ ] Task 1: Create X component
- [ ] Task 2: Modify Y service
- [ ] Task 3: Update Z configuration

### Design Artifacts
```text
[ASCII diagrams, interface definitions, etc.]
```
```

### Implementation Output
```markdown
### Changes Made
- `file1.ts`: Added authentication middleware
- `file2.ts`: Updated user model
- `file3.ts`: Created JWT service

### Commits
- `abc123`: Add authentication middleware
- `def456`: Update user model with token fields
```

### Validation Output
```markdown
### Test Results
- [x] Unit tests pass
- [x] Integration tests pass
- [ ] Manual testing complete
- [ ] Edge cases verified

### Issues Found
1. Issue 1 description → Fixed in commit xyz789
2. Issue 2 description → Pending fix

### Fix Cycles
- Cycle 1: [issue] → [fix] → [result]
```

## Example Usage

```
User: "skill create-plan"
Assistant: What task would you like to create a development plan for?
User: "Add JWT authentication to the API"
Assistant:
1. Analyzes that this is a "large" workflow (security, multiple endpoints, testing critical)
2. Creates `.llms/dev-plan-jwt-authentication.md`
3. Creates subtasks:
   - User model updates
   - JWT token service
   - Authentication middleware
   - Protected route implementation
   - Token refresh logic
4. Sets up feature branch
5. Shows plan summary and next steps
```

## Integration with execute-plan

Plans created by this skill are designed for the `execute-plan` skill to:
- Read phase status and objectives
- Update checkboxes as tasks complete
- Add findings and results to each phase
- Track progress through the workflow
- Commit changes at phase boundaries

## Best Practices

1. **Clear Objectives**: Write specific, measurable objectives for each phase
2. **Decomposition**: Break epics into 3-7 subtasks maximum
3. **Progress Tracking**: Use checkboxes for all actionable items
4. **Documentation**: Add notes and findings as you discover them
5. **Incremental Commits**: Plan for commits at natural boundaries

## Error Handling

- Ensure `.llms/` directory exists before creating plans
- Check for existing plans with same name
- Validate workflow selection
- Handle file write errors gracefully
- Verify git repository exists before branch operations