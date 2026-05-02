require "test_helper"

class Athletes::ComputeProprietaryGradesTest < ActiveSupport::TestCase
  SEASON = "2025-nfl"

  setup do
    # Wipe any pre-set rank/grade so we can assert from a known baseline.
    AthleteGrade.where(season_slug: SEASON)
                .update_all(position_pass_rank: nil, position_pass_grade: nil,
                            position_run_rank:  nil, position_run_grade:  nil)
  end

  test "ranks QBs by pass_grade_pff (descending)" do
    Athletes::ComputeProprietaryGrades.new(season_slug: SEASON).call

    allen = AthleteGrade.find_by(athlete_slug: "josh-allen-athlete", season_slug: SEASON)
    # Allen has pass_grade_pff=92.0; he should rank #1 among QBs in fixtures.
    assert_equal 1, allen.position_pass_rank
    assert_equal 10, allen.position_pass_grade
  end

  test "QB run rank mirrors pass rank (QBs use pass grade for both axes)" do
    Athletes::ComputeProprietaryGrades.new(season_slug: SEASON).call

    allen = AthleteGrade.find_by(athlete_slug: "josh-allen-athlete", season_slug: SEASON)
    assert_equal allen.position_pass_rank,  allen.position_run_rank
    assert_equal allen.position_pass_grade, allen.position_run_grade
  end

  test "athletes missing both primary input AND side-overall fall to the bottom with grade 0" do
    # Cam Ward fixture has no pass_grade_pff and no offense_grade_pff set →
    # should be ranked at the bottom of the QB pool with grade 0 (D tier).
    Athletes::ComputeProprietaryGrades.new(season_slug: SEASON).call

    ward = AthleteGrade.find_by(athlete_slug: "cam-ward-athlete", season_slug: SEASON)
    assert_not_nil ward.position_pass_rank, "expected Ward to get a bottom rank, not nil"
    assert_equal 0, ward.position_pass_grade

    # Ward's rank should be greater than any QB with a real input.
    allen = AthleteGrade.find_by(athlete_slug: "josh-allen-athlete", season_slug: SEASON)
    assert ward.position_pass_rank > allen.position_pass_rank
  end

  test "0-10 grade maps linearly: best=10, worst=0, middle scaled" do
    # RB bucket uses run_grade_pff. Cook=82, Davis=70.5 → 2 athletes,
    # best=10 worst=0 in a 2-athlete bucket.
    Athletes::ComputeProprietaryGrades.new(season_slug: SEASON).call

    cook  = AthleteGrade.find_by(athlete_slug: "james-cook-athlete",  season_slug: SEASON)
    davis = AthleteGrade.find_by(athlete_slug: "ray-davis-athlete",   season_slug: SEASON)

    assert_equal 1, cook.position_run_rank
    assert_equal 10, cook.position_run_grade
    assert_equal 2, davis.position_run_rank
    assert_equal 0, davis.position_run_grade
  end

  test "single-row bucket gets grade=10" do
    # Force a 1-athlete bucket: keep only one TE with route-grade input set.
    AthleteGrade.joins("INNER JOIN athletes ON athletes.slug = athlete_grades.athlete_slug")
                .where(season_slug: SEASON, athletes: { position: %w[WR TE] })
                .update_all(pass_route_grade_pff: nil)
    target = AthleteGrade.joins("INNER JOIN athletes ON athletes.slug = athlete_grades.athlete_slug")
                         .where(season_slug: SEASON, athletes: { position: "TE" }).first
    target.update!(pass_route_grade_pff: 75.0)

    Athletes::ComputeProprietaryGrades.new(season_slug: SEASON).call

    target.reload
    assert_equal 1, target.position_pass_rank
    assert_equal 10, target.position_pass_grade
  end

  test "returns stats hash with bucket counts" do
    stats = Athletes::ComputeProprietaryGrades.new(season_slug: SEASON).call
    assert_kind_of Hash, stats
    # Buckets that have at least one athlete in fixtures should be > 0.
    assert stats[:qb] >= 2, "expected ≥2 QBs in fixtures, got #{stats[:qb]}"
    assert stats[:rb] >= 2, "expected ≥2 RBs in fixtures, got #{stats[:rb]}"
  end
end
