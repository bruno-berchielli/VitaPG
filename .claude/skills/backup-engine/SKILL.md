---
name: backup-engine
description: Rules and architecture for VitaPG's backup pipeline (pg_dump execution, compression, streaming uploads, retention, scheduling). Load before touching app/services, app/jobs, or anything that talks to source databases or destinations.
---

# Backup Engine

## Safety invariants (non-negotiable)

1. **Read-only against sources.** The only binaries ever executed against a source database are `pg_dump` and `psql` with read-only statements (version check, size estimate). Connection test uses `SELECT 1`. Never `pg_restore --clean`, never DDL/DML against sources.
2. **Additive against destinations.** Uploads create new objects under the routine's prefix. Deletion happens ONLY through retention pruning and ONLY for object keys stored in `backup_runs.file_key` belonging to that routine. Never list-and-delete by prefix.
3. **Credentials never leak.** Pass `PGPASSWORD` via the spawned process env (`Open3` env hash — never `ENV[]=`, it leaks across threads), never in argv (visible in `ps`), never logged. Log commands with credentials redacted. Job arguments carry record IDs only, never credentials.
4. **Idempotent jobs.** Every job can be retried safely. Partial artifacts (tmp files, incomplete multipart uploads) are cleaned up in `ensure` blocks and by a janitor job.

## Pipeline architecture

`RunBackupJob` → `Backups::Runner` orchestrates steps, each step logs to `BackupLog` and advances `BackupRun#status` (state machine: `pending → dumping → uploading → completed | failed`). Status changes broadcast via Turbo Streams for live UI.

- **Dump**: `pg_dump --format=custom --compress=<level>` streamed to a tmp file in `Dir.mktmpdir`; for large DBs, directory format + `--jobs=N` enables parallel dump. Capture stderr for logs. Record dump duration and byte size on the run.
- **Upload**: adapter pattern in `app/services/storage/` (one adapter per provider, common interface: `upload!(io_or_path, key)`, `delete!(key)`, `download_url(key)`, `verify!`). S3 family uses managed multipart upload with configurable part size; stream from disk, never load whole file into memory.
- **Verify**: after upload, HEAD the object and compare size/checksum before marking completed.
- **Retention**: per-routine policy (keep last N and/or max age days). Pruning selects candidate `BackupRun` records (completed, with file_key), deletes remote object, then marks the run `pruned`. Wrapped so one failed deletion doesn't abort the batch.
- **Scheduling**: routines sync to Solid Queue recurring tasks (`SolidQueue.create_recurring_task`) on save; disabling/destroying a routine removes its task. Cron is validated with `Fugit` before save. Timezone-aware.

## Efficiency requirements

- Streaming end-to-end; memory ceiling independent of database size.
- Compression configurable per routine (pg_dump built-in zstd/gzip levels).
- Concurrent runs across routines are fine; the same routine never runs concurrently (guard with an active-run check).
- Timeouts on every external call; a wall-clock timeout per run (configurable) marks the run failed and kills the process group.

## Testing

- Unit-test command construction (argv arrays, option mapping) without executing binaries.
- Integration tests run against a Dockerized PostgreSQL (`test/support`) when `INTEGRATION=1`; CI includes at least one real dump+restore-verify cycle against MinIO for S3.
- Every failure path (unreachable host, bad credentials, full disk, upload abort) has a test asserting run status, logs, and cleanup.
