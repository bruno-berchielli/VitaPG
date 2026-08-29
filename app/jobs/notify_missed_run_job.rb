class NotifyMissedRunJob < ApplicationJob
  queue_as :notifications

  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(channel_id, routine_id, expected_at_iso)
    channel = NotificationChannel.find_by(id: channel_id)
    routine = BackupRoutine.find_by(id: routine_id)
    return unless channel&.enabled? && routine

    case channel.kind
    when "webhook" then Notifications::MissedRunWebhookNotifier.call(channel, routine, expected_at_iso)
    when "slack" then Notifications::MissedRunSlackNotifier.call(channel, routine, expected_at_iso)
    when "email" then BackupRunMailer.missed(channel, routine, expected_at_iso).deliver_now
    end
  end
end
