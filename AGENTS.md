# Repository Guidelines

## Project Structure & Module Organization
Core Rails plugin code lives under `app/`, following standard MVC groupings (`app/controllers`, `app/models`, `app/helpers`). Plugin-specific library code lives in `lib/redmine_sla/`. Tests follow Redmine's minitest layout: controller flows in `test/functional/`, business logic in `test/unit/`, API tests in `test/integration/`.

## Build, Test, and Development Commands
- `bundle install` — install plugin gems. Run from the Redmine root.
- `bundle exec rake redmine:plugins:migrate RAILS_ENV=test` — prep the test DB.
- `bundle exec rake redmine:plugins:test NAME=redmine_sla` — execute unit and functional suites with coverage to `coverage/`.
- `bundle exec ruby -I"lib:test" plugins/redmine_sla/test/unit/some_test.rb` — run a single test file.
- `bundle exec rake redmine:plugins:test NAME=redmine_sla TESTOPTS="--name=/test_name_pattern/"` — run tests matching a pattern.

## Design Principles

Follow **KISS** (Keep It Simple), **DRY** (Don't Repeat Yourself), and **YAGNI** (You Aren't Gonna Need It):
- Write the simplest code that satisfies the requirement — no speculative abstractions
- Extract shared logic only when duplication is proven (≥3 occurrences), not preemptively
- Never add features, helpers, or error handling that aren't required by the current task

## Coding Style & Naming Conventions

### Ruby
- **Indentation**: Two spaces (not tabs)
- **Naming**: snake_case for methods and variables, CamelCase for classes
- **File header**: Always start with `# frozen_string_literal: true`
- **Comments**: Write in English
- **Imports**: Use `require` at file top, followed by relative requires
- **Constants**: SCREAMING_SNAKE_CASE, freeze with `.freeze` for immutable values
- **Error Handling**: NEVER implement fallback error handling — let errors surface immediately
- **TDD**: Write tests BEFORE implementing features (red-green-refactor cycle)

### JavaScript
- **Variables**: Use `const` and `let`, never `var`
- **Style**: Vanilla JavaScript only, no jQuery
- **Comments**: Write in English
- **DOM**: Target Redmine-provided DOM hooks; build HTML in ERB templates for security

### CSS
- **Styles**: Use Redmine's existing class definitions (e.g., `.box`)
- **Colors/fonts**: Do NOT introduce custom colors or fonts — leverage Redmine's design system

### Testing with Shoulda
```ruby
class SomeTest < ActiveSupport::TestCase
  context "method_name" do
    should "describe expected behavior" do
      # test implementation
    end
  end
end
```
- Use `shoulda` (context/should blocks), not RSpec
- Use `mocha` for mocking — but only when connecting to external servers
- Place fixtures in `test/model_factory.rb`

### Test-Driven Development (TDD)
Follow TDD: write tests BEFORE implementing features.
- Red: Write a failing test first
- Green: Write minimum code to make test pass
- Refactor: Improve code while keeping tests green
- Never write production code without a failing test
- For bug fixes, write a test that reproduces the bug first

## Commit & Pull Request Guidelines
- **Commit messages**: Concise, imperative, English (e.g., "Add SLA calculation for issues")
- **PR body**: Summarize change set, list commands/tests executed, reference related issues
- **UI changes**: Include screenshots

## Frontend Security
- Build HTML structures in ERB templates (`*.html.erb`), NOT in JavaScript
- This prevents XSS and injection vulnerabilities by leveraging Rails' automatic escaping
- JavaScript should only manipulate existing DOM elements rendered by ERB
- Use `sprite_icon` helper for icons, `t()` / `l()` for i18n text in templates

## Error Handling Best Practices
- **NEVER implement fallback error handling** — fallbacks hide real problems
- Let errors surface immediately for proper diagnosis

## Linting & Quality Tools
- **Rubocop**: Run `rubocop` for Ruby style checking; config in `.rubocop.yml`
- Configuration in `.qlty/qlty.toml` with plugins for actionlint, checkov, markdownlint, prettier, shellcheck, and trufflehog

## Internationalization
- All user-facing text must support i18n via `config/locales/*.yml`
- Use `t()` helper for translations
