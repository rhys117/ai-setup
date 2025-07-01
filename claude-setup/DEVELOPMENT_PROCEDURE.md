# Feature Development Procedure

## WHEN TO USE
```
Activate this procedure when:
- Implementing new features or significant changes
- Fixing bugs requiring multi-file changes
- Refactoring with broad impact
- Any task estimated >30min or touching >2 files

Skip for: typos, single-line fixes, documentation-only changes
```

## HOW TO INITIATE
```
1. Create plan file in .llms/: .dev-plan-[feature-slug]-[YYYYMMDD].yaml
   Examples: .llms/.dev-plan-user-auth-20240115.yaml
            .llms/.dev-plan-fix-payment-bug-20240115.yaml
2. If resuming: find latest .llms/.dev-plan-*-*.yaml for the feature
3. Follow phases based on task size
4. For large/epic features: create subtask directory structure (see below)
```

## HOW TO USE

- ALWAYS follow the plan in the steps ordered (unless going back to a previous one).
- ALWAYS update the plan file after each phase.
- ALWAYS update a checklist item AS SOON AS you have completed an item in the plan.

## PLAN FILE STRUCTURE
```yaml
# .dev-plan-[feature-slug]-[YYYYMMDD].yaml
task: "Feature/fix description"
slug: "feature-slug"
size: micro|small|medium|large|epic
phase: current_phase_name
status: active|paused|completed
created: timestamp
updated: timestamp
sub_tasks: []
progress:
  scope_analysis: {complete: bool, findings: {}}
  context_gathering: {complete: bool, findings: {}}
  solution_design: {complete: bool, artifacts: {}}
  implementation: {complete: bool, changes: []}
  validation: {complete: bool, results: {}}
  documentation: {complete: bool, files: []}
  knowledge_capture: {complete: bool, learnings: {}}
```

## SUBTASK DIRECTORY STRUCTURE (Large/Epic Features)
```
.llms/
├── .dev-plan-[main-feature]-[YYYYMMDD].yaml          # Main plan file
├── [main-feature]/                                    # Feature context folder
│   ├── subtasks/
│   │   ├── .dev-plan-[subtask1]-[YYYYMMDD].yaml     # Individual subtask plans
│   │   ├── .dev-plan-[subtask2]-[YYYYMMDD].yaml
│   │   └── .dev-plan-[subtaskN]-[YYYYMMDD].yaml
│   ├── context/
│   │   ├── requirements.md                           # Detailed requirements
│   │   ├── architecture.md                           # System design
│   │   └── integration-points.md                     # External dependencies
│   └── artifacts/
│       ├── wireframes/                               # UI mockups
│       ├── schemas/                                  # DB schemas
│       └── api-specs/                                # API documentation

Example:
.llms/
├── .dev-plan-user-management-20240115.yaml
├── user-management/
│   ├── subtasks/
│   │   ├── .dev-plan-user-auth-20240115.yaml
│   │   ├── .dev-plan-user-profiles-20240116.yaml
│   │   └── .dev-plan-user-permissions-20240117.yaml
│   └── context/
│       ├── requirements.md
│       └── auth-flow.md
```

### SUBTASK BENEFITS
- **Incremental Context**: Each subtask captures complete context for focused development
- **Parallel Development**: Multiple developers can work on different subtasks
- **Progress Tracking**: Clear visibility into feature completion status
- **Knowledge Isolation**: Contained learnings and gotchas per subtask
- **Resumption Support**: Easy to pause/resume individual components

## 1. SCOPE ANALYSIS
```
- Parse requirement/issue → plan.progress.scope_analysis.findings
- Classify size: [micro|small|medium|large|epic]
- Decompose if >medium → plan.sub_tasks[]
- Query memory for similar work
```

## 2. CONTEXT GATHERING
```
- Search codebase → plan.progress.context_gathering.findings:
  - Related components (pattern search)
  - Existing patterns (read relevant dirs)
  - Test patterns (identify test structure)
- Identify reusable components
```

## 3. SOLUTION DESIGN
```
- Architecture sketch (if >small) → plan.progress.solution_design.artifacts
- List affected files:line_numbers → plan.progress.solution_design.checklist
- Define integration points
- Specify test strategy

Create checklist in plan.progress.solution_design.checklist:
  - [ ] Architecture sketch completed
  - [ ] Affected files identified with line numbers
  - [ ] Integration points defined
  - [ ] Test strategy specified
```

## 4. ITERATIVE IMPLEMENTATION
```
For each change → plan.progress.implementation.changes[]:
  a. Write failing test
  b. Implement minimal solution
  c. Run test command
  d. Manual test if UI/UX
  e. Refactor if needed
  f. Record progress

Create checklist in plan.progress.implementation.changes[].checklist:
  - [ ] Failing test written
  - [ ] Minimal solution implemented
  - [ ] Test command executed successfully
  - [ ] Manual testing completed (if UI/UX)
  - [ ] Refactoring completed (if needed)
  - [ ] Progress recorded in plan
```

## 5. VALIDATION
```
- Full test suite → plan.progress.validation.results
- Manual testing checklist
- Performance check if data-intensive
- Security review if auth/data-related
```

## 6. DOCUMENTATION (if >=large)
```
- Feature overview → plan.progress.documentation.files[]
- API changes
- Configuration updates
```

## 7. KNOWLEDGE CAPTURE
```
- Update memory → plan.progress.knowledge_capture.learnings:
  - New patterns discovered
  - Edge cases/gotchas
  - Reusable component locations
```

If you're using a dev-memory system. ALWAYS ensure to capture the learnings as per its requirements.

## SIZE→WORKFLOW MAPPING
```
micro:   [4]
small:   [2,3,4,5,7]
medium:  [1,2,3,4,5,7]
large:   [1,2,3,4,5,6,7]
epic:    [1(decompose)→spawn sub-plans]
```

## RESUMPTION PROTOCOL
```
1. Glob .llms/.dev-plan-*-*.yaml (and subtask directories)
2. Match feature-slug or find most recent
3. Check plan.phase and plan.progress
4. For large features: check subtask completion status
5. Continue from last incomplete step
6. Update plan.updated after each phase
```

## PLAN FILE LOCATION REQUIREMENTS
```
ALL plan files MUST be created in the .llms/ folder:
- Main plans: .llms/.dev-plan-[feature-slug]-[YYYYMMDD].yaml
- Subtask plans: .llms/[main-feature]/subtasks/.dev-plan-[subtask]-[YYYYMMDD].yaml
- Context files: .llms/[main-feature]/context/
- Artifacts: .llms/[main-feature]/artifacts/

This ensures:
- Centralized development tracking
- Integration with working memory system
- Consistent tooling and automation
- Clear separation from production code
```
