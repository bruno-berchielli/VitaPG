class CreateBackupRoutines < ActiveRecord::Migration[8.0]
  def change
    create_table :backup_routines do |t|
      t.string :name
      t.string :frequency
      t.references :database_connection, null: false, foreign_key: true
      t.references :destination, null: false, foreign_key: true

      t.timestamps
    end
  end
end
