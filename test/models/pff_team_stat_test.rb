require "test_helper"

class PffTeamStatTest < ActiveSupport::TestCase
  test "slug is generated from team, season, and stat_type" do
    stat = PffTeamStat.create!(
      team_slug: "miami-dolphins",
      season_slug: "2025-nfl",
      stat_type: "line_pass_blocking_efficiency",
      data: { "pbe" => 85.0 }
    )
    assert_equal "miami-dolphins-2025-nfl-line_pass_blocking_efficiency", stat.slug
  end

  test "to_param returns slug" do
    stat = pff_team_stats(:bills_blocking)
    assert_equal "buffalo-bills-2025-nfl-line_pass_blocking_efficiency", stat.to_param
  end

  test "team, season, stat_type combo is unique" do
    assert_raises ActiveRecord::RecordInvalid do
      PffTeamStat.create!(
        team_slug: "buffalo-bills",
        season_slug: "2025-nfl",
        stat_type: "line_pass_blocking_efficiency",
        data: { "pbe" => 90.0 }
      )
    end
  end

  test "belongs to team via slug" do
    stat = pff_team_stats(:bills_blocking)
    assert_equal teams(:buffalo_bills), stat.team
  end

  test "belongs to season via slug" do
    stat = pff_team_stats(:bills_blocking)
    assert_equal seasons(:nfl_2025), stat.season
  end

  test "JSONB data stores full row" do
    stat = pff_team_stats(:bills_blocking)
    assert_equal 88.5, stat.data["pbe"]
    assert_equal 600, stat.data["attempts"]
  end

  test "scopes filter correctly" do
    assert_includes PffTeamStat.for_season("2025-nfl"), pff_team_stats(:bills_blocking)
    assert_includes PffTeamStat.of_type("line_pass_blocking_efficiency"), pff_team_stats(:bills_blocking)
  end

  test "validations require team_slug, season_slug, stat_type" do
    stat = PffTeamStat.new(data: {})
    assert_not stat.valid?
    assert_includes stat.errors[:team_slug], "can't be blank"
    assert_includes stat.errors[:season_slug], "can't be blank"
    assert_includes stat.errors[:stat_type], "can't be blank"
  end
end
