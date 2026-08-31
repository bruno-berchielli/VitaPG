class AddSshTunnelToDatabaseConnections < ActiveRecord::Migration[8.1]
  def change
    change_table :database_connections, bulk: true do |t|
      t.string :connection_mode, null: false, default: "direct"
      t.string :ssh_host
      t.integer :ssh_port, default: 22
      t.string :ssh_user
      t.text :ssh_private_key
      t.text :ssh_public_key
      t.text :ssh_known_host_key
    end
  end
end
