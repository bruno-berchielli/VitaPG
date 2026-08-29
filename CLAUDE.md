# VitaPG — CLAUDE.md

VitaPG is an open-source, self-hosted PostgreSQL backup platform — a direct competitor to SimpleBackups, minus billing. A company installs it on a server and gets robust, reliable, observable backup routines. MIT licensed, a gift to the community.

## Product principles

- **PostgreSQL only.** No other databases, ever. Depth over breadth: SSL modes, dump formats, parallel dumps, compression — first-class.
- **Never destructive to targets.** The app only READS from source databases (`pg_dump`) and only WRITES new files to destinations. Retention pruning deletes only files the app itself created (tracked by `BackupRun`). No feature may drop, truncate, or write to a source database. No feature may delete destination files it did not create.
- **Security is a constant concern.** All credentials (database passwords, storage keys) encrypted at rest with Active Record Encryption. Credentials never appear in logs, job arguments, URLs, or error messages. Secrets are write-only in the UI (masked, re-enter to change). `filter_parameters` covers all secret fields.
- **Self-hosted, no billing.** No payment code. Workspaces + user management exist for team organization, not monetization.

## Boring Rails

This is an absolute "Boring Rails" app. Rails-way always, latest stable everything:

- Ruby 4.0.1, Rails ~> 8.1 (match the versions used in ~/Git/edupass).
- The Solid triad: **Solid Queue** (jobs, incl. recurring backup schedules), **Solid Cache**, **Solid Cable**. All flows must be persistent and resumable — no in-memory state that a restart loses.
- SQLite for the app's own data (zero-dependency install); PostgreSQL is only the backup *target*.
- Hotwire (Turbo + Stimulus). No SPA, no React.
- Minitest + fixtures (default Rails testing).
- Prefer plain Rails constructs (concerns, POROs in `app/services`, jobs) over gems. Every new gem needs a strong justification.

## Frontend

- **ViewComponents + Tailwind 4** — state of the art. Styling lives at the component level; `application.tailwind.css` stays nearly empty (only `@import "tailwindcss"` and theme tokens via `@theme`).
- Components live in `app/components` with sidecar `.html.erb` and optional sidecar `.js` Stimulus controller, auto-registered by the esbuild glob autoload strategy (ported from edupass — see `.claude/skills/`).
- Self-refreshing components pattern (ported from edupass): components subscribe to model updates over Turbo Streams / Solid Cable and re-render themselves. Use it for anything showing live state (run status, logs, dashboards).
- Design: modern, restrained, intentional — no AI-agent mannerisms (no gradient-purple-on-everything, no emoji headers, no glassmorphism-by-default). Dense, legible, product-grade dashboard UI. See `.claude/skills/vitapg-design` for the design system.

## i18n

- Trilingual: **en / pt-BR / es**. English is the source locale.
- Every user-facing string goes through `I18n.t`. No hardcoded UI text — including flash messages, mailers, validation messages, and component templates (use the lazy `t(".key")` form).
- Locale files organized per feature under `config/locales/{en,pt-BR,es}/`.

## Code style

- All code, comments, commit messages, and identifiers in **English**.
- Comments follow **YARD** style when present, but write comments ONLY when strictly necessary — to capture the WHY or the how-it-works one abstraction level above/below what the code shows. NEVER narrate what the code does. Excess comments are long-term damage.
- Rubocop with `rubocop-rails-omakase`. Run `bin/rubocop` before committing.
- Run `bin/rails test` before committing; system tests for critical flows.

## Domain language

- `DatabaseConnection` — a source PostgreSQL database (encrypted credentials).
- `Destination` — a storage target (S3 and S3-compatible, GCS, etc.). Adapter pattern under `app/services/storage/`.
- `BackupRoutine` — the scheduled definition: connection + destination + schedule (cron) + pg_dump options + retention policy.
- `BackupRun` — one execution of a routine, with status, timings, size, file key, and `BackupLog` lines.
- `Workspace` — the tenancy unit. Every domain record belongs to a workspace; users join workspaces through memberships with roles (owner/admin/member). All queries are workspace-scoped via `Current.workspace`.

## Backup engine rules

- Backups must be **efficient, parallelizable, compressible**: stream `pg_dump` output (directory format + `--jobs` for parallel dumps where applicable), compress (zstd/gzip via pg_dump `--compress`), multipart-upload to storage in chunks, never buffer whole dumps in memory.
- Every run step logs to `BackupLog` (structured), and run status transitions broadcast live to the UI.
- Failures are first-class: captured, logged, notified, visible on the dashboard. Jobs are idempotent and safe to retry.
- Retention/pruning must be provably limited to files recorded in `backup_runs` for that routine.

## Skills

Always check the corresponding `.claude/skills/*/SKILL.md` before operating on these topics:

- `vitapg-design` — design system, tokens, anti-AI-slop checklist. Load before any UI work.
- `create-view-component` — sidecar components, Stimulus autoload via esbuild-rails glob, per-component i18n.
- `create-self-refreshing-component` — Turbo Streams live-updating components (async broadcast vs sync render).
- `backup-engine` — safety invariants and pipeline architecture for anything touching sources/destinations.

## Dev workflow

- `bin/dev` runs web + js + css watchers (Procfile.dev, foreman).
- `bin/setup` must always work from a fresh clone.
- Work in feature branches; open PRs against `main` on github.com/bruno-berchielli/VitaPG; merge when green.
- Keep `README.md` install docs accurate — a company must be able to install from scratch by following it.
