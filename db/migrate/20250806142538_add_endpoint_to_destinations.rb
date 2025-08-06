class AddEndpointToDestinations < ActiveRecord::Migration[8.0]
  def change
    add_column :destinations, :endpoint, :string
  end
end
