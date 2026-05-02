class RenamePffGradesAndAddProprietaryGrades < ActiveRecord::Migration[7.2]
  PFF_RENAMES = {
    overall_grade:      :overall_grade_pff,
    offense_grade:      :offense_grade_pff,
    defense_grade:      :defense_grade_pff,
    pass_grade:         :pass_grade_pff,
    run_grade:          :run_grade_pff,
    pass_route_grade:   :pass_route_grade_pff,
    pass_block_grade:   :pass_block_grade_pff,
    run_block_grade:    :run_block_grade_pff,
    pass_rush_grade:    :pass_rush_grade_pff,
    coverage_grade:     :coverage_grade_pff,
    rush_defense_grade: :rush_defense_grade_pff,
    fg_grade:           :fg_grade_pff,
    kickoff_grade:      :kickoff_grade_pff,
    punting_grade:      :punting_grade_pff,
    return_grade:       :return_grade_pff
  }.freeze

  def change
    PFF_RENAMES.each do |old, new_name|
      rename_column :athlete_grades, old, new_name
    end

    add_column :athlete_grades, :position_pass_rank,  :integer
    add_column :athlete_grades, :position_pass_grade, :integer
    add_column :athlete_grades, :position_run_rank,   :integer
    add_column :athlete_grades, :position_run_grade,  :integer

    add_index :athlete_grades, :position_pass_rank
    add_index :athlete_grades, :position_run_rank
  end
end
