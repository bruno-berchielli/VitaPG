class AddColumnsToIgnoreToBackupRoutines < ActiveRecord::Migration[8.0]
  def change
    add_column :backup_routines, :tables_to_exclude, :text
    add_column :backup_routines, :tables_to_exclude_data, :text
    add_column :backup_routines, :no_owner, :boolean, default: false, null: false
    add_column :backup_routines, :no_privileges, :boolean, default: false, null: false
  end
end
