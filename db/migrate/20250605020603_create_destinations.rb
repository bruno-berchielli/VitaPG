class CreateDestinations < ActiveRecord::Migration[8.0]
  def change
    create_table :destinations do |t|
      t.string :name
      t.string :provider
      t.string :bucket
      t.string :region
      t.string :access_key_id
      t.string :secret_access_key
      t.string :project_id
      t.string :credentials_path

      t.timestamps
    end
  end
end
