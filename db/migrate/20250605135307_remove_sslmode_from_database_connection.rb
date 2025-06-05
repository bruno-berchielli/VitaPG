class RemoveSslmodeFromDatabaseConnection < ActiveRecord::Migration[8.0]
  def change
    remove_column :database_connections, :sslmode, :string, if_exists: true
  end
end
