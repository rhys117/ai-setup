# Claude Code Configuration

## MUST FOLLOW RULES
- NEVER commit to the `main` branch
- Complete changes on an appropriate feature branch (refer to deveopment procedure below)
- Commit changes often. Follow conventional commits pattern.

## Development Procedure
YOU NOW MUST IMMEDIATELY READ THE [DEVELOPMENT_PROCEDURE.md](.llms/DEVELOPMENT_PROCEDURE.md) FILE for the structured feature development workflow including:
- Plan file tracking (`.llms/.dev-plan-*.yaml`)
- Development process
- Working memory system (`.llms/dev-memory.json`)
- Tag management and search tools (`.llms/memory-search.js`)
- Size-based workflow mapping

WHEN MOVING ONTO THE NEXT STEP IN THE DEVELOPMENT PROCEDURE YOU MUST:
- Re-Read the DEVELOPMENT_PROCEDURE.md file
- Verify that you do not need to revisit an earlier step
- Update the development plan
- announce that you're moving into the next step

## Project Overview
"Let Me Know" is a Ruby on Rails 8.0 event management and RSVP system.

### Technology Stack
- **Backend**: Ruby 3.2.2, Rails 8.0
- **Database**: PostgreSQL
- **Frontend**: Tailwind CSS, Alpine.js, Turbo
- **Background Jobs**: GoodJob
- **Communications**: ClickSend (SMS), ActionMailer (Email)
- **AI Orchestration**: claude-flow (v1.0.72)
- **Containerization**: Docker with timestamped worktree isolation
- **Testing**: Use of rspec for testing

### Rails Commands (inside container)
```bash
bundle install        # Install Ruby dependencies
rails db:create       # Create database
rails db:migrate      # Run migrations
rails db:seed         # Seed database
rails server          # Start Rails server (port 3000 internal, 3050 external)
bundle exec rspec     # Run RSpec tests
```

## Code Style & Conventions

### Ruby/Rails Conventions
- Follow Rails 8.0 best practices
- Use strong parameters for all controllers
- Implement service objects in `app/services/` for complex business logic
- Use concerns for shared functionality
- Follow RESTful routing conventions
- Use Rails validations and callbacks appropriately

### Frontend Conventions
- Use Tailwind CSS for styling (no custom CSS unless necessary)
- Implement interactivity with Alpine.js
- Use Turbo for SPA-like navigation
- Follow BEM naming for custom components

### Database Conventions
- Always create indexes for foreign keys
- Use Rails migrations exclusively (never modify schema.rb directly)
- Always create migrations via the Rails generator, you may edit the migration file after creation
- NEVER modify ALREADY migrated migrations UNLESS you are rolling back the IMMEDIATE migration YOU have CREATED
- Follow Rails naming conventions for tables and columns
- Use appropriate PostgreSQL data types

### Testing Requirements
- Write tests for all new features
- Use RSpec for model and service specs
- Use RSpec system tests for integration testing
- Maintain test coverage above 80%
- Run tests before committing: `bundle exec rspec`

## Project Context

### Core Features
- Event creation and management
- RSVP collection and tracking
- Guest communication (SMS/Email)
- Seating arrangement management
- Vendor coordination
- Custom event theming

### Key Models
- `Event`: Core event entity
- `Guest`: Event participants
- `RSVP`: Guest responses
- `Communication`: SMS/Email logs
- `Vendor`: Service providers
- `SeatingArrangement`: Table assignments

### API Patterns
- RESTful JSON APIs under `/api/v1/`
- Use serializers for API responses
- Implement proper authentication/authorization
- Follow Rails API conventions

### Security Considerations
- Never commit credentials or secrets
- Use Rails credentials for sensitive data
- Implement proper authorization checks
- Sanitize all user inputs
- Use CSRF protection for forms

### Ports
- 3000: Rails

### When Working on This Project
1. Always check existing patterns before implementing new features
2. Use Rails generators when appropriate
3. Follow TDD practices
4. Maintain consistent code style with existing codebase
5. Run linters and tests before marking tasks complete
