# == Schema Information
#
# Table name: backup_runs
# Database name: primary
#
#  id                   :integer          not null, primary key
#  error_message        :text
#  file_key             :string
#  finished_at          :datetime
#  progress_bytes       :bigint
#  progress_detail      :string
#  progress_rate_bps    :bigint
#  progress_total_bytes :bigint
#  size_bytes           :bigint
#  source_size_bytes    :bigint
#  stage_started_at     :datetime
#  started_at           :datetime
#  status               :string
#  trigger              :string           default("scheduled"), not null
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  backup_routine_id    :integer          not null
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

  # Live UI: any change (status transitions, size, error) re-renders the
  # subscribed self-refreshing components. Runs in the jobs process; Solid
  # Cable carries it to browser sessions.
  after_update_commit :broadcast_refresh

  before_save -> { self.stage_started_at = Time.current }, if: :status_changed?

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

  def stage_elapsed
    return unless in_progress?

    Time.current - (stage_started_at || started_at || created_at)
  end

  # Live KPIs while dumping/uploading. Saving broadcasts the refresh, so
  # callers throttle how often they invoke this.
  def progress!(bytes:, rate_bps: nil, detail: nil, total_bytes: nil)
    update!(
      progress_bytes: bytes,
      progress_rate_bps: rate_bps,
      progress_detail: detail&.first(255),
      progress_total_bytes: total_bytes || progress_total_bytes
    )
  end

  # @return [Integer, nil] 0..100 when the total is known (upload stage)
  def progress_percent
    return unless progress_bytes && progress_total_bytes&.positive?

    [ (progress_bytes * 100 / progress_total_bytes), 100 ].min
  end

  def download_url
    return unless completed? && file_key.present?

    destination.adapter.download_url(file_key)
  end

  # Single live-updates channel per run. Pages subscribe to it OUTSIDE any
  # element that gets replaced, so a broadcast can never race a re-subscribe.
  def updates_channel
    [ self, :run_updates ]
  end

  private

  def broadcast_refresh
    BackupRuns::RowComponent.new(run: self).broadcast_refresh!
    BackupRuns::DetailComponent.new(run: self).broadcast_refresh!
  end
end
