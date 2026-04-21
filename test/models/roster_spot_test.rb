require "test_helper"

class RosterSpotTest < ActiveSupport::TestCase
  test "belongs to roster" do
    spot = roster_spots(:allen_qb)
    assert_equal rosters(:bills_offseason), spot.roster
  end

  test "belongs to person via slug" do
    spot = roster_spots(:allen_qb)
    assert_equal people(:josh_allen), spot.person
  end

  test "validates uniqueness of position and depth within roster" do
    assert_raises ActiveRecord::RecordInvalid do
      RosterSpot.create!(
        roster: rosters(:bills_offseason),
        person_slug: "cam-ward",
        position: "QB",
        side: "offense",
        depth: 1
      )
    end
  end

  test "allows same position at different depths" do
    spot = RosterSpot.create!(
      roster: rosters(:bills_offseason),
      person_slug: "cam-ward",
      position: "QB",
      side: "offense",
      depth: 2
    )
    assert spot.persisted?
  end
end
