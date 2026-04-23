require "test_helper"

class TeamRankingTest < ActiveSupport::TestCase
  test "slug is generated from team_slug, rank_type, and season_slug" do
    ranking = team_rankings(:bills_quarterback)
    ranking.save!
    assert_equal "buffalo-bills-quarterback-2025-nfl", ranking.slug
  end

  test "slug includes week when present" do
    ranking = TeamRanking.new(
      team_slug: "buffalo-bills",
      season_slug: "2025-nfl",
      rank_type: "quarterback",
      rank: 3,
      score: 92.0,
      week: 1
    )
    ranking.save!
    assert_equal "buffalo-bills-quarterback-2025-nfl-week-1", ranking.slug
  end

  test "validates rank_type inclusion" do
    ranking = team_rankings(:bills_quarterback)
    ranking.rank_type = "invalid_type"
    assert_not ranking.valid?
    assert_includes ranking.errors[:rank_type], "is not included in the list"
  end

  test "validates rank range 1-32" do
    ranking = team_rankings(:bills_quarterback)

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

  test "validates uniqueness of team_slug scoped to rank_type, season, and week" do
    existing = team_rankings(:bills_quarterback)
    duplicate = TeamRanking.new(
      team_slug: existing.team_slug,
      rank_type: existing.rank_type,
      season_slug: existing.season_slug,
      week: existing.week,
      rank: 10,
      score: 80.0
    )
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:team_slug], "has already been taken"
  end

  test "allows same team+rank_type+season with different weeks" do
    existing = team_rankings(:bills_quarterback)
    weekly = TeamRanking.new(
      team_slug: existing.team_slug,
      rank_type: existing.rank_type,
      season_slug: existing.season_slug,
      week: 1,
      rank: 5,
      score: 88.0
    )
    assert weekly.valid?
  end

  test "RANK_TYPES includes all unit and aggregate types" do
    assert_equal 14, TeamRanking::RANK_TYPES.size
    assert_includes TeamRanking::RANK_TYPES, "quarterback"
    assert_includes TeamRanking::RANK_TYPES, "power"
    assert_includes TeamRanking::RANK_TYPES, "pass_offense"
  end

  test "for_season scope filters by season slug" do
    results = TeamRanking.for_season("2025-nfl")
    assert results.all? { |r| r.season_slug == "2025-nfl" }
  end

  test "preseason scope returns records with nil week" do
    results = TeamRanking.preseason
    assert results.all? { |r| r.week.nil? }
  end

  test "units scope returns only unit types" do
    results = TeamRanking.units
    assert results.all? { |r| TeamRanking::UNIT_TYPES.include?(r.rank_type) }
  end

  test "aggregates scope returns only aggregate types" do
    results = TeamRanking.aggregates
    assert results.all? { |r| TeamRanking::AGGREGATE_TYPES.include?(r.rank_type) }
  end

  test "belongs to team via slug" do
    ranking = team_rankings(:bills_quarterback)
    assert_equal teams(:buffalo_bills), ranking.team
  end

  test "belongs to season via slug" do
    ranking = team_rankings(:bills_quarterback)
    assert_equal seasons(:nfl_2025), ranking.season
  end

  test "team has_many team_rankings" do
    team = teams(:buffalo_bills)
    assert_includes team.team_rankings, team_rankings(:bills_quarterback)
    assert_includes team.team_rankings, team_rankings(:bills_offense)
  end

  test "season has_many team_rankings" do
    season = seasons(:nfl_2025)
    assert_includes season.team_rankings, team_rankings(:bills_quarterback)
  end

  # --- simulate_impact ---

  test "simulate_impact returns hash with rank deltas for all rank types" do
    result = TeamRanking.simulate_impact(
      person_slug: "david-bailey",
      target_team_slug: "buffalo-bills",
      season_slug: "2025-nfl"
    )
    assert_not_nil result
    assert_equal TeamRanking::RANK_TYPES.sort, result.keys.sort
    result.each do |type, data|
      assert_includes data, :current_score
      assert_includes data, :modified_score
      assert_includes data, :current_rank
      assert_includes data, :modified_rank
      assert_includes data, :delta_rank
      assert_includes data, :delta_score
      assert_includes data, :changed
    end
  end

  test "simulate_impact returns nil for missing player" do
    result = TeamRanking.simulate_impact(
      person_slug: "nonexistent-player",
      target_team_slug: "buffalo-bills",
      season_slug: "2025-nfl"
    )
    assert_nil result
  end

  test "simulate_impact shows improvement for strong EDGE added to pass_rush" do
    result = TeamRanking.simulate_impact(
      person_slug: "david-bailey",
      target_team_slug: "buffalo-bills",
      season_slug: "2025-nfl"
    )
    assert_not_nil result
    # David Bailey (84.0 pass_rush) should improve the Bills' pass_rush score
    assert result["pass_rush"][:modified_score] >= result["pass_rush"][:current_score],
      "Adding a strong EDGE should not decrease pass_rush score"
  end

  test "team_aggregates computes correct formulas" do
    units = {
      "quarterback" => 80.0, "receiving" => 70.0, "rushing" => 60.0,
      "pass_block" => 65.0, "run_block" => 55.0, "pass_rush" => 75.0,
      "coverage" => 72.0, "run_defense" => 68.0
    }
    agg = TeamRanking.team_aggregates(units)
    assert_equal 6, agg.size
    assert_in_delta (80.0**1.6) + 4 * 70.0 + 2 * 65.0, agg["pass_offense"], 0.01
    assert_in_delta 5 * 60.0 + 2 * 55.0, agg["run_offense"], 0.01
    assert_in_delta 4 * 75.0 + 3 * 72.0, agg["pass_defense"], 0.01
  end
end
