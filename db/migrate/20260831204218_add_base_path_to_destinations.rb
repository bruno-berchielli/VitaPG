class AddBasePathToDestinations < ActiveRecord::Migration[8.1]
  def change
    add_column :destinations, :base_path, :string
  end
end
