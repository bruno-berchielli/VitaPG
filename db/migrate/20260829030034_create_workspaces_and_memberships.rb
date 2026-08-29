class CreateWorkspacesAndMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :workspaces do |t|
      t.string :name, null: false
      t.string :slug, null: false

      t.timestamps
    end
    add_index :workspaces, :slug, unique: true

    create_table :memberships do |t|
      t.references :user, null: false, foreign_key: true
      t.references :workspace, null: false, foreign_key: true
      t.string :role, null: false, default: "member"

      t.timestamps
    end
    add_index :memberships, [ :user_id, :workspace_id ], unique: true
  end
end
