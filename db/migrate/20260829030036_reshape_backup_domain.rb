class ReshapeBackupDomain < ActiveRecord::Migration[8.1]
  def change
    add_reference :database_connections, :workspace, foreign_key: true
    add_reference :destinations, :workspace, foreign_key: true
    add_reference :backup_routines, :workspace, foreign_key: true

    change_table :backup_routines do |t|
      t.string :schedule_timezone, null: false, default: "UTC"
      t.string :format, null: false, default: "custom"
      t.integer :compression_level, null: false, default: 6
      t.integer :parallel_jobs, null: false, default: 1
      t.integer :retention_keep_last
      t.integer :retention_max_age_days
      t.string :path_prefix
    end

    change_table :backup_runs do |t|
      t.string :file_key
      t.bigint :size_bytes
      t.text :error_message
      t.string :trigger, null: false, default: "scheduled"
      t.remove :file_url, type: :string
    end

    change_table :destinations do |t|
      t.remove :credentials_path, type: :string
      t.remove :project_id, type: :string
    end

    reversible do |dir|
      dir.up do
        if select_value("SELECT COUNT(*) FROM database_connections").to_i.positive? ||
           select_value("SELECT COUNT(*) FROM destinations").to_i.positive?
          workspace_id = insert(<<~SQL.squish)
            INSERT INTO workspaces (name, slug, created_at, updated_at)
            VALUES ('Default', 'default', datetime('now'), datetime('now'))
          SQL

          %w[database_connections destinations backup_routines].each do |table|
            execute("UPDATE #{table} SET workspace_id = #{workspace_id}")
          end
        end
      end
    end

    change_column_null :database_connections, :workspace_id, false
    change_column_null :destinations, :workspace_id, false
    change_column_null :backup_routines, :workspace_id, false
  end
end
