class RedesignBackupRoutineForDynamicScheduling < ActiveRecord::Migration[8.0]
  def change
    remove_column :backup_routines, :run_at, :time
    remove_column :backup_routines, :frequency, :string

    add_column :backup_routines, :cron, :string, null: false, default: "0 0 * * *" # daily at midnight
    add_column :backup_routines, :enabled, :boolean, null: false, default: true
  end
end
