# frozen_string_literal: true

module Backups
  # Orchestrates one backup run: dump -> upload -> verify -> retention.
  # Each step advances the run's status and appends structured logs, so the
  # dashboard can follow along live.
  class Runner < ApplicationService
    attr_reader :run, :routine

    def initialize(run)
      @run = run
      @routine = run.backup_routine
    end

    def call
      return false unless claim_run!

      Dir.mktmpdir("vitapg-run-#{run.id}-") do |workdir|
        artifact = dump!(workdir)
        upload!(artifact)
      end

      complete!
      after_finish_housekeeping
      true
    rescue => e
      fail!(e)
      notify
      false
    end

    private

    # Moving pending -> dumping atomically is the concurrency guard: a routine
    # never has two live runs, and a retried job never re-executes a finished run.
    def claim_run!
      unless run.pending?
        run.log!(message: "Run is #{run.status}, nothing to do", status: :warning)
        return false
      end

      if routine.runs.in_progress.where.not(id: run.id).exists?
        run.update!(status: :failed, finished_at: Time.current,
                    error_message: "Another run of this routine is already in progress")
        run.log!(message: "Skipped: another run is already in progress", status: :error)
        return false
      end

      run.update!(status: :dumping, started_at: Time.current)
      run.log!(message: "Backup run started (#{run.trigger})")
      true
    end

    def dump!(workdir)
      artifact = DumpExecutor.call(run, workdir: workdir)
      run.log!(message: "Dump finished (#{ActiveSupport::NumberHelper.number_to_human_size(artifact.size_bytes)})")
      artifact
    end

    def upload!(artifact)
      run.update!(status: :uploading)
      key = object_key(artifact)
      adapter = routine.destination.adapter

      run.log!(message: "Uploading to #{routine.destination.name} as #{key}")
      adapter.upload!(artifact.path, key)

      verify!(adapter, key, artifact.size_bytes)
      run.update!(file_key: key, size_bytes: artifact.size_bytes)
    end

    def verify!(adapter, key, expected_size)
      remote_size = adapter.head_size(key)

      if remote_size.nil?
        raise Backups::Error, "Verification failed: uploaded object not found"
      elsif remote_size != expected_size
        raise Backups::Error, "Verification failed: remote size #{remote_size} != local size #{expected_size}"
      end

      run.log!(message: "Upload verified (remote size matches)")
    end

    def complete!
      run.update!(status: :completed, finished_at: Time.current)
      run.log!(message: "Backup completed in #{run.duration.round}s")
    end

    def fail!(error)
      run.update!(status: :failed, finished_at: Time.current, error_message: error.message.to_s.first(5000))
      run.log!(message: "Backup failed: #{error.message.to_s.first(2000)}", status: :error)
      Rails.error.report(error, context: { backup_run_id: run.id }, source: "backups")
    end

    # Post-success work is best-effort: problems here must never mark a
    # successful backup as failed.
    def after_finish_housekeeping
      safely("Anomaly check") { AnomalyChecker.call(run) }
      safely("Retention pruning") { RetentionPruner.call(routine) }
      notify
    end

    def notify
      safely("Notification dispatch") { Notifications::Dispatcher.call(run) }
    end

    def safely(label)
      yield
    rescue => e
      run.log!(message: "#{label} failed: #{e.message}", status: :warning)
      Rails.error.report(e, context: { backup_run_id: run.id }, source: "backups")
    end

    def object_key(artifact)
      prefix = routine.path_prefix.presence || "#{routine.workspace.slug}/#{routine.name.parameterize}"
      timestamp = run.started_at.utc.strftime("%Y-%m-%dT%H-%M-%S")
      extension = File.basename(artifact.path).sub(/\Adump/, "")

      "#{prefix.chomp("/")}/#{routine.database_connection.database_name}-#{timestamp}#{extension}"
    end
  end
end
