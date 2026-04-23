class CreatePffTeamStats < ActiveRecord::Migration[7.2]
  def change
    create_table :pff_team_stats do |t|
      t.string  :team_slug, null: false
      t.string  :season_slug, null: false
      t.string  :stat_type, null: false
      t.jsonb   :data, null: false, default: {}
      t.string  :slug, null: false

      t.timestamps
    end

    add_index :pff_team_stats, :slug, unique: true
    add_index :pff_team_stats, [:team_slug, :season_slug, :stat_type], unique: true, name: "idx_pff_team_stats_unique"
    add_index :pff_team_stats, :data, using: :gin
  end
end
