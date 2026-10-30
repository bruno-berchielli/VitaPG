# frozen_string_literal: true

module Backups
  # Cleans up after runs whose worker died without unwinding (SIGKILL, OOM,
  # reboot). Runner's own error handling never ran for those, so the run would
  # stay in progress forever and block every later run of its routine, its
  # work directory would keep its partial dump, and an upload could stay open.
  #
  # A live run bumps updated_at every few seconds while dumping or uploading
  # (BackupRun#progress!), so silence past STALE_AFTER means nobody is on it.
  class InterruptedRunSweeper < ApplicationService
    STALE_AFTER = 1.hour

    def call
      BackupRun.in_progress.where(updated_at: ...STALE_AFTER.ago).find_each { |run| fail_run(run) }
      remove_orphan_workdirs
    end

    private

    def fail_run(run)
      abort_upload(run) if run.uploading?

      message = "Interrupted: no activity for over #{STALE_AFTER.inspect}, the worker stopped mid-run"
      run.update!(status: :failed, finished_at: Time.current, error_message: message)
      run.log!(message: message, status: :error)
      Notifications::Dispatcher.call(run)
    rescue => e
      Rails.error.report(e, context: { backup_run_id: run.id }, source: "backups")
    end

    def abort_upload(run)
      run.destination.adapter.abort_incomplete_uploads!(run.storage_key_stem)
    rescue => e
      Rails.error.report(e, context: { backup_run_id: run.id }, source: "backups")
    end

    # Runner works inside Dir.mktmpdir("vitapg-run-<id>-"), which only a hard
    # kill leaves behind.
    def remove_orphan_workdirs
      live = BackupRun.in_progress.pluck(:id).to_set

      Dir.glob(File.join(Dir.tmpdir, "vitapg-run-*")).each do |dir|
        id = dir[/vitapg-run-(\d+)-/, 1]
        next if id.nil? || live.include?(id.to_i)

        FileUtils.rm_rf(dir)
      end
    end
  end
end
