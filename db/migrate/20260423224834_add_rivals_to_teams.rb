class AddRivalsToTeams < ActiveRecord::Migration[7.2]
  def change
    add_column :teams, :rivals, :jsonb, default: []
  end
end
