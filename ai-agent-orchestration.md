# AI Agent Orchestration Architecture

## System Overview
This diagram illustrates the multi-agent orchestration system for the "Let Me Know" application, leveraging the existing dev container, development procedure, and memory systems.

```mermaid
graph TB
    subgraph "Development Environment"
        DC[Dev Container<br/>Isolated Environment]
        DP[Development Procedure<br/>DEVELOPMENT_PROCEDURE.md]
        DM[Development Memory<br/>dev-memory.json]
        MS[Memory Search<br/>memory-search.js]
    end

    subgraph "Orchestration Layer"
        OA[Orchestrator Agent<br/>Main Controller]
        PM[Plan Manager<br/>dev-plan-*.yaml]
        AS[Agent Spawner<br/>Context-Specific Agent Creator]
        VA[Validation Agent<br/>Change Verifier]
    end

    subgraph "Execution Agents"
        SA1[Scope Analysis Agent<br/>Requirements & Size Classification]
        CG1[Context Gathering Agent<br/>Codebase Pattern Discovery]
        SD1[Solution Design Agent<br/>Architecture & File Planning]
        IM1[Implementation Agent<br/>Code Changes & Testing]
        VL1[Validation Agent<br/>Testing & Quality Checks]
        KC1[Knowledge Capture Agent<br/>Memory System Updates]
    end

    subgraph "Agent Communication"
        AC[Agent Communication Bus]
        AL[Agent Lifecycle Manager]
        CS[Context Sharing System]
    end

    subgraph "Quality Control"
        PC[Plan Compliance Checker]
        CR[Code Review Agent]
        TR[Test Runner Agent]
        MU[Memory Updater Agent]
    end

    %% Main Flow
    OA --> PM
    PM --> AS
    AS --> SA1
    SA1 --> VA
    VA --> |Pass| AS
    VA --> |Fail/Retry| SA1
    AS --> CG1
    CG1 --> VA
    VA --> |Pass| AS
    VA --> |Fail/Retry| CG1
    AS --> SD1
    SD1 --> VA
    VA --> |Pass| AS
    VA --> |Fail/Retry| SD1
    AS --> IM1
    IM1 --> VA
    VA --> |Pass| AS
    VA --> |Fail/Retry| IM1
    AS --> VL1
    VL1 --> VA
    VA --> |Pass| AS
    VA --> |Fail/Retry| VL1
    AS --> KC1
    KC1 --> VA

    %% Environment Integration
    DC --> OA
    DP --> PM
    DM --> MS
    MS --> CG1
    MS --> KC1

    %% Agent Communication
    SA1 --> AC
    CG1 --> AC
    SD1 --> AC
    IM1 --> AC
    VL1 --> AC
    KC1 --> AC
    AC --> CS
    CS --> AL
    AL --> AS

    %% Quality Control
    VA --> PC
    PC --> CR
    CR --> TR
    TR --> MU
    MU --> DM

    %% Feedback Loops
    VA --> PM
    PC --> PM
    KC1 --> DM

    classDef orchestrator fill:#e1f5fe,stroke:#01579b,stroke-width:2px
    classDef execution fill:#f3e5f5,stroke:#4a148c,stroke-width:2px
    classDef quality fill:#e8f5e8,stroke:#1b5e20,stroke-width:2px
    classDef environment fill:#fff3e0,stroke:#e65100,stroke-width:2px
    classDef communication fill:#fce4ec,stroke:#880e4f,stroke-width:2px

    class OA,PM,AS,VA orchestrator
    class SA1,CG1,SD1,IM1,VL1,KC1 execution
    class PC,CR,TR,MU quality
    class DC,DP,DM,MS environment
    class AC,AL,CS communication
```

## Detailed Agent Specifications

### Orchestrator Agent
- **Purpose**: Main controller that manages the entire development workflow
- **Responsibilities**:
  - Parse incoming requests and initialize plan files
  - Monitor overall progress and handle failures
  - Coordinate agent lifecycle and resource allocation
  - Maintain global context and state

### Agent Spawner
- **Purpose**: Creates context-specific agents for each development phase
- **Responsibilities**:
  - Generate custom prompts based on current phase and context
  - Initialize agents with specific tools and constraints
  - Monitor agent completion and trigger validation
  - Handle agent termination and cleanup

### Validation Agent
- **Purpose**: Verifies changes against plan requirements
- **Responsibilities**:
  - Compare completed work against plan specifications
  - Run automated tests and quality checks
  - Determine if changes are acceptable or need retry
  - Update plan status and trigger next phase or retry

### Execution Agents (Phase-Specific)

#### Scope Analysis Agent
```yaml
tools: [Read, Grep, Glob, Memory Search]
constraints: 
  - Must classify size: micro|small|medium|large|epic
  - Must decompose epic tasks into subtasks
  - Must query memory for similar work
custom_prompt: |
  You are a scope analysis specialist. Your job is to parse requirements,
  classify task size, and decompose complex features. Use memory search
  to find similar implementations. Focus only on analysis, not implementation.
```

#### Context Gathering Agent
```yaml
tools: [Read, Grep, Glob, Memory Search, Task]
constraints:
  - Must identify existing patterns
  - Must locate reusable components  
  - Must document test patterns
custom_prompt: |
  You are a codebase explorer. Search for related components, existing patterns,
  and test structures. Document all findings for implementation agents.
  Focus on understanding, not changing code.
```

#### Solution Design Agent
```yaml
tools: [Read, Write (for design docs)]
constraints:
  - Must create architecture sketches for >small tasks
  - Must list affected files with line numbers
  - Must define integration points
custom_prompt: |
  You are a solution architect. Create detailed implementation plans
  based on context findings. Design before building. Document all
  architectural decisions.
```

#### Implementation Agent
```yaml
tools: [Read, Edit, MultiEdit, Write, Bash]
constraints:
  - Must write tests first (TDD)
  - Must run tests after each change
  - Must follow existing patterns
custom_prompt: |
  You are an implementation specialist. Follow the solution design exactly.
  Write failing tests first, implement minimal solutions, refactor as needed.
  Respect existing code conventions.
```

#### Validation Agent
```yaml
tools: [Bash, Read]
constraints:
  - Must run full test suite
  - Must perform manual testing checklist
  - Must check security if auth/data related
custom_prompt: |
  You are a quality assurance specialist. Run comprehensive tests,
  validate functionality, and ensure security standards.
  Report detailed validation results.
```

#### Knowledge Capture Agent
```yaml
tools: [Read, Write, Memory Search, Bash (for memory-search.js)]
constraints:
  - Must update memory with new patterns
  - Must document gotchas and solutions
  - Must maintain tag consistency
custom_prompt: |
  You are a knowledge curator. Capture learnings, patterns, and gotchas
  discovered during development. Use memory search tools to maintain
  consistency and avoid duplication.
```

## Agent Communication Protocol

### Message Types
- `PHASE_COMPLETE`: Agent signals completion with results
- `PHASE_FAILED`: Agent signals failure with error details
- `VALIDATION_PASS`: Validation agent approves changes
- `VALIDATION_FAIL`: Validation agent requests retry
- `PLAN_UPDATE`: Plan modifications from any agent
- `CONTEXT_SHARE`: Shared context between agents

### Lifecycle Management
1. **Spawn**: Create agent with custom prompt and constraints
2. **Monitor**: Track progress and resource usage
3. **Validate**: Check work against plan requirements
4. **Retry/Continue**: Based on validation results
5. **Terminate**: Clean up and capture final state

## Integration Points

### Existing Systems
- **Dev Container**: Provides isolated execution environment
- **Development Procedure**: Drives agent workflow phases
- **Memory System**: Provides knowledge persistence and search
- **Plan Files**: Track progress and coordinate agents

### Quality Gates
- Each phase must pass validation before proceeding
- Plan compliance checked at every step
- Memory system updated with new learnings
- Test suite must pass before completion
