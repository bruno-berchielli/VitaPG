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

  def missed(channel, routine, expected_at_iso)
    @routine = routine
    @expected_at = Time.iso8601(expected_at_iso)

    mail(
      to: channel.recipient_list,
      subject: t("backup_run_mailer.missed.subject", routine: routine.name)
    )
  end
end
