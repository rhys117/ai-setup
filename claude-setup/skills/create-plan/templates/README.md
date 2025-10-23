# Plan Templates

This directory contains markdown templates for each workflow size used by the `create-plan` skill.

## Template Files

| File | Workflow | Phases | Use Case |
|------|----------|--------|----------|
| `micro.md` | Micro | 1 | Single file, trivial changes |
| `small.md` | Small | 3 | 2-3 files, straightforward changes |
| `medium.md` | Medium | 5 | Multiple files, moderate complexity |
| `large.md` | Large | 6 | Many files, significant changes |
| `epic.md` | Epic | 7 | Major features requiring decomposition |
| `subtask.md` | Variable | Depends | Subtasks of epic workflows |

## Template Structure

Each template includes:

1. **Overview Section**
   - Task description
   - Workflow classification
   - Status tracking
   - Timestamps
   - Priority level
   - Git branch reference

2. **Phase Sections**
   - Phase name and number
   - Status indicator
   - Objectives (as checkboxes)
   - Output sections (Findings, Changes, Results, etc.)
   - Phase-specific subsections

3. **Progress Log**
   - Timestamped events
   - Phase transitions
   - Significant milestones

4. **Special Sections**
   - **Subtasks** (epic only): Links to decomposed subtask plans
   - **Fix Cycles** (validation phase): Iterative issue resolution
   - **Design Artifacts** (large/epic): Architecture diagrams, specs
   - **Knowledge Capture** (epic only): Learnings and recommendations

## Phase Progression

### Standard Phase Flow

```
Scope Analysis → Context Gathering → Solution Design → Implementation → Validation → Documentation → Knowledge Capture
```

### Workflow-Specific Phases

- **Micro**: Implementation only
- **Small**: Scope → Implementation → Validation
- **Medium**: Scope → Context → Design → Implementation → Validation
- **Large**: All except Knowledge Capture
- **Epic**: All phases + Subtask coordination

## Template Placeholders

Templates use these placeholders to be filled during plan creation:

- `[Task Name]`: The main task description
- `[Description]`: Detailed task description
- `[ISO timestamp]`: ISO 8601 formatted timestamp
- `[high/medium/low]`: Priority selection
- `[slug]`: URL-friendly task identifier
- `[appropriate size]`: Workflow size determination
- `[Parent task name]`: For subtask references

## Customization

These templates can be customized per project needs:

1. **Add project-specific phases**: Insert new phase sections
2. **Modify objectives**: Adjust checklist items per team standards
3. **Include custom sections**: Add project-specific tracking
4. **Adjust workflow sizes**: Redefine what constitutes each size

## Usage

The `create-plan` skill automatically selects the appropriate template based on:

1. Task complexity analysis
2. Number of files affected
3. Need for design documentation
4. Testing requirements
5. User preference (if specified)

## Best Practices

1. **Keep templates consistent**: Maintain similar structure across sizes
2. **Use clear placeholders**: Make it obvious what needs replacement
3. **Include helpful comments**: Use `<!-- -->` for guidance
4. **Version control templates**: Track template evolution
5. **Document customizations**: Note any project-specific changes

## Integration

These templates integrate with:
- `create-plan` skill: Generates plans from templates
- `execute-plan` skill: Reads and updates generated plans
- Git workflow: Branch references and commit tracking
- Progress tracking: Status and checkbox management