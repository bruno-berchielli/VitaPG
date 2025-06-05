# == Schema Information
#
# Table name: backup_logs
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
  belongs_to :backup_run

  enum :status, {
    success: "success",
    failure: "failure"
  }

  validates :status, presence: true
end
