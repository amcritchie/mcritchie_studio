class CreateTeamRankings < ActiveRecord::Migration[7.2]
  def change
    create_table :team_rankings do |t|
      t.string :team_slug, null: false
      t.string :season_slug, null: false
      t.string :rank_type, null: false
      t.integer :rank, null: false
      t.decimal :score, precision: 10, scale: 2
      t.integer :week
      t.string :slug, null: false

      t.timestamps
    end

    add_index :team_rankings, :slug, unique: true
    add_index :team_rankings, :team_slug
    add_index :team_rankings, :season_slug
    add_index :team_rankings, [:team_slug, :rank_type, :season_slug, :week], unique: true, name: "idx_team_rankings_unique_with_week", where: "week IS NOT NULL"
    add_index :team_rankings, [:team_slug, :rank_type, :season_slug], unique: true, name: "idx_team_rankings_unique_preseason", where: "week IS NULL"
  end
end
