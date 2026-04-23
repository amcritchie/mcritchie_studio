class AddGradeRangesToAthleteGrades < ActiveRecord::Migration[7.2]
  def change
    add_column :athlete_grades, :grade_ranges, :jsonb
  end
end
