class CreateDatabaseConnections < ActiveRecord::Migration[8.0]
  def change
    create_table :database_connections do |t|
      t.string :name
      t.string :host
      t.integer :port
      t.string :username
      t.string :password
      t.string :database_name
      t.string :sslmode

      t.timestamps
    end
  end
end
