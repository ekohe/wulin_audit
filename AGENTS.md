# AGENTS.md

`wulin_audit` is a Rails engine, never run standalone — it's always loaded into a host app alongside [`wulin_master`](https://github.com/ekohe/wulin_master). This file is for agents working in a host app that consumes this gem. If you're developing the gem itself, see `CONTRIBUTING.md`.

## Wiring it into a host app

- Gemfile + `rails db:migrate` — full steps in the README's Installation section.
- The host app must implement `User.current_user` returning an object that responds to `id`, `email`, `ip`.
- None of the WulinMaster JS or screens auto-load. The host app must add explicit `//= require audit` / `//= require actions/show_audit_logs` lines to its asset manifest, and `item AuditLogScreen`/`item ActionLogScreen` lines to its menu-defining controller — see the README's "WulinMaster Integration" section for both snippets.
- The **Audit** grid toolbar action is gated on a `record_audit#read` permission that the host app must create itself — this gem does not seed it.
- `ActionLogScreen` is gated on `action_log#read`/`action_log#cud` permissions, which ARE seeded automatically by this gem's migration, but only if the host app already defines a `Permission` model.
- The Action Log APM (per-request performance rows) is on by default; disable it host-app-wide with `WulinAudit.action_log_enabled = false`.

## Gotchas

- Nothing in this gem loads on a page just because it's installed — the host app's own asset manifest must explicitly require the JS (line above), regardless of what asset pipeline it uses.
- Defining a screen in this gem doesn't add it to a host app's navigation — each host app needs its own `item` line even after migrating and requiring the JS.
- `RecordAuditScreen` filters by `class_name`. A model can redirect that lookup with `self.audit_class_name`, but the `class_name` actually written to `AuditLog` rows is always the record's real class name — the override only affects the screen's query, not what's stored.

## Verifying integration behavior

Claims about grid actions, permissions, or asset loading can be wrong if inferred from this repo alone — this gem's `app/grid`, `app/screens`, and `app/controllers` are only half the picture; the other half is whatever the host app's manifest, menu, and permission seeds actually do.

Before trusting an assumption about WulinMaster/host-app behavior, check it against a local checkout if one is available:
- `wulin_master` — the actual grid/screen/action engine
- a host app that vendors this gem (e.g. via `Gemfile` `path:`/git submodule) — grep its asset manifest (`app/assets/javascripts/application.js`) for how it actually requires this gem's JS
