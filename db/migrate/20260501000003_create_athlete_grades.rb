class CreateAthleteGrades < ActiveRecord::Migration[7.2]
  def change
    create_table "athlete_grades", force: :cascade do |t|
      t.string "athlete_slug", null: false
      t.string "season_slug", null: false
      t.float "overall_grade"
      t.float "offense_grade"
      t.float "defense_grade"
      t.float "pass_grade"
      t.float "run_grade"
      t.float "pass_route_grade"
      t.float "pass_block_grade"
      t.float "run_block_grade"
      t.float "pass_rush_grade"
      t.float "coverage_grade"
      t.float "rush_defense_grade"
      t.integer "games_played"
      t.integer "snaps"
      t.string "slug", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.float "fg_grade"
      t.float "kickoff_grade"
      t.float "punting_grade"
      t.float "return_grade"
      t.jsonb "grade_ranges"
      t.index ["athlete_slug", "season_slug"], name: "index_athlete_grades_on_athlete_slug_and_season_slug", unique: true
      t.index ["athlete_slug"], name: "index_athlete_grades_on_athlete_slug"
      t.index ["season_slug"], name: "index_athlete_grades_on_season_slug"
      t.index ["slug"], name: "index_athlete_grades_on_slug", unique: true
    end
  end
end
