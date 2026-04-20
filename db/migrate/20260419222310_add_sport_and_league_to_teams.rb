class AddSportAndLeagueToTeams < ActiveRecord::Migration[7.2]
  def change
    add_column :teams, :sport, :string
    add_column :teams, :league, :string
    add_column :teams, :conference, :string
    add_column :teams, :division, :string
    add_index :teams, [:sport, :league]
  end
end
