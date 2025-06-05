class RunBackupJob < ApplicationJob
  queue_as :default

  def perform(backup_routine_id)
    routine = BackupRoutine.find_by(id: backup_routine_id)
    return unless routine&.enabled?

    routine.run!
  end
end
