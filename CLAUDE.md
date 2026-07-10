# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Redmine SLA Plugin — a Ruby on Rails plugin for Redmine.

## Development Commands

```bash
# Run all tests
bundle exec rake redmine:plugins:test NAME=redmine_sla

# Run a single test file
bundle exec ruby -I"lib:test" plugins/redmine_sla/test/unit/some_test.rb

# Run tests matching a pattern
bundle exec rake redmine:plugins:test NAME=redmine_sla TESTOPTS="--name=/test_name_pattern/"

# Setup test environment (first time only)
bundle exec rake redmine:plugins:migrate RAILS_ENV=test

# Run migrations
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

## Architecture

- `init.rb` — Plugin registration, permissions, and module setup
- `app/` — Standard Redmine/Rails MVC layout (`controllers`, `models`, `helpers`, `views`)
- `lib/redmine_sla/` — Plugin-specific library code, namespaced under `RedmineSla`
- `db/migrate/` — Plugin migrations
- `config/routes.rb` — Plugin routes
- `config/locales/*.yml` — Translations

## Development Guidelines

### Test-Driven Development (TDD)
This project follows TDD. **Always write tests BEFORE implementing features.**

1. **Red**: Write a failing test first
2. **Green**: Write minimum code to pass
3. **Refactor**: Improve while keeping tests green

Testing conventions:
- Use `shoulda` (context/should blocks), not rspec
- Use `mocha` for mocking external servers
- Use `test/model_factory.rb` for creating test fixtures
- Test structure: `test/unit/` (models), `test/functional/` (controllers), `test/integration/` (API tests)

### Code Style (Ruby)
- Follow Ruby on Rails conventions
- Write comments in English
- Two-space indentation, no tabs
- Start files with `# frozen_string_literal: true`

### Code Style (JavaScript)
- Use `let` and `const`, not `var`
- Vanilla JavaScript only, no jQuery
- Write comments in English

### Frontend Security
- Build HTML in ERB templates, not JavaScript (prevents XSS)
- JavaScript only manipulates existing DOM elements rendered by ERB
- Use `sprite_icon` for icons, `t()`/`l()` for i18n text in templates

### Error Handling
- **NEVER implement fallback error handling** — fallbacks hide real problems
- Let errors surface immediately for proper diagnosis

### CSS
- No custom colors or fonts — use Redmine's class definitions and design system
- Use Redmine's `.box` class for container elements

## Code Quality

After modifying any Ruby source file, run RuboCop and fix all offenses before finishing:

```bash
rubocop 2>&1
```

Use the `/rubocop` skill for the full fix workflow including auto-correction and test verification.

## Git Workflow

- Uses git-flow: `develop` is the integration branch, `main` is production
- Always branch from `develop` for new features/fixes
- Do not include any information about Claude Code in commit messages
- Write commit messages in plain English
- **NEVER commit or push without explicit instruction from the user**
