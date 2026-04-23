class CreatePffStats < ActiveRecord::Migration[7.2]
  def change
    create_table :pff_stats do |t|
      t.string  :athlete_slug, null: false
      t.string  :season_slug, null: false
      t.string  :stat_type, null: false
      t.string  :team_slug
      t.integer :pff_player_id
      t.integer :games_played
      t.jsonb   :data, null: false, default: {}
      t.string  :slug, null: false

      t.timestamps
    end

    add_index :pff_stats, :slug, unique: true
    add_index :pff_stats, [:athlete_slug, :season_slug, :stat_type], unique: true, name: "idx_pff_stats_unique"
    add_index :pff_stats, :stat_type
    add_index :pff_stats, :pff_player_id
    add_index :pff_stats, :data, using: :gin
  end
end
