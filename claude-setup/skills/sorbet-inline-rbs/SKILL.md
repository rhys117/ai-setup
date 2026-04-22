---
name: sorbet-inline-rbs
description: Create RBS type signatures using Sorbet's inline RBS comment syntax.
---

# Sorbet Inline RBS Signatures

This project uses Sorbet with RBS comment syntax (`--enable-experimental-rbs-comments`). We do NOT use sorbet-runtime (no `T.let`, `T.nilable`, `sig {}` blocks, etc.).

## Documentation Reference
- https://sorbet.org/docs/rbs-support

## Key Rules

### 1. Use `#:` for type annotations
```ruby
#: (Integer) -> String
def foo(x); end
```

### 2. Use concise syntax - no empty parens
```ruby
# Good
#: -> String
def foo; end

# Bad - don't use empty parens
#: () -> String
def foo; end
```

### 3. Multi-line signatures use `#|` continuation
```ruby
#: (step: MessageFlow::Step, status: Symbol, completed: bool,
#|  recipient_count: Integer) -> ActiveSupport::SafeBuffer
def render_step(step:, status:, completed:, recipient_count:)
```

### 4. Instance variables - annotate on same line
```ruby
@steps ||= STEPS.map { |attrs| Step.new(**attrs) } #: Array[Step]?
@current_step ||= steps.find { |s| !completed?(s) } || steps.last #: Step?
```

### 5. Constants - annotate at end of line
```ruby
STEPS = [...].freeze #: Array[Hash[Symbol, untyped]]
```

### 6. Attribute readers - group by type
```ruby
#: Symbol
attr_reader :key, :icon
#: String
attr_reader :name, :description, :template
#: ActiveSupport::Duration?
attr_reader :send_before_event, :send_after_event
```

### 7. Use `typed: true` not `typed: strict`
- `typed: strict` requires signatures for ALL methods including Data.define accessors
- `typed: true` is more practical for most files
- Data.define generated methods don't have sigs in strict mode

### 8. RBS shim files go next to the .rb file
If needed, place `.rbs` files in the same directory as the `.rb` file, not in `sorbet/rbi/shims/`.

## Type Syntax Quick Reference

| RBS Syntax | Meaning |
|------------|---------|
| `Type?` | Nilable (T.nilable) |
| `Type1 \| Type2` | Union (T.any) |
| `Type1 & Type2` | Intersection (T.all) |
| `[Type1, Type2]` | Tuple |
| `{ key: Type }` | Shape/Hash |
| `^(Type) -> Type` | Proc/Lambda |
| `Array[Type]` | Generic array |
| `Hash[K, V]` | Generic hash |
| `untyped` | Escape hatch |

## Common Patterns

### Method with keyword args
```ruby
#: (message_flow: MessageFlow, ?current_step_key: Symbol?, ?clickable: bool) -> void
def initialize(message_flow:, current_step_key: nil, clickable: true)
```

### Method accepting multiple types
```ruby
#: (Step | Symbol) -> bool
def step_completed?(step)
```

### Optional parameter with nil default
```ruby
#: (?(Symbol | String | nil)) -> Step
def resolve_step(key = nil)
```

### ActiveRecord relations
```ruby
#: (Step | Symbol) -> Participant::PrivateRelation
def participants_for_step(step)
```

## Gotchas

1. **Comment must be immediately before def** - blank lines break it
2. **No runtime type checking** - RBS comments are static analysis only
3. **Data.define accessors** - Can't easily type in strict mode, use `typed: true`
4. **Hash splat with keyword params** - Sorbet can't handle `Step.new(**attrs)` well in strict mode
5. **Date arithmetic with Duration** - Sorbet's Date RBI doesn't know about ActiveSupport::Duration extensions
