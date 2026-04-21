class CreateAthleteGrades < ActiveRecord::Migration[7.2]
  def change
    create_table :athlete_grades do |t|
      t.string :athlete_slug, null: false
      t.string :season_slug, null: false
      t.float :overall_grade
      t.float :offense_grade
      t.float :defense_grade
      t.float :pass_grade
      t.float :run_grade
      t.float :pass_route_grade
      t.float :pass_block_grade
      t.float :run_block_grade
      t.float :pass_rush_grade
      t.float :coverage_grade
      t.float :rush_defense_grade
      t.integer :games_played
      t.integer :snaps
      t.string :slug, null: false

      t.timestamps
    end

    add_index :athlete_grades, :slug, unique: true
    add_index :athlete_grades, :athlete_slug
    add_index :athlete_grades, :season_slug
    add_index :athlete_grades, [:athlete_slug, :season_slug], unique: true
  end
end
