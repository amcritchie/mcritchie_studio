require "test_helper"

class RosterTest < ActiveSupport::TestCase
  test "slug is generated from team and slate slugs" do
    roster = Roster.create!(team_slug: "buffalo-bills", slate_slug: "2025-nfl-week-2")
    assert_equal "buffalo-bills-2025-nfl-week-2", roster.slug
  end

  test "team and slate combo is unique" do
    assert_raises ActiveRecord::RecordInvalid do
      Roster.create!(team_slug: "buffalo-bills", slate_slug: "2025-nfl-offseason")
    end
  end

  test "belongs to team" do
    roster = rosters(:bills_offseason)
    assert_equal teams(:buffalo_bills), roster.team
  end

  test "belongs to slate" do
    roster = rosters(:bills_offseason)
    assert_equal slates(:nfl_offseason), roster.slate
  end

  test "starters returns depth 1 spots" do
    roster = rosters(:bills_offseason)
    starters = roster.starters
    assert starters.all? { |s| s.depth == 1 }
  end

  test "offense_starters returns offense depth 1" do
    roster = rosters(:bills_offseason)
    starters = roster.offense_starters
    assert starters.all? { |s| s.depth == 1 && s.side == "offense" }
  end

  test "person_at returns the person at a position" do
    roster = rosters(:bills_offseason)
    person = roster.person_at("QB")
    assert_equal people(:josh_allen), person
  end

  test "person_at returns nil for empty position" do
    roster = rosters(:bills_offseason)
    assert_nil roster.person_at("WR")
  end
end
