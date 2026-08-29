class NotifyRunJob < ApplicationJob
  queue_as :notifications

  retry_on StandardError, wait: :polynomially_longer, attempts: 5

  def perform(channel_id, run_id)
    channel = NotificationChannel.find_by(id: channel_id)
    run = BackupRun.find_by(id: run_id)
    return unless channel&.enabled? && run

    case channel.kind
    when "webhook" then Notifications::WebhookNotifier.call(channel, run)
    when "slack" then Notifications::SlackNotifier.call(channel, run)
    when "email" then BackupRunMailer.finished(channel, run).deliver_now
    end
  end
end
