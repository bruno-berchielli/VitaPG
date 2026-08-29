class AddSuperadminToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :superadmin, :boolean, null: false, default: false
  end
end
