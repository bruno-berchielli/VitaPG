class CreateBackupRuns < ActiveRecord::Migration[8.0]
  def change
    remove_columns :backup_logs, :backup_routine_id, :message, :file_url

    create_table :backup_runs do |t|
      t.belongs_to :backup_routine, null: false, foreign_key: true
      t.string :status
      t.string :file_url
      t.datetime :started_at
      t.datetime :finished_at

      t.timestamps
    end

    add_reference :backup_logs, :backup_run, null: false, foreign_key: true
    add_column :backup_logs, :message, :json, default: nil
  end
end
