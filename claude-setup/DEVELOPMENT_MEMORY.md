# Working Memory (.llms/dev-memory.json)

## PURPOSE
Persistent knowledge store that captures learnings, patterns, and gotchas discovered during development. Query this before starting new features to leverage existing knowledge.

## STRUCTURE
```json
{
  "version": "1.0",
  "last_updated": "ISO-8601 timestamp",
  "total_entries": 0,
  "knowledge": {
    "patterns": [
      {
        "id": "unique-id",
        "tags": ["auth", "middleware", "security"],
        "context": "Authentication handled via middleware pattern",
        "files": ["app/middleware/auth.rb:45-67"],
        "created": "timestamp",
        "accessed_count": 0,
        "last_accessed": "timestamp"
      }
    ],
    "testing": [...],
    "gotchas": [...],
    "components": [...],
    "integrations": [...],
    "performance": [...],
    "conventions": [...]
  }
}
```

## SEARCHABLE CATEGORIES
- **patterns**: Code implementation patterns
- **testing**: Test approaches and helpers (RSpec patterns, factories)
- **gotchas**: Common pitfalls and solutions
- **components**: Reusable component locations
- **integrations**: External service patterns (ClickSend, GoodJob)
- **performance**: Optimization learnings
- **conventions**: Naming and structure rules

## QUERY PATTERNS

### Using the Memory Search Script (Recommended)
```bash
# Search by tag
node .llms/memory-search.js query "tags:auth"

# Search in context
node .llms/memory-search.js query "context:middleware"

# Search by category
node .llms/memory-search.js query "category:testing"

# Combined search
node .llms/memory-search.js query "tags:api AND category:gotchas"

# Full-text search
node .llms/memory-search.js query "viewcomponents"

# View all available tags (ALWAYS DO THIS BEFORE ADDING NEW ENTRIES)
node .llms/memory-search.js tags

# Check if proposed tags are similar to existing ones
node .llms/memory-search.js suggest authentication auth-service

# Add new entry (automatically checks for similar tags)
node .llms/memory-search.js add patterns '{"tags":["new-pattern"],"context":"Description","files":["app/models/example.rb"]}'

# Force add without tag similarity check
node .llms/memory-search.js add patterns '{"tags":["new-pattern"],"context":"Description"}' --force
```

### Direct LLM Search (Simple queries)
```javascript
// LLM can read .llms/dev-memory.json and filter programmatically
// Use for simple searches when script isn't available
```

## USAGE RECOMMENDATIONS

### When to Use Script vs LLM Direct
- **Use Script**: Complex queries, access tracking needed, performance critical
- **Use LLM Direct**: Script unavailable, simple filtering, one-off searches

### Best Practices
- **Always query memory** before implementing similar features
- **Check existing tags first**: Always run `node .llms/memory-search.js tags` before adding new entries
- **Use consistent tags**: Check for similar existing tags with `suggest` command
- **Update access counts** to track popular patterns
- **Add new learnings** immediately after discovery
- **Use descriptive tags** for better searchability
- **Include file references** with specific line numbers

### Tag Management Workflow
```bash
# STEP 1: Always check existing tags before adding new entries
node .llms/memory-search.js tags

# STEP 2: Check if your proposed tags are similar to existing ones
node .llms/memory-search.js suggest your-proposed-tag another-tag

# STEP 3: Add entry (will automatically suggest similar tags)
node .llms/memory-search.js add category '{"tags":["tag1","tag2"],"context":"..."}'

# STEP 4: Use --force only if you're sure the new tags are necessary
```

### Tag Categories to Use
Based on current memory structure, prefer these tag categories:
- **Technical**: `rails`, `activerecord`, `viewcomponents`, `stimulus`, `goodjob`
- **Patterns**: `service-objects`, `operations`, `aggregates`, `domain-modeling`
- **Architecture**: `mvc`, `layered-architecture`, `multi-tenant`
- **Security**: `authentication`, `authorization`, `pundit`, `devise`
- **Testing**: `rspec`, `fabrication`, `capybara`, `coverage`
- **Performance**: `n+1`, `includes`, `caching`, `query-optimization`
- **Frontend**: `hotwire`, `turbo`, `tailwind`, `ui-components`
- **Integrations**: `clicksend`, `activestorage`, `actionmailer`

### Memory Maintenance
- Review low-access entries periodically
- Consolidate duplicate patterns
- Update examples when code changes
- Archive obsolete patterns

## INTEGRATION WITH DEV PROCEDURE
During phase 7 (Knowledge Capture):

### REQUIRED WORKFLOW:
```bash
# 1. Check existing tags to maintain consistency
node .llms/memory-search.js tags

# 2. Identify what category your learning fits into
# Choose from: patterns, testing, gotchas, components, integrations, performance, conventions

# 3. Check if your proposed tags already exist or are similar
node .llms/memory-search.js suggest your-tag-1 your-tag-2

# 4. Add your learning (script will warn about similar tags)
node .llms/memory-search.js add patterns '{
  "tags": ["your-tags-here"],
  "context": "Clear description of what was learned",
  "files": ["specific/file/path:line-numbers"],
  "examples": ["code examples or usage patterns"],
  "solution": "if this is a gotcha, provide the solution"
}'

# 5. Update accessed_count for any entries you referenced during development
# This happens automatically when you search, but you can also query specific entries
```

### MANUAL PROCESS (fallback):
1. Read current .llms/dev-memory.json
2. Add new learnings with appropriate categorization and consistent tagging
3. Update accessed_count for referenced entries
4. Write back to .llms/dev-memory.json

### WHAT TO CAPTURE:
- **New patterns discovered** (architectural, code organization, Rails conventions)
- **Gotchas and solutions** (edge cases, common mistakes, workarounds)
- **Reusable components** (ViewComponents, services, helpers)
- **Performance learnings** (query optimization, caching strategies)
- **Integration insights** (external APIs, third-party services)
- **Testing approaches** (new test patterns, mocking strategies)

## AI AGENT ORCHESTRATION MEMORY GUIDELINES

### AGENT-SPECIFIC MEMORY CAPTURE

When using the AI Agent Orchestration system, each agent type has specific memory capture responsibilities:

#### Scope Analysis Agent Memory
```bash
# Query before analysis
node .llms/memory-search.js query "tags:scope AND category:patterns"
node .llms/memory-search.js query "size:epic" # For decomposition patterns

# Capture after analysis
node .llms/memory-search.js add patterns '{
  "tags": ["scope", "size-classification", "epic-decomposition"],
  "context": "Size classification patterns for [feature type]",
  "examples": ["Keywords that indicate large features"]
}'
```

#### Context Gathering Agent Memory
```bash
# Query for existing patterns
node .llms/memory-search.js query "tags:[feature-type] AND category:components"
node .llms/memory-search.js query "category:testing" # For test patterns

# Capture discoveries
node .llms/memory-search.js add components '{
  "tags": ["reusable", "[technology]", "[pattern-type]"],
  "context": "Reusable component discovered during context gathering",
  "files": ["app/components/component_name.rb"],
  "examples": ["Usage patterns or integration examples"]
}'
```

#### Solution Design Agent Memory
```bash
# Query for architecture patterns
node .llms/memory-search.js query "category:patterns AND tags:architecture"

# Capture design decisions
node .llms/memory-search.js add patterns '{
  "tags": ["architecture", "design-decision", "[feature-type]"],
  "context": "Architecture pattern for [specific use case]",
  "files": ["design artifacts or key implementation files"],
  "solution": "Rationale for chosen approach"
}'
```

#### Implementation Agent Memory
```bash
# Query for implementation patterns
node .llms/memory-search.js query "tags:[technology] AND category:patterns"
node .llms/memory-search.js query "tags:tdd AND category:testing"

# Capture implementation learnings
node .llms/memory-search.js add gotchas '{
  "tags": ["implementation", "[technology]", "tdd"],
  "context": "Implementation challenge encountered",
  "solution": "How the issue was resolved",
  "files": ["files where solution was applied"]
}'
```

#### Validation Agent Memory
```bash
# Query for testing patterns
node .llms/memory-search.js query "category:testing"
node .llms/memory-search.js query "tags:performance"

# Capture validation insights
node .llms/memory-search.js add testing '{
  "tags": ["validation", "testing", "[test-type]"],
  "context": "Validation approach or testing pattern",
  "examples": ["Test commands or validation procedures"],
  "files": ["spec files or test configurations"]
}'
```

#### Knowledge Capture Agent Memory
```bash
# This agent performs final consolidation
# Query for all project-related entries
node .llms/memory-search.js query "tags:[project-slug]"

# Add consolidated learnings
node .llms/memory-search.js add patterns '{
  "tags": ["[project-slug]", "consolidated", "agent-orchestrated"],
  "context": "Overall patterns and learnings from orchestrated development",
  "solution": "Key insights and best practices discovered",
  "files": ["all files modified during orchestration"]
}'
```

### ORCHESTRATION-SPECIFIC TAGS

Use these tags for agent-orchestrated memory entries:
- `agent-orchestrated`: Indicates entry was created by orchestration system
- `scope-analysis`, `context-gathering`, `solution-design`, `implementation`, `validation`, `knowledge-capture`: Phase-specific tags
- `checkpoint-passed`, `checkpoint-failed`: Validation checkpoint results
- `retry-[number]`: For entries related to retry attempts
- `automated`: For entries automatically captured by agents

### MEMORY INTEGRATION PATTERNS

#### Agent Context Sharing
Agents can share context through memory:
```bash
# Agent stores intermediate results
node .llms/memory-search.js add patterns '{
  "tags": ["context-sharing", "phase-[phase-name]", "temp"],
  "context": "Intermediate findings for next agent",
  "ttl": 3600000
}'

# Next agent queries shared context
node .llms/memory-search.js query "tags:context-sharing AND tags:phase-[previous-phase]"
```

#### Cross-Agent Learning
```bash
# Query what other agents learned about similar features
node .llms/memory-search.js query "tags:[feature-type] AND agent-orchestrated"

# Learn from previous orchestration runs
node .llms/memory-search.js query "tags:retry AND category:gotchas"
```

### VALIDATION RULES FOR ORCHESTRATED MEMORY

- **Tag Consistency**: All orchestrated entries must include agent type tag
- **Context Completeness**: Must include sufficient context for future reuse
- **File References**: Include specific file paths with line numbers where applicable
- **Temporal Tags**: Include size and complexity indicators for better filtering
