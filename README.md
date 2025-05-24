# README

# Rules

## Purpose

A collection of AI rules or setup guides for better prompt engineering practices for AI models and code consistency.

## Usage

To use these rules, copy them into the appropriate directory, (`.cursor/rules`, or `.roo/rules-{mode}`) and ensure you order them appropiately for your use case. The rules are designed to be modular and can be combined as needed.

## TODO:

Build a CLI tool to merge groups of rules together depending on the project and symlink the resulting directory to the appropriate location.

## Contributors

I am in no way taking credit for the rules themselves, these are only a collection of rules that I have found useful in my own projects and modified to fit my needs. Many of these rules are inspired by the work of others in the community, and I encourage you to explore their repositories for more context and examples.

See the following repositories for the where I found most of these rules:
- https://github.com/GreatScottyMac/roo-code-memory-bank
- https://github.com/Mawla/cursor_rules/tree/main/.cursor/rules

## Other recommendations

#### Setup a tech stack specific rule. Here's an example.
```md
The following tech stack is implemented in this repository, ensure you use the approprate technology
when writing code or prompts. Follow the conventions and best practices outlined in the tech stack documentation.

## 4. Tech Stack

- **Backend**: Ruby on Rails 8
- **Frontend**: Hotwire (Turbo + Stimulus)
- **Styling**: Tailwind CSS
- **Database**: PostgreSQL (via Docker)
- **Testing**: RSpec, Capybara
- **Background Jobs**: Queue
- **Caching**: Solid Cache (default in Rails 8)
- **Real-time**: Solid Cable
- **Authentication**: Built-in Sessions Generator
- **Authorization**: Pundit
- **Deployment**: Kamal 2 (default in Rails 8)
- **Asset Pipeline**: Propshaft (default in Rails 8)
- **Container**: Docker (development & production)
```

# Practices 

## Reading List

Ruvnet - https://github.com/ruvnet/ruvnet
