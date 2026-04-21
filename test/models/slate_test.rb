require "test_helper"

class SlateTest < ActiveSupport::TestCase
  test "slug is generated from season and label" do
    season = seasons(:nfl_2025)
    slate = Slate.create!(season_slug: season.slug, sequence: 99, label: "Test Slate", slate_type: "test")
    assert_equal "2025-nfl-test-slate", slate.slug
  end

  test "sequence is unique within season" do
    assert_raises ActiveRecord::RecordInvalid do
      Slate.create!(season_slug: "2025-nfl", sequence: 0, label: "Dupe", slate_type: "offseason")
    end
  end

  test "ordered scope sorts by sequence" do
    slates = Slate.where(season_slug: "2025-nfl").ordered
    assert_equal 0, slates.first.sequence
  end

  test "belongs to season" do
    slate = slates(:nfl_offseason)
    assert_equal seasons(:nfl_2025), slate.season
  end

  test "has many rosters" do
    slate = slates(:nfl_offseason)
    assert_includes slate.rosters, rosters(:bills_offseason)
  end
end
