class AddMissedRunAlertToBackupRoutines < ActiveRecord::Migration[8.1]
  def change
    add_column :backup_routines, :last_missed_alert_at, :datetime
  end
end
