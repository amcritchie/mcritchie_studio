require "test_helper"

class PffStatTest < ActiveSupport::TestCase
  test "slug is generated from athlete, season, and stat_type" do
    stat = PffStat.create!(
      athlete_slug: "josh-allen-athlete",
      season_slug: "2025-nfl",
      stat_type: "defense_summary",
      data: { "grades_defense" => 80.0 }
    )
    assert_equal "josh-allen-athlete-2025-nfl-defense_summary", stat.slug
  end

  test "to_param returns slug" do
    stat = pff_stats(:allen_passing)
    assert_equal "josh-allen-athlete-2025-nfl-passing_summary", stat.to_param
  end

  test "athlete, season, stat_type combo is unique" do
    assert_raises ActiveRecord::RecordInvalid do
      PffStat.create!(
        athlete_slug: "josh-allen-athlete",
        season_slug: "2025-nfl",
        stat_type: "passing_summary",
        data: { "grades_pass" => 85.0 }
      )
    end
  end

  test "belongs to athlete via slug" do
    stat = pff_stats(:allen_passing)
    assert_equal athletes(:allen_athlete), stat.athlete
  end

  test "belongs to season via slug" do
    stat = pff_stats(:allen_passing)
    assert_equal seasons(:nfl_2025), stat.season
  end

  test "belongs to team via slug (optional)" do
    stat = pff_stats(:allen_passing)
    assert_equal teams(:buffalo_bills), stat.team
  end

  test "team is optional" do
    stat = PffStat.create!(
      athlete_slug: "josh-allen-athlete",
      season_slug: "2025-nfl",
      stat_type: "defense_summary",
      team_slug: nil,
      data: { "test" => true }
    )
    assert_nil stat.team
  end

  test "grade helper extracts float from JSONB" do
    stat = pff_stats(:allen_passing)
    assert_in_delta 92.0, stat.grade(:grades_pass), 0.01
  end

  test "grade helper returns nil for missing key" do
    stat = pff_stats(:allen_passing)
    assert_nil stat.grade(:nonexistent_field)
  end

  test "JSONB data stores full CSV row" do
    stat = pff_stats(:allen_passing)
    assert_equal "Josh Allen", stat.data["player"]
    assert_equal 11765, stat.data["player_id"]
    assert_equal 4200, stat.data["yards"]
  end

  test "scopes filter correctly" do
    assert_includes PffStat.for_season("2025-nfl"), pff_stats(:allen_passing)
    assert_includes PffStat.of_type("passing_summary"), pff_stats(:allen_passing)
    assert_not_includes PffStat.of_type("defense_summary"), pff_stats(:allen_passing)
  end

  test "validations require athlete_slug, season_slug, stat_type" do
    stat = PffStat.new(data: {})
    assert_not stat.valid?
    assert_includes stat.errors[:athlete_slug], "can't be blank"
    assert_includes stat.errors[:season_slug], "can't be blank"
    assert_includes stat.errors[:stat_type], "can't be blank"
  end
end
