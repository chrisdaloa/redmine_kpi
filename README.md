# Redmine SLA Plugin

[![build](https://github.com/yourname/redmine_sla/actions/workflows/build.yml/badge.svg)](https://github.com/yourname/redmine_sla/actions/workflows/build.yml)
![Redmine](https://img.shields.io/badge/redmine->=6.0-blue?logo=redmine&logoColor=%23B32024&labelColor=f0f0f0&link=https%3A%2F%2Fwww.redmine.org)

A Redmine plugin scaffolded from the [redmine_ai_helper](https://github.com/haru/redmine_ai_helper) boilerplate.

## Installation

```bash
cd redmine/plugins
git clone https://github.com/yourname/redmine_sla.git
cd ../..
bundle install
bundle exec rake redmine:plugins:migrate RAILS_ENV=production
```

Restart Redmine after installation.

## Development

```bash
# Run all tests
bundle exec rake redmine:plugins:test NAME=redmine_sla

# Run a single test file
bundle exec ruby -I"lib:test" plugins/redmine_sla/test/unit/some_test.rb

# Setup test environment (first time only)
bundle exec rake redmine:plugins:migrate RAILS_ENV=test
```

## License

MIT — see [LICENSE](LICENSE).
