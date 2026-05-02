require "test_helper"

class AthleteGradeTest < ActiveSupport::TestCase
  test "slug is generated from athlete and season slugs" do
    grade = AthleteGrade.create!(
      athlete_slug: "lionel-messi-athlete",
      season_slug: "2025-nfl",
      overall_grade_pff: 88.5
    )
    assert_equal "lionel-messi-athlete-2025-nfl", grade.slug
  end

  test "athlete and season combo is unique" do
    assert_raises ActiveRecord::RecordInvalid do
      AthleteGrade.create!(
        athlete_slug: "josh-allen-athlete",
        season_slug: "2025-nfl",
        overall_grade_pff: 85.0
      )
    end
  end

  test "belongs to athlete via slug" do
    grade = athlete_grades(:allen_2025)
    assert_equal athletes(:allen_athlete), grade.athlete
  end

  test "belongs to season via slug" do
    grade = athlete_grades(:allen_2025)
    assert_equal seasons(:nfl_2025), grade.season
  end
end
