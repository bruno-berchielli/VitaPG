class BackupRunMailer < ApplicationMailer
  def finished(channel, run)
    @run = run
    @routine = run.backup_routine

    subject_key = run.completed? ? "completed" : "failed"

    mail(
      to: channel.recipient_list,
      subject: t("backup_run_mailer.finished.subject_#{subject_key}", routine: @routine.name)
    )
  end
end
