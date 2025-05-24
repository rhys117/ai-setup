# Rails 8 Development Guidelines

## 1. Rails 8 Core Features

** Prefer the command line utilities to manually generated code ** 

e.g use `rails generate model` instead of creating a model from scratch

- You can monitor development.log for errors and performance issues
- Use `tail -f log/development.log` for real-time monitoring
- Review logs before considering any change complete

1. **Modern Infrastructure**
   - Use Thruster for asset compression and caching
   - Utilize turbo streams and frames for dynamic content
   - Leverage Solid Cache for caching
   - Use Solid Cable for real-time features
   - Configure healthcheck silencing in production logs

2. **Database Best Practices**
   - Use PostgreSQL full-text search capabilities
   - Configure proper database extensions in database.yml
   - Implement database partitioning for large datasets
   - Use proper database indexing strategies
   - Configure connection pooling
   - Implement proper backup strategies
   - Use PostgreSQL-specific features (arrays, jsonb, etc)
   - Monitor and optimize query performance

3. **Controller Patterns**
   - Use `params.expect()` for safer parameter handling
   - Implement rate limiting via cache store
   - Use the new sessions generator for authentication
   - Silence healthcheck requests in production
   - Keep controllers RESTful and focused
   - Use service objects for complex business logic

4. **Progressive Web App Features**
   - Utilize default PWA manifest
   - Implement service worker functionality
   - Configure browser version requirements
   - Use `allow_browser` to set minimum versions
   - Implement offline capabilities
   - Configure proper caching strategies

## 2. Development Standards

1. **Code Organization**
   - Follow Single Responsibility Principle
   - Use service objects for complex business logic
   - Keep controllers skinny
   - Use concerns for shared functionality
   - Use `params.expect()` instead of strong parameters
   - Follow Rails 8 conventions
   - Where practical, follow Sandi Metz's rules for Rails
    - Classes can be no longer than one hundred lines of code.
    - Methods can be no longer than five lines of code.
    - Pass no more than four parameters into a method. Hash options are parameters.
    - Controllers can instantiate only one object. Therefore, views can only know about one instance variable and views should only send messages to that object (@object.collaborator.value is not allowed).
      - Use service objects to encapsulate complex logic `app/services`.
      - Use operations to encapsulate complex workflows related to a model `app/operations`. 

2. **Performance**
   - Use Thruster for asset compression
   - Implement proper caching with Solid Cache
   - Configure connection pooling
   - Use a Queue for background jobs
   - Monitor application metrics
   - Regular performance profiling
   - Optimize database queries
   - Use proper indexing strategies

3. **Testing**
   - Write comprehensive tests
   - Use factories instead of fixtures
   - Test happy and edge cases
   - Keep tests DRY but readable
   - Use parallel testing by default
   - Regular security testing
   - Performance testing
   - Load testing for critical paths

4. **Security**
   - Use `params.expect()` for parameter handling
   - Implement proper authorization
   - Sanitize user input
   - Follow OWASP guidelines
   - Configure rate limiting via cache store
   - Regular security audits
   - Keep dependencies updated
   - Use secure communication (HTTPS)

5. **Hotwire Patterns**
   - Use Turbo Frames for partial page updates
   - Use Turbo Streams for real-time updates
   - Keep Stimulus controllers focused and simple
   - Use data attributes for JavaScript hooks
   - Use Solid Cable for real-time features

6. **Logging and Monitoring**
   - Check logs after every code change
   - Monitor development.log for errors
   - Use `tail -f log/development.log` for real-time monitoring
   - Review logs before marking tasks as complete
   - Set up proper log rotation
   - Configure log levels appropriately
   - Monitor performance metrics
   - Track error rates and patterns

## 3. Directory Structure

```
/app
├── components/     # View components
│   └── ui/         # UI components
├── controllers/    # Controllers
├── models/         # Active Record models
├── views/          # View templates
├── helpers/        # View helpers
├── javascript/     # Stimulus controllers
│   └── controllers/
├── operations/     # Business logic encapsulated in operations
├── services/       # Service objects
├── policies/       # Pundit policies
├── jobs/          # Background jobs
├── mailers/       # Action Mailer classes
└── assets/        # Assets (if not using importmap)
```
