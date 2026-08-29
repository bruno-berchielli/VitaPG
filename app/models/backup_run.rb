# == Schema Information
#
# Table name: backup_runs
# Database name: primary
#
#  id                :integer          not null, primary key
#  error_message     :text
#  file_key          :string
#  finished_at       :datetime
#  size_bytes        :bigint
#  started_at        :datetime
#  status            :string
#  trigger           :string           default("scheduled"), not null
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
  has_one :workspace, through: :backup_routine
  has_many :logs, class_name: "BackupLog", dependent: :destroy

  enum :status, {
    pending: "pending",
    dumping: "dumping",
    uploading: "uploading",
    completed: "completed",
    failed: "failed",
    pruned: "pruned"
  }, default: :pending

  enum :trigger, { scheduled: "scheduled", manual: "manual" }, prefix: true

  scope :in_progress, -> { where(status: %i[pending dumping uploading]) }
  scope :finished, -> { where(status: %i[completed failed]) }
  scope :prunable, -> { completed.where.not(file_key: nil) }

  def in_progress?
    pending? || dumping? || uploading?
  end

  def duration
    return unless started_at

    (finished_at || Time.current) - started_at
  end

  def log!(message:, status: :info)
    logs.create!(message:, status:)
  end

  def download_url
    return unless completed? && file_key.present?

    destination.adapter.download_url(file_key)
  end
end
