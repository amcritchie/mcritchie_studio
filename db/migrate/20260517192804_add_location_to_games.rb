class AddLocationToGames < ActiveRecord::Migration[7.2]
  def change
    add_column :games, :location, :string
  end
end
