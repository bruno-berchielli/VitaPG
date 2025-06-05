class CreateBackupLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :backup_logs do |t|
      t.references :backup_routine, null: false, foreign_key: true
      t.string :status
      t.text :message
      t.string :file_url

      t.timestamps
    end
  end
end
