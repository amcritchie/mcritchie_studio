class AddStGradesToAthleteGrades < ActiveRecord::Migration[7.2]
  def change
    add_column :athlete_grades, :fg_grade, :float
    add_column :athlete_grades, :kickoff_grade, :float
    add_column :athlete_grades, :punting_grade, :float
    add_column :athlete_grades, :return_grade, :float
  end
end
