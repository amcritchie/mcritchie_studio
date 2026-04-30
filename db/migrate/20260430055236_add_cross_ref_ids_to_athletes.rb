class AddCrossRefIdsToAthletes < ActiveRecord::Migration[7.2]
  def change
    add_column :athletes, :team_slug, :string
    add_column :athletes, :gsis_id, :string
    add_column :athletes, :otc_id, :string
    add_column :athletes, :sleeper_id, :string
    add_column :athletes, :pfr_id, :string
    add_column :athletes, :nflverse_id, :string

    add_index :athletes, :team_slug
    add_index :athletes, :gsis_id, unique: true
    add_index :athletes, :otc_id, unique: true
    add_index :athletes, :sleeper_id, unique: true
    add_index :athletes, :pfr_id, unique: true
    add_index :athletes, :nflverse_id, unique: true
  end
end
