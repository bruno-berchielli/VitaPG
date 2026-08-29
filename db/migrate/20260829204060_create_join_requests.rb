class CreateJoinRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :join_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.references :workspace, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.references :decided_by, foreign_key: { to_table: :users }
      t.datetime :decided_at

      t.timestamps
    end
    add_index :join_requests, [ :user_id, :workspace_id ], unique: true
  end
end
