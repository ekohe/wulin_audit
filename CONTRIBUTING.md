# Contributing

Development setup for working on this gem itself. If you're integrating `wulin_audit` into a host app, see `AGENTS.md` and the README instead.

## Commands

```shell
bundle install
bundle exec rake test        # minitest, test/**/*_test.rb
bundle exec standardrb       # lint (must be clean before commit)
bundle exec standardrb --fix # auto-fix lint offenses
```

CI (`.gitlab-ci.yml`) runs `standardrb` then `rake test` on every push.

## Structure

- `lib/wulin_audit.rb` — gem entry point; defines `WulinAudit.action_log_enabled` (default `true`) and conditionally requires the ORM/WulinMaster integrations below
- `lib/wulin_audit/engine.rb` — Rails::Engine, initializers (audit callbacks, action-log subscriber, request-id capture)
- `lib/wulin_audit/action_log_subscriber.rb` — `ActiveSupport::Notifications` subscriber that writes `ActionLog` rows on a background thread pool
- `lib/wulin_audit/extension.rb` — `WulinAudit::Extension`, the `after_create`/`after_update`/`after_destroy` audit hooks; `orm/active_record.rb` mixes it into `ActiveRecord::Base`
- `lib/wulin_audit/wulin_master.rb` — patches `WulinMaster::Grid` to add the default `:audit` toolbar action, gated on `record_audit#read`
- `lib/tasks/*.rake` — `wulin_audit:load_audit_in_influxdb` (backfill) and `wulin_audit:migrate_audit_log` (legacy MongoDB→PostgreSQL one-off)
- `app/models/wulin_audit/` — `AuditLog`, `ActionLog`
- `app/grid/`, `app/screens/`, `app/controllers/wulin_audit/` — WulinMaster UI integration; guarded with `if defined? WulinMaster` (and `if defined? WulinExcel` for export)
- `config/routes.rb` — namespaces `audit_logs`, `record_audits`, `action_logs` under `/wulin_audit`
- `db/migrate/` — engine migrations, auto-loaded by host apps
- `test/test_helper.rb` — boots a stub environment (no full Rails app): sqlite3 shared-cache in-memory DB, a stubbed `User.current_user`, and a stubbed `Rails.application.config.filter_parameters`

## Conventions

- Migration timestamps must not collide with `wulin_master`'s own migrations — never reuse `000000`; pick a real, unique timestamp.
- `db/migrate/..._create_action_log_screen_permissions.rb` writes `Permission` rows (`action_log#read`/`action_log#cud`), not just schema, and only if the host app defines a `Permission` model. Keep that guard if you add similar screen-permission migrations.
- `WulinMaster` and `WulinExcel` are optional peer gems, not dependencies — any code touching them must be guarded with `defined?`.
- `standardrb` is the formatter/linter; don't hand-format against a different style.
- Prefer the simplest solution: no speculative abstractions, no dead parameters, no code guarding against cases that can't happen.
