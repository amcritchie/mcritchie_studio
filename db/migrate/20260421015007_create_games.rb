class CreateGames < ActiveRecord::Migration[7.2]
  def change
    create_table :games do |t|
      t.string :slug, null: false
      t.string :slate_slug, null: false
      t.string :home_team_slug, null: false
      t.string :away_team_slug, null: false
      t.datetime :kickoff_at
      t.string :venue
      t.string :status, default: "scheduled"
      t.timestamps
    end

    add_index :games, :slug, unique: true
    add_index :games, :slate_slug
    add_index :games, :home_team_slug
    add_index :games, :away_team_slug
  end
end
