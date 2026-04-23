require "test_helper"

class CoachRankingTest < ActiveSupport::TestCase
  test "slug is generated from coach_slug, rank_type, and season_slug" do
    ranking = coach_rankings(:bills_pass_first)
    ranking.save!
    assert_equal "sean-mcdermott-buffalo-bills-head_coach-pass_first-2025-nfl", ranking.slug
  end

  test "validates rank_type inclusion" do
    ranking = coach_rankings(:bills_pass_first)
    ranking.rank_type = "run_first"
    assert_not ranking.valid?
    assert_includes ranking.errors[:rank_type], "is not included in the list"
  end

  test "validates rank range" do
    ranking = coach_rankings(:bills_pass_first)
    ranking.rank = 0
    assert_not ranking.valid?
    assert_includes ranking.errors[:rank], "is not included in the list"

    ranking.rank = 33
    assert_not ranking.valid?

    ranking.rank = 1
    assert ranking.valid?

    ranking.rank = 32
    assert ranking.valid?
  end

  test "validates uniqueness of coach_slug scoped to rank_type and season" do
    existing = coach_rankings(:bills_pass_first)
    duplicate = CoachRanking.new(
      coach_slug: existing.coach_slug,
      rank_type: existing.rank_type,
      season_slug: existing.season_slug,
      rank: 10,
      tier: "Pass Enthusiast"
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:coach_slug], "has already been taken"
  end

  test "pass_first scope returns only pass_first rankings" do
    assert CoachRanking.pass_first.all? { |r| r.rank_type == "pass_first" }
  end

  test "pass_heavy scope returns only pass_heavy rankings" do
    assert CoachRanking.pass_heavy.all? { |r| r.rank_type == "pass_heavy" }
  end

  test "for_season scope filters by season slug" do
    results = CoachRanking.for_season("2025-nfl")
    assert results.all? { |r| r.season_slug == "2025-nfl" }
  end

  test "belongs to coach via slug" do
    ranking = coach_rankings(:bills_pass_first)
    assert_equal coaches(:bills_hc), ranking.coach
  end

  test "belongs to season via slug" do
    ranking = coach_rankings(:bills_pass_first)
    assert_equal seasons(:nfl_2025), ranking.season
  end

  test "coach has_many coach_rankings" do
    coach = coaches(:bills_hc)
    assert_includes coach.coach_rankings, coach_rankings(:bills_pass_first)
    assert_includes coach.coach_rankings, coach_rankings(:bills_pass_heavy)
  end

  test "season has_many coach_rankings" do
    season = seasons(:nfl_2025)
    assert_includes season.coach_rankings, coach_rankings(:bills_pass_first)
  end
end
