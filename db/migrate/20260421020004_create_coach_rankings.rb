class CreateCoachRankings < ActiveRecord::Migration[7.2]
  def change
    create_table :coach_rankings do |t|
      t.string :coach_slug, null: false
      t.string :season_slug, null: false
      t.string :rank_type, null: false
      t.integer :rank, null: false
      t.string :tier
      t.string :slug, null: false
      t.timestamps
    end

    add_index :coach_rankings, :slug, unique: true
    add_index :coach_rankings, :coach_slug
    add_index :coach_rankings, :season_slug
    add_index :coach_rankings, [:coach_slug, :rank_type, :season_slug], unique: true, name: "index_coach_rankings_unique_type_season"
  end
end
