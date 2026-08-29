class CreateNotificationChannels < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_channels do |t|
      t.references :workspace, null: false, foreign_key: true
      t.string :name, null: false
      t.string :kind, null: false
      t.string :url
      t.string :recipients
      t.string :signing_secret
      t.boolean :notify_on_success, null: false, default: false
      t.boolean :notify_on_failure, null: false, default: true
      t.boolean :enabled, null: false, default: true

      t.timestamps
    end
  end
end
