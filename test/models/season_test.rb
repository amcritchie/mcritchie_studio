require "test_helper"

class SeasonTest < ActiveSupport::TestCase
  test "slug is generated from year and league" do
    season = Season.create!(year: 2026, sport: "football", league: "nfl", name: "2026 NFL Season")
    assert_equal "2026-nfl", season.slug
  end

  test "year and league combo is unique" do
    assert_raises ActiveRecord::RecordInvalid do
      Season.create!(year: 2025, sport: "football", league: "nfl", name: "Duplicate")
    end
  end

  test "active scope returns active seasons" do
    assert_includes Season.active, seasons(:nfl_2025)
    assert_not_includes Season.active, seasons(:ncaa_2025)
  end

  test "nfl scope returns nfl seasons" do
    assert_includes Season.nfl, seasons(:nfl_2025)
    assert_not_includes Season.nfl, seasons(:ncaa_2025)
  end

  test "active_nfl returns the active NFL season" do
    assert_equal seasons(:nfl_2025), Season.active_nfl
  end

  test "has many slates" do
    season = seasons(:nfl_2025)
    assert_includes season.slates, slates(:nfl_offseason)
  end
end
