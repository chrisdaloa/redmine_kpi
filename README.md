# Redmine SLA Plugin

[![build](https://github.com/chrisdaloa/redmine_kpi/actions/workflows/build.yml/badge.svg)](https://github.com/chrisdaloa/redmine_kpi/actions/workflows/build.yml)
![Redmine](https://img.shields.io/badge/redmine->=6.0-blue?logo=redmine&logoColor=%23B32024&labelColor=f0f0f0&link=https%3A%2F%2Fwww.redmine.org)

A Redmine plugin that tracks helpdesk SLA/KPI metrics: acknowledgement, first response and resolution times, measured against a configurable business calendar and per-project/tracker/priority rules.

## Features

- **Three KPIs per issue**: acknowledgement (first status change), first response (first public note from someone other than the author) and resolution (entry into a configured "resolved" status, with support for reopen/re-resolve cycles).
- **Business calendar**: configurable working days/hours and holidays, defined globally with an optional per-project override, used to compute due dates instead of raw wall-clock time.
- **SLA pause**: the countdown for any KPI can be paused while an issue sits in a configured "pause" status (e.g. waiting for the customer), globally or per project.
- **Configurable rules**: SLA targets (in minutes) per KPI, matchable by tracker, priority, or a tracker+priority combination, with a global fallback and per-project overrides.
- **Three-level status**: each KPI is classified as on time / at risk / breached (plus paused), based on a configurable risk threshold percentage.
- **Issue view integration**: an SLA box on the issue detail page showing due dates and status for each tracked KPI.
- **Issue list integration**: sortable/filterable due-date columns and status columns per KPI, added to the standard issue query.
- **Per-project activation**: enable/disable the SLA module per project like any other Redmine module, with a `view_sla` and a `manage_sla_settings` permission.
- **Administration**: a "Configure SLA" entry in the Administration panel, with tabbed navigation across general settings, business calendar and rules.
- **Project settings**: a project-level SLA menu entry to override the global calendar, rules and thresholds, plus an on-demand SLA metrics recalculation action (also available as a rake task for bulk backfills).
- **Italian localization**: full `it.yml` translation alongside the default English locale.

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
