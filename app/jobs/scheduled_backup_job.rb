# Entry point for Solid Queue recurring tasks (one per enabled routine).
class ScheduledBackupJob < ApplicationJob
  queue_as :backups

  def perform(backup_routine_id)
    routine = BackupRoutine.find_by(id: backup_routine_id)
    return unless routine&.enabled?
    return if routine.running?

    run = routine.runs.create!(status: :pending, trigger: :scheduled)
    Backups::Runner.call(run)
  end
end
