# == Schema Information
#
# Table name: backup_runs
#
#  id                :integer          not null, primary key
#  file_url          :string
#  finished_at       :datetime
#  started_at        :datetime
#  status            :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  backup_routine_id :integer          not null
#
# Indexes
#
#  index_backup_runs_on_backup_routine_id  (backup_routine_id)
#
# Foreign Keys
#
#  backup_routine_id  (backup_routine_id => backup_routines.id)
#
class BackupRun < ApplicationRecord
  belongs_to :backup_routine

  has_one :destination, through: :backup_routine
  has_many :logs, class_name: "BackupLog", dependent: :destroy

  enum :status, {
    running: "running",
    completed: "completed",
    failed: "failed",
    cancelled: "cancelled",
  }

  def log!(message:, status:)
    logs.create!(message:, status:)
  end

  def delete_remote_file!
    raise "No file URL to delete" unless file_url.present?

    if Storage::DeleteService.call(destination, file_url)
      update!(file_url: nil)
      log!(message: "Remote backup deleted from #{destination.name}", status: :info)
    else
      log!(message: "Failed to delete remote backup from #{destination.name}", status: :error)
      raise "Failed to delete remote backup"
    end
  end
end
