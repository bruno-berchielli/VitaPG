# Hourly dead-man's switch sweep over every enabled routine.
class CheckMissedRunsJob < ApplicationJob
  queue_as :backups

  def perform
    BackupRoutine.enabled.find_each do |routine|
      Backups::MissedRunChecker.call(routine)
    rescue => e
      Rails.error.report(e, context: { backup_routine_id: routine.id }, source: "backups")
    end
  end
end
