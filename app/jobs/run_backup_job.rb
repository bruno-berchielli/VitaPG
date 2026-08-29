class RunBackupJob < ApplicationJob
  queue_as :backups

  # Safe to retry: Backups::Runner only executes runs still in pending.
  retry_on Errno::ECONNRESET, Seahorse::Client::NetworkingError, wait: :polynomially_longer, attempts: 3

  def perform(backup_run_id)
    run = BackupRun.find_by(id: backup_run_id)
    return unless run

    Backups::Runner.call(run)
  end
end
