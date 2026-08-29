# Daily sweep so age-based retention applies even to routines that stopped
# running (per-run pruning only fires after successful backups).
class PruneBackupsJob < ApplicationJob
  queue_as :backups

  def perform
    BackupRoutine.find_each do |routine|
      Backups::RetentionPruner.call(routine)
    rescue => e
      Rails.error.report(e, context: { backup_routine_id: routine.id }, source: "backups")
    end
  end
end
