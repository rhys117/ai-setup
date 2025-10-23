# Development Plan Execution Agents

These agents work with the `create-plan` and `execute-plan` skills to provide autonomous phase execution for development workflows.

## Phase Execution Agents

Each agent is responsible for a specific phase of development:

| Agent | Phase | Description |
|-------|-------|-------------|
| `execute-plan-scope-analysis.md` | Scope Analysis | Analyzes requirements and classifies task complexity |
| `execute-plan-context-gathering.md` | Context Gathering | Explores codebase and documents existing patterns |
| `execute-plan-solution-design.md` | Solution Design | Creates technical architecture and implementation checklist |
| `execute-plan-implementation.md` | Implementation | Executes the checklist and writes code |
| `execute-plan-validation.md` | Validation | Tests changes and handles fix cycles |
| `execute-plan-documentation.md` | Documentation | Creates and updates all documentation |
| `execute-plan-knowledge-capture.md` | Knowledge Capture | Extracts learnings and documents insights |

## How It Works

### 1. Plan Execution Flow

When the `execute-plan` skill runs, it:
1. Identifies the current phase from the plan
2. Spawns the appropriate agent using the Task tool
3. The agent executes autonomously within phase boundaries
4. Updates the plan and moves to the next phase

### 2. Agent Invocation

The execute-plan skill uses this pattern:
```javascript
Task({
  subagent_type: "general-purpose",
  description: "Execute [phase] phase",
  prompt: `Execute the [phase] phase of the development plan.
           Use the [agent-name] agent from claude-setup/agents/`
})
```

### 3. Phase Boundaries

Each agent respects strict boundaries:
- ✅ Only performs tasks for their specific phase
- ❌ Does not skip ahead to future phases
- ❌ Does not re-do completed phases
- ✅ Updates the plan with phase-specific outputs

## Agent Responsibilities

### execute-plan-scope-analysis
- Classify task size (micro/small/medium/large/epic)
- Decompose large tasks into subtasks
- Identify affected components
- Assess risks and complexity

### execute-plan-context-gathering
- Search for similar implementations
- Identify reusable code and patterns
- Document dependencies
- Map integration points

### execute-plan-solution-design
- Create technical architecture
- Design component interfaces
- Build implementation checklist
- Document design decisions

### execute-plan-implementation
- Execute the implementation checklist
- Write and modify code
- Create tests alongside code
- Track all changes made

### execute-plan-validation
- Run automated tests
- Perform manual testing
- Fix issues found
- Document test results

### execute-plan-documentation
- Update README files
- Create API documentation
- Add code comments
- Write user guides

### execute-plan-knowledge-capture
- Extract technical learnings
- Document reusable patterns
- Identify improvements
- Create knowledge artifacts

## Plan Structure

Agents work with markdown plans in `.llms/` directory:

```markdown
# Development Plan: [Task]

## Phase 1: Scope Analysis
**Status**: In Progress

### Objectives
- [ ] Tasks to complete

### Findings
<!-- Agent updates this -->

## Phase 2: Context Gathering
**Status**: Pending
...
```

## Agent Guidelines

### Input
Each agent reads:
- Current plan from `.llms/dev-plan-*.md`
- Previous phase outputs
- Project codebase as needed

### Processing
Agents follow their specific process:
1. Read current state
2. Execute phase tasks
3. Update plan with results
4. Mark phase complete

### Output
Each agent produces:
- Updated plan with findings/results
- Phase marked as complete
- Next phase marked as "In Progress"
- Git commit for the phase

## Git Integration

Agents follow these git practices:
- Work on feature branches only
- Commit after each phase
- Never commit to main/master
- Use conventional commit messages:
  - `chore:` - Scope analysis
  - `docs:` - Context, design, documentation, knowledge
  - `feat:` - Implementation
  - `test:` - Validation

## Best Practices

1. **Phase Isolation**: Each agent focuses only on their phase
2. **Clear Documentation**: Agents document all findings
3. **Progress Tracking**: Real-time plan updates
4. **Quality Focus**: Validation before proceeding
5. **Knowledge Preservation**: Capture learnings for future

## Integration with Skills

These agents are designed to work with:
- `create-plan` skill - Creates the initial plan
- `execute-plan` skill - Orchestrates agent execution

The workflow:
1. User: `skill create-plan` → Creates plan
2. User: `skill execute-plan` → Spawns agents
3. Agents execute phases autonomously
4. Plan progresses through completion

## Troubleshooting

### Agent Not Found
Ensure agent file exists in `claude-setup/agents/`

### Phase Not Progressing
Check plan status - phase must be "In Progress" or "Pending"

### Git Issues
Verify on correct feature branch before execution

### Test Failures
Agent will create fix cycles and retry

## Extending the System

To add new phases:
1. Create new agent in this directory
2. Follow the agent template structure
3. Update execute-plan skill mapping
4. Add phase to workflow templates

## Other Agents

This directory also contains specialized agents:
- `sandi-metz-reviewer.md` - Code review using Sandi Metz principles
- `security-reviewer.md` - Security-focused code review
- `spec-writer.md` - Test specification writing
- `tdd-tester.md` - Test-driven development support

These can be used independently or integrated into workflows as needed.