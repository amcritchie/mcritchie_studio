require "test_helper"

class PositionConcernTest < ActiveSupport::TestCase
  # Default behavior (no source) — uses GENERAL_MAP
  test "normalize_position returns canonical positions unchanged" do
    assert_equal "QB", PositionConcern.normalize_position("QB")
    assert_equal "EDGE", PositionConcern.normalize_position("EDGE")
    assert_equal "S", PositionConcern.normalize_position("S")
  end

  test "normalize_position upcases bare input" do
    assert_equal "QB", PositionConcern.normalize_position("qb")
    assert_equal "EDGE", PositionConcern.normalize_position("Edge")
  end

  test "normalize_position uses GENERAL_MAP without source" do
    assert_equal "RB", PositionConcern.normalize_position("HB")
    assert_equal "OG", PositionConcern.normalize_position("G")
    assert_equal "OT", PositionConcern.normalize_position("T")
    assert_equal "DT", PositionConcern.normalize_position("DI")
    assert_equal "S", PositionConcern.normalize_position("DB")
  end

  test "normalize_position returns nil for nil input" do
    assert_nil PositionConcern.normalize_position(nil)
  end

  # ESPN source — collapses formation labels to generic positions
  test "normalize_position with source: :espn flattens linebackers to LB" do
    assert_equal "LB", PositionConcern.normalize_position("WLB", source: :espn)
    assert_equal "LB", PositionConcern.normalize_position("SLB", source: :espn)
    assert_equal "LB", PositionConcern.normalize_position("LILB", source: :espn)
    assert_equal "LB", PositionConcern.normalize_position("MIKE", source: :espn)
  end

  test "normalize_position with source: :espn keeps FS and SS distinct" do
    assert_equal "FS", PositionConcern.normalize_position("FS", source: :espn)
    assert_equal "SS", PositionConcern.normalize_position("SS", source: :espn)
  end

  test "normalize_position with source: :espn collapses ends to EDGE" do
    assert_equal "EDGE", PositionConcern.normalize_position("LDE", source: :espn)
    assert_equal "EDGE", PositionConcern.normalize_position("RDE", source: :espn)
  end

  test "normalize_position with source: :espn maps PK to K" do
    assert_equal "K", PositionConcern.normalize_position("PK", source: :espn)
  end

  # PFF source — uses HB/T/G/ED/DI vocabulary
  test "normalize_position with source: :pff maps PFF vocabulary" do
    assert_equal "RB", PositionConcern.normalize_position("HB", source: :pff)
    assert_equal "OT", PositionConcern.normalize_position("T", source: :pff)
    assert_equal "OG", PositionConcern.normalize_position("G", source: :pff)
    assert_equal "EDGE", PositionConcern.normalize_position("ED", source: :pff)
    assert_equal "DT", PositionConcern.normalize_position("DI", source: :pff)
  end

  # nflverse + Spotrac — break out ILB/OLB/MLB
  test "normalize_position with source: :nflverse flattens linebackers" do
    assert_equal "LB", PositionConcern.normalize_position("ILB", source: :nflverse)
    assert_equal "LB", PositionConcern.normalize_position("OLB", source: :nflverse)
    assert_equal "LB", PositionConcern.normalize_position("MLB", source: :nflverse)
  end

  test "normalize_position with source: :spotrac maps DE to EDGE" do
    assert_equal "EDGE", PositionConcern.normalize_position("DE", source: :spotrac)
    assert_equal "S", PositionConcern.normalize_position("FS", source: :spotrac)
  end

  # Fallback — unknown source-specific value falls through to GENERAL_MAP
  test "normalize_position falls back to GENERAL_MAP when source map has no entry" do
    assert_equal "RB", PositionConcern.normalize_position("HB", source: :espn)
    assert_equal "DT", PositionConcern.normalize_position("DI", source: :nflverse)
  end

  # Side detection
  test "side_for returns offense/defense/special_teams" do
    assert_equal "offense", PositionConcern.side_for("QB")
    assert_equal "offense", PositionConcern.side_for("WR")
    assert_equal "defense", PositionConcern.side_for("EDGE")
    assert_equal "defense", PositionConcern.side_for("CB")
    assert_equal "special_teams", PositionConcern.side_for("K")
    assert_equal "special_teams", PositionConcern.side_for("P")
  end
end
