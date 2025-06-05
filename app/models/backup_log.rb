# == Schema Information
#
# Table name: backup_logs
#
#  id                :integer          not null, primary key
#  file_url          :string
#  message           :text
#  status            :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  backup_routine_id :integer          not null
#
# Indexes
#
#  index_backup_logs_on_backup_routine_id  (backup_routine_id)
#
# Foreign Keys
#
#  backup_routine_id  (backup_routine_id => backup_routines.id)
#
class BackupLog < ApplicationRecord
  belongs_to :backup_routine

  enum :status, {
    success: "success",
    failure: "failure"
  }

  validates :status, presence: true
end
