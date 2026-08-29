# == Schema Information
#
# Table name: backup_routines
# Database name: primary
#
#  id                     :integer          not null, primary key
#  compression_level      :integer          default(6), not null
#  cron                   :string           default("0 0 * * *"), not null
#  enabled                :boolean          default(TRUE), not null
#  format                 :string           default("custom"), not null
#  name                   :string
#  no_owner               :boolean          default(FALSE), not null
#  no_privileges          :boolean          default(FALSE), not null
#  parallel_jobs          :integer          default(1), not null
#  path_prefix            :string
#  retention_keep_last    :integer
#  retention_max_age_days :integer
#  schedule_timezone      :string           default("UTC"), not null
#  tables_to_exclude      :text
#  tables_to_exclude_data :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  database_connection_id :integer          not null
#  destination_id         :integer          not null
#  workspace_id           :integer          not null
#
# Indexes
#
#  index_backup_routines_on_database_connection_id  (database_connection_id)
#  index_backup_routines_on_destination_id          (destination_id)
#  index_backup_routines_on_workspace_id            (workspace_id)
#
# Foreign Keys
#
#  database_connection_id  (database_connection_id => database_connections.id)
#  destination_id          (destination_id => destinations.id)
#  workspace_id            (workspace_id => workspaces.id)
#
class BackupRoutine < ApplicationRecord
  FORMATS = %w[custom plain directory].freeze

  belongs_to :workspace
  belongs_to :database_connection
  belongs_to :destination

  has_many :runs, class_name: "BackupRun", dependent: :destroy

  after_commit :sync_solid_queue_task, on: %i[create update]
  after_destroy :remove_solid_queue_task

  validates :name, presence: true
  validates :cron, presence: true
  validates :format, inclusion: { in: FORMATS }
  validates :compression_level, numericality: { only_integer: true, in: 0..9 }
  validates :parallel_jobs, numericality: { only_integer: true, in: 1..16 }
  validates :retention_keep_last, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :retention_max_age_days, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true
  validates :schedule_timezone, inclusion: { in: ActiveSupport::TimeZone::MAPPING.values.uniq + [ "UTC" ] }
  validate :cron_must_parse

  scope :enabled, -> { where(enabled: true) }

  def run_later!(trigger: :manual)
    run = runs.create!(status: :pending, trigger: trigger)
    RunBackupJob.perform_later(run.id)
    run
  end

  def running?
    runs.in_progress.exists?
  end

  def next_run_at
    return unless enabled?

    Fugit.parse_cron(cron)&.next_time(Time.current)&.to_t
  end

  def last_run
    runs.order(created_at: :desc).first
  end

  def sync_solid_queue_task
    remove_solid_queue_task

    return unless enabled?

    SolidQueue::RecurringTask.create_dynamic_task(
      solid_queue_key,
      class: "ScheduledBackupJob",
      args: [ id ],
      schedule: cron_with_timezone
    )
  end

  def remove_solid_queue_task
    SolidQueue::RecurringTask.dynamic.find_by(key: solid_queue_key)&.destroy
  end

  private

  def solid_queue_key
    "backup_routine_#{id}"
  end

  # Fugit supports an embedded timezone in the cron string, which is how the
  # per-routine timezone reaches Solid Queue's scheduler.
  def cron_with_timezone
    schedule_timezone == "UTC" ? cron : "#{cron} #{schedule_timezone}"
  end

  def cron_must_parse
    return if cron.blank?

    errors.add(:cron, :invalid) unless Fugit.parse_cron(cron_with_timezone)
  end
end
