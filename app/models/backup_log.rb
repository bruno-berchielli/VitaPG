# == Schema Information
#
# Table name: backup_logs
# Database name: primary
#
#  id            :integer          not null, primary key
#  message       :json
#  status        :string
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  backup_run_id :integer          not null
#
# Indexes
#
#  index_backup_logs_on_backup_run_id  (backup_run_id)
#
# Foreign Keys
#
#  backup_run_id  (backup_run_id => backup_runs.id)
#
class BackupLog < ApplicationRecord
  after_save :print_to_rails_log
  after_create_commit :broadcast_line

  belongs_to :backup_run, inverse_of: :logs

  enum :status, {
    info: "info",
    warning: "warning",
    error: "error"
  }

  validates :status, presence: true

  private

  def print_to_rails_log
    level = status == "warning" ? "warn" : status
    Rails.logger.send(level, "[BackupLog] #{message}")
  end

  def broadcast_line
    BackupRuns::LogListComponent.broadcast_line!(self)
  end
end
