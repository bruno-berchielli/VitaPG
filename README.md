# VitaPG

**Open-source, self-hosted PostgreSQL backup platform.** Install it on a server, connect your databases, and get scheduled, compressed, verified backups shipped to your own storage — with a real dashboard, live run logs, retention policies, notifications, and team workspaces. MIT licensed.

VitaPG does one thing: PostgreSQL backups. That focus is the feature.

## Highlights

- **Scheduled backup routines** — standard cron expressions with per-routine timezones, powered by Solid Queue (persistent, survives restarts, no Redis).
- **Efficient dumps** — `pg_dump` custom format with configurable compression (0–9), plain SQL, or directory format with parallel jobs for large databases. Table and data exclusions, `--no-owner`, `--no-privileges`.
- **Bring your own storage** — Amazon S3 and every S3-compatible service (MinIO, Cloudflare R2, Backblaze B2, Wasabi, DigitalOcean Spaces…), with streaming multipart uploads.
- **Verified, never trusted** — after upload, every backup is re-checked against the remote object before being marked completed.
- **Retention that can't hurt you** — keep-last-N and/or max-age pruning that only ever deletes files VitaPG itself created. Nothing in the app can write to or delete from your source databases; nothing can touch objects it didn't create.
- **Size anomaly detection** — a backup that suddenly shrinks or balloons relative to its recent history gets flagged, because a small dump usually means a big problem.
- **Live dashboard** — run status and logs stream to the browser in real time (Hotwire + Solid Cable). Failures are front and center.
- **Notifications** — email, Slack/Discord/Mattermost, and HMAC-signed webhooks. Failures notify by default.
- **Workspaces & members** — group databases, destinations and routines per team; invite members with owner/admin/member roles.
- **Security by default** — all credentials (database passwords, storage keys, webhook URLs) encrypted at rest with Active Record Encryption; secrets are write-only in the UI and never appear in logs, process lists, or URLs.
- **Trilingual** — English, Português (Brasil), Español.

## Technology

Boring on purpose: Ruby on Rails 8.1, Ruby 4.0, SQLite for the app's own data (zero external services to operate), Solid Queue / Solid Cache / Solid Cable, Hotwire, ViewComponent, Tailwind 4. The only databases VitaPG connects to besides its own SQLite files are the PostgreSQL servers you back up.

## Requirements

- Ruby (see `.ruby-version`) and Node.js (see `.node-version`) for source installs — or just Docker.
- PostgreSQL client tools (`pg_dump`, `psql`) on the host. Already included in the Docker image.

## Quick start (Docker)

```bash
docker build -t vitapg .
docker volume create vitapg-storage
docker run -d --name vitapg -p 80:80 \
  -e SECRET_KEY_BASE=$(openssl rand -hex 64) \
  -e APP_HOST=backups.example.com \
  -v vitapg-storage:/rails/storage \
  vitapg
```

Open the app, create the first account and workspace, and start adding routines. The `storage/` volume holds the SQLite databases — that's the whole persistence story.

> `SECRET_KEY_BASE` also derives the credential-encryption keys. Keep it stable and secret; rotating it invalidates stored credentials (see `.env.example` for independent encryption keys).

## Development install

```bash
git clone https://github.com/bruno-berchielli/VitaPG.git
cd VitaPG
bin/setup            # bundle + yarn + db:prepare
bin/dev              # web + js/css watchers + jobs (procman TUI; picks the first free port from 3000)
```

Visit `http://localhost:3000`, sign up, create a workspace.

To try a full backup locally without touching real infrastructure:

```bash
docker run -d --rm --name pg -e POSTGRES_PASSWORD=test -p 55432:5432 postgres:17-alpine
docker run -d --rm --name minio -e MINIO_ROOT_USER=minioadmin -e MINIO_ROOT_PASSWORD=minioadmin \
  -p 59000:9000 quay.io/minio/minio server /data
```

Add a connection to `localhost:55432`, an S3-compatible destination pointing at `http://localhost:59000` (create the bucket first), a routine, and hit **Run now**.

## Production notes

- **Deploy** — a Kamal config ships in `config/deploy.yml`; any Docker host works. One container runs web + jobs (see `Procfile` semantics in `bin/thrust`/`bin/jobs`); scale job concurrency with `JOB_CONCURRENCY`.
- **Email** — set the `SMTP_*` variables (see `.env.example`) to enable password resets and email notifications.
- **Job dashboard** — `/jobs` (Mission Control) requires a signed-in user.
- **Sign-ups** — the first account bootstraps the instance; after that, public registration closes and people join via **Members** invitations. Set `VITAPG_OPEN_SIGNUPS=1` to keep it open.
- **Database permissions** — back up with a dedicated read-only role. VitaPG only ever runs `pg_dump` and `SELECT 1` against your servers.
- **Storage permissions** — scope credentials to the bucket, with put/get/delete-object rights only (no bucket deletion needed).

## Webhook signature

Signed webhooks send `X-Vitapg-Signature: t=<unix>,v1=<hex>` where `v1 = HMAC-SHA256(signing_secret, "#{t}.#{raw_body}")`. The signing secret is shown on the channel's edit screen.

## Testing

```bash
bin/rails test          # unit
bin/rails test:system   # browser (headless Chrome)
bin/rubocop
```

## Contributing

Issues and pull requests are welcome. Keep it boring: Rails conventions, tests with every change, English everywhere, all UI text through I18n (en, pt-BR, es).

## License

MIT — see `MIT-LICENSE`. Created by [Bruno Berchielli](https://github.com/bruno-berchielli).
