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

## WulinMaster Integration

If [WulinMaster](https://github.com/ekohe/wulin_master) is loaded, WulinAudit automatically:

- Adds an **Audit** toolbar action to grids (requires `record_audit#read` permission)
- Provides `AuditLogScreen` at `/wulin_audit/audit_logs` for browsing all audit logs
- Provides `RecordAuditScreen` at `/wulin_audit/record_audits` for per-record audit history

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

Jimmy, Xuhao, and Maxime Guilbot from [Ekohe](https://ekohe.com).

## License

WulinAudit is released under the MIT license.
