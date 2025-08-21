# == Schema Information
#
# Table name: backup_routines
#
#  id                     :integer          not null, primary key
#  cron                   :string           default("0 0 * * *"), not null
#  enabled                :boolean          default(TRUE), not null
#  name                   :string
#  no_owner               :boolean          default(FALSE), not null
#  no_privileges          :boolean          default(FALSE), not null
#  tables_to_exclude      :text
#  tables_to_exclude_data :text
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  database_connection_id :integer          not null
#  destination_id         :integer          not null
#
# Indexes
#
#  index_backup_routines_on_database_connection_id  (database_connection_id)
#  index_backup_routines_on_destination_id          (destination_id)
#
# Foreign Keys
#
#  database_connection_id  (database_connection_id => database_connections.id)
#  destination_id          (destination_id => destinations.id)
#
class BackupRoutine < ApplicationRecord
  after_commit :sync_solid_queue_task, on: %i[create update]
  after_destroy :remove_solid_queue_task

  belongs_to :database_connection
  belongs_to :destination

  has_many :runs, class_name: "BackupRun", dependent: :destroy

  validates :name, :cron, presence: true

  def sync_solid_queue_task
    remove_solid_queue_task

    SolidQueue.create_recurring_task(
      solid_queue_key,
      class_name: "RunBackupJob",
      arguments: [id],
      schedule: cron
    )
  end

  def remove_solid_queue_task
    SolidQueue.destroy_recurring_task(remove_solid_queue_task) rescue nil
  end

  def run!
    BackupRunnerService.call(self)
  end

  private

  def solid_queue_key
    "backup_routine_id_#{id}_#{name}"
  end
end
