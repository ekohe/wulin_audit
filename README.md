# WulinAudit

Automatic audit logging for Rails + ActiveRecord. Every create, update, and delete is recorded with the user, IP address, and a detailed change log — no per-model setup required.

## Installation

Add to your Gemfile:

```ruby
gem 'wulin_audit'
```

Run:

```shell
bundle install
rails db:migrate
```

The engine auto-loads its migration. All ActiveRecord models are audited by default.

## How It Works

WulinAudit includes itself into `ActiveRecord::Base` via `after_create`, `after_update`, and `after_destroy` callbacks. Each audited action writes a `WulinAudit::AuditLog` record with:

| Column       | Description                              |
|--------------|------------------------------------------|
| `user_id`    | `User.current_user.try(:id)`             |
| `user_email` | `User.current_user.try(:email)`          |
| `request_ip` | `User.current_user.try(:ip)`             |
| `request_id` | Rails `X-Request-Id` of the request that triggered the change |
| `record_id`  | ID of the audited record                 |
| `action`     | `create`, `update`, or `delete`          |
| `class_name` | Class name of the audited record         |
| `detail`     | JSONB hash of changes                    |

Your application must implement `User.current_user` returning an object that responds to `id`, `email`, and `ip`.

## Excluding Models

```ruby
class Session < ActiveRecord::Base
  reject_audit
end
```

## Restricting Audited Columns

By default all columns are audited (except `created_at` and `updated_at`). To restrict:

```ruby
class Post < ActiveRecord::Base
  audit_columns :title, :content, :category
end
```

Ignored when `reject_audit` is set.

## Customizing Relation Display

When a foreign key changes, the audit log resolves it to a human-readable value. By default it looks for `name`, then `code`, then `id` on the related record. To override:

```ruby
class Department < ActiveRecord::Base
  human_relation_column :title
end
```

## Customizing the Audited Class Name

`RecordAuditScreen` looks up audit logs by `class_name`. If a model's audits should be queried under a different name (e.g. an STI base class), define `audit_class_name`:

```ruby
class Post < ActiveRecord::Base
  def self.audit_class_name
    "Article"
  end
end
```

This only affects the `RecordAuditScreen` query — the `class_name` written to each `AuditLog` row is always the record's actual class.

## Action Log

A lightweight APM that records every HTTP request with performance breakdown. Subscribes to `ActiveSupport::Notifications` — no middleware or monkey-patching. Enabled by default; disable entirely with:

```ruby
WulinAudit.action_log_enabled = false
```

Each request writes one `WulinAudit::ActionLog` row:

| Column | Description |
|---|---|
| `request_id` | Rails `X-Request-Id` header / auto-generated UUID |
| `user_id` | `User.current_user.try(:id)` |
| `user_email` | `User.current_user.try(:email)` |
| `request_ip` | `request.remote_ip` |
| `http_method` | GET / POST / PUT / DELETE / PATCH |
| `path` | Request path |
| `controller` | Controller class name |
| `action` | Action name |
| `params` | Filtered request parameters (JSONB) |
| `status` | HTTP response code |
| `duration` | Total request duration in ms |
| `allocations` | Object allocations (Rails 5.2+) |
| `exception` | Exception class + message, if any |
| `spans` | Performance breakdown by type (JSONB) |

The `spans` column stores an aggregate hash:

```json
{"db": {"count": 5, "duration": 4.33}, "view": {"count": 2, "duration": 6.78}}
```

`WulinAudit::ActionLog` derives `db_duration` and `view_duration` from `spans`, and `action_duration` as the remainder of `duration` — no extra columns needed.

Writes happen asynchronously on a background thread pool. INSERTs are silenced from the Rails log.

### Param Filtering

`params` are passed through `ActiveSupport::ParameterFilter` using your app's `config.filter_parameters` — the same rules Rails applies to its own logs, so passwords and other sensitive keys are redacted. If the filtered payload's JSON serialization exceeds 512 bytes, it's truncated to a plain string.

### Excluding Controllers

By default all controllers are logged. To opt out, use `reject_action_log`:

```ruby
class HealthChecksController < ApplicationController
  reject_action_log
end
```

WulinAudit's own controllers are excluded by default.

## WulinMaster Integration

If [WulinMaster](https://github.com/ekohe/wulin_master) is loaded, WulinAudit automatically:

- Adds an **Audit** toolbar action to grids, gated on a `record_audit#read` permission — create that permission yourself, it isn't seeded by this gem
- Provides `AuditLogScreen` at `/wulin_audit/audit_logs` for browsing all audit logs
- Provides `RecordAuditScreen` at `/wulin_audit/record_audits` for per-record audit history
- Provides `ActionLogScreen` at `/wulin_audit/action_logs` for browsing all action logs, gated on `action_log#read`/`action_log#cud` permissions seeded automatically by migration (if your app defines a `Permission` model)
- Adds an **Audit Logs** toolbar action to `ActionLogGrid`: select one or more rows and it opens a modal with the `AuditLogScreen` grid filtered to those requests' `request_id`s
- Adds an **Export** action to `ActionLogGrid` when the `WulinExcel` gem is installed; `AuditLogGrid` always exposes **Export**

None of this JS is auto-loaded — add both to your host app's asset manifest:

```
//= require audit
//= require actions/show_audit_logs
```

None of these screens appear in your app's navigation automatically either — add them to your menu-defining controller:

```ruby
submenu :settings do
  item AuditLogScreen, icon: :history
  item ActionLogScreen, icon: :assignment
end
```

## InfluxDB Integration (Optional)

To also push audit events to InfluxDB, configure in your `APP_CONFIG`:

```yaml
wulin_audit:
  influxdb:
    host: localhost
    port: 8086
    database: audit
```

To backfill existing logs into InfluxDB:

```shell
rails wulin_audit:load_audit_in_influxdb
```

## Contributing

Jimmy, Xuhao, Maxime Guilbot, Sarah Wang, and Mel Cao from [Ekohe](https://ekohe.com).

## License

WulinAudit is released under the MIT license.
