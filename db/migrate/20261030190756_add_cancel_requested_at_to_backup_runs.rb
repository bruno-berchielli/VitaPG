class AddCancelRequestedAtToBackupRuns < ActiveRecord::Migration[8.1]
  def change
    add_column :backup_runs, :cancel_requested_at, :datetime
  end
end
