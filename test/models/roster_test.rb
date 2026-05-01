require "test_helper"

class RosterTest < ActiveSupport::TestCase
  # pick_starters now reads from DepthChart, but fixtures only define roster_spots.
  # Mirror each RosterSpot into a DepthChartEntry per team so the existing tests
  # don't need to maintain a parallel fixture set.
  setup do
    Roster.find_each do |roster|
      chart = DepthChart.find_or_create_by!(team_slug: roster.team_slug)
      roster.roster_spots.find_each do |rs|
        chart.depth_chart_entries.find_or_create_by!(person_slug: rs.person_slug, position: rs.position) do |dce|
          dce.depth = rs.depth
          dce.side  = rs.side
        end
      end
    end
  end

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

  test "offense_starters returns offense depth 1" do
    roster = rosters(:bills_offseason)
    starters = roster.offense_starters
    assert starters.all? { |s| s.depth == 1 && s.side == "offense" }
  end

  # offense_starting_12 — new 12-slot layout

  test "offense_starting_12 returns hash with 12 ordered slots" do
    roster = rosters(:bills_offseason)
    result = roster.offense_starting_12
    assert_kind_of Hash, result
    assert_equal Roster::OFFENSE_SLOTS, result.keys
  end

  test "offense_starting_12 totals 12 picks" do
    roster = rosters(:bills_offseason)
    picks = roster.offense_starting_12.values.compact
    assert_equal 12, picks.size
  end

  test "offense_starting_12 fills QB, RB, WRs, TE from depth chart" do
    roster = rosters(:bills_offseason)
    result = roster.offense_starting_12
    assert_equal "josh-allen",     result[:qb].person_slug
    assert_equal "james-cook",     result[:rb].person_slug
    assert_equal "khalil-shakir",  result[:wr1].person_slug
    assert_equal "dalton-kincaid", result[:te].person_slug
  end

  test "offense_starting_12 OL slots align to canonical positions" do
    roster = rosters(:bills_offseason)
    result = roster.offense_starting_12
    assert_equal "dion-dawkins",    result[:lt].person_slug
    assert_equal "connor-mcgovern", result[:lg].person_slug
    assert_equal "mitch-morse",     result[:c].person_slug
    assert_equal "ryan-bates",      result[:rg].person_slug
    assert_equal "spencer-brown",   result[:rt].person_slug
  end

  test "offense_starting_12 each PickedSpot exposes its slot" do
    roster = rosters(:bills_offseason)
    result = roster.offense_starting_12
    assert_equal :qb,  result[:qb].slot
    assert_equal :wr1, result[:wr1].slot
    assert_equal :flex, result[:flex].slot
  end

  # defense_starting_12 — new 12-slot layout

  test "defense_starting_12 returns hash with 12 ordered slots" do
    roster = rosters(:bills_offseason)
    result = roster.defense_starting_12
    assert_kind_of Hash, result
    assert_equal Roster::DEFENSE_SLOTS, result.keys
  end

  test "defense_starting_12 totals 12 picks" do
    roster = rosters(:bills_offseason)
    picks = roster.defense_starting_12.values.compact
    assert_equal 12, picks.size
  end

  test "defense_starting_12 EDGE slots resort by pass_rush_grade" do
    roster = rosters(:bills_offseason)
    result = roster.defense_starting_12
    pr1 = result[:edge1].person.athlete_profile.grades.first.pass_rush_grade
    pr2 = result[:edge2].person.athlete_profile.grades.first.pass_rush_grade
    assert pr1 >= pr2 if pr1 && pr2
  end

  test "defense_starting_12 dl_flex picks highest pass_rush_grade among unselected DLine" do
    roster = rosters(:bills_offseason)
    result = roster.defense_starting_12
    flex = result[:dl_flex]
    return skip "no flex pool" unless flex
    edge_dl_slugs = [result[:edge1], result[:edge2], result[:dl1], result[:dl2]].compact.map(&:person_slug)
    refute_includes edge_dl_slugs, flex.person_slug
  end

  test "defense_starting_12 nickel flex draws from CBs or safeties" do
    roster = rosters(:bills_offseason)
    result = roster.defense_starting_12
    nickel = result[:flex]
    return skip "no nickel pool" unless nickel
    assert_includes %w[CB S FS SS], nickel.position
    used = [result[:cb1], result[:cb2], result[:ss], result[:fs]].compact.map(&:person_slug)
    refute_includes used, nickel.person_slug
  end

  # Edge case: empty roster

  test "offense_starting_12 returns empty groups for roster with no spots" do
    skip "DepthChart is per-team — empty roster still inherits the team's chart"
  end

  test "defense_starting_12 returns empty groups for roster with no spots" do
    skip "DepthChart is per-team — empty roster still inherits the team's chart"
  end

  # OLine guardrail tests — superseded by explicit LT/LG/C/RG/RT slots

  test "oline includes a center when top 5 by grade have none" do
    skip "OL slots are now per-position (LT/LG/C/RG/RT) — center is always picked explicitly"
  end

  test "oline replaces duplicate center with next best non-center" do
    skip "OL slots are now per-position — no possibility of duplicate centers"
  end

  # ─── Scheme-aware defense picker ─────────────────────────────────────────────

  test "defense_starting_12 uses 3-4 formation mapping when scheme=3-4" do
    roster = rosters(:bills_offseason)
    chart = DepthChart.find_or_create_by!(team_slug: roster.team_slug)
    chart.update!(scheme: "3-4")

    # Wipe defense entries from fixture-mirror setup, build fresh ones with
    # formation_slot set per the 3-4 mapping
    chart.depth_chart_entries.where(side: "defense").destroy_all
    {
      "WLB"  => "von-miller",       # → EDGE1
      "SLB"  => "greg-rousseau",    # → EDGE2
      "LDE"  => "ed-oliver",        # → DL1
      "RDE"  => "daquan-jones",     # → DL2
      "NT"   => "tim-settle",       # → DL Flex
      "LILB" => "matt-milano",      # → LB1
      "RILB" => "terrel-bernard",   # → LB2
      "SS"   => "jordan-poyer",     # → SS
      "FS"   => "taylor-rapp",      # → FS
      "LCB"  => "rasul-douglas",    # → CB1
      "RCB"  => "taron-johnson",    # → CB2
      "NB"   => "christian-benford" # → Nickel Flex
    }.each do |slot, person_slug|
      chart.depth_chart_entries.create!(
        person_slug: person_slug, position: slot, side: "defense",
        depth: 1, formation_slot: slot
      )
    end

    result = roster.defense_starting_12

    assert_equal "von-miller",        result[:edge1].person_slug
    assert_equal "greg-rousseau",     result[:edge2].person_slug
    assert_equal "ed-oliver",         result[:dl1].person_slug
    assert_equal "daquan-jones",      result[:dl2].person_slug
    assert_equal "tim-settle",        result[:dl_flex].person_slug
    assert_equal "matt-milano",       result[:lb1].person_slug
    assert_equal "terrel-bernard",    result[:lb2].person_slug
    assert_equal "jordan-poyer",      result[:ss].person_slug
    assert_equal "taylor-rapp",       result[:fs].person_slug
    assert_equal "rasul-douglas",     result[:cb1].person_slug
    assert_equal "taron-johnson",     result[:cb2].person_slug
    assert_equal "christian-benford", result[:flex].person_slug
  end

  test "defense_starting_12 falls back to pool logic when scheme is nil" do
    roster = rosters(:bills_offseason)
    chart = DepthChart.find_or_create_by!(team_slug: roster.team_slug)
    chart.update!(scheme: nil)
    # All entries from fixture-mirror have nil formation_slot, so pool path used
    result = roster.defense_starting_12
    assert_equal Roster::DEFENSE_SLOTS, result.keys
    assert result.values.compact.size >= 7  # bills fixture has enough defense to fill most slots
  end

  test "defense_starting_12 4-3 DL Flex picks best PR among unselected EDGE/DL at depth 2+" do
    roster = rosters(:bills_offseason)
    chart = DepthChart.find_or_create_by!(team_slug: roster.team_slug)
    chart.update!(scheme: "4-3")

    chart.depth_chart_entries.where(side: "defense").destroy_all
    # Minimum 4-3 setup with one depth-2 EDGE for the flex slot
    chart.depth_chart_entries.create!(person_slug: "von-miller",     position: "EDGE", side: "defense", depth: 1, formation_slot: "LDE")
    chart.depth_chart_entries.create!(person_slug: "greg-rousseau",  position: "EDGE", side: "defense", depth: 1, formation_slot: "RDE")
    chart.depth_chart_entries.create!(person_slug: "ed-oliver",      position: "DT",   side: "defense", depth: 1, formation_slot: "LDT")
    chart.depth_chart_entries.create!(person_slug: "daquan-jones",   position: "DT",   side: "defense", depth: 1, formation_slot: "RDT")
    chart.depth_chart_entries.create!(person_slug: "aj-epenesa",     position: "EDGE", side: "defense", depth: 2, formation_slot: "LDE")

    result = roster.defense_starting_12

    assert_equal "von-miller",     result[:edge1].person_slug
    assert_equal "greg-rousseau",  result[:edge2].person_slug
    assert_equal "ed-oliver",      result[:dl1].person_slug
    assert_equal "daquan-jones",   result[:dl2].person_slug
    assert_equal "aj-epenesa",     result[:dl_flex].person_slug, "DL Flex should be the depth-2 EDGE"
  end

  # Backward-compat grouped accessors

  test "offense_starters_grouped wraps the 12-slot layout in legacy shape" do
    roster = rosters(:bills_offseason)
    g = roster.offense_starters_grouped
    assert_equal %i[qb rb wr te flex oline], g.keys
    assert_equal 1, g[:qb].size
    assert_equal 1, g[:rb].size
    assert_equal 3, g[:wr].size
    assert_equal 1, g[:te].size
    assert_equal 1, g[:flex].size
    assert_equal 5, g[:oline].size
  end

  test "defense_starters_grouped wraps the 12-slot layout" do
    roster = rosters(:bills_offseason)
    g = roster.defense_starters_grouped
    assert_equal %i[edge dl flex_dl lb cb s flex], g.keys
    assert_equal 2, g[:edge].size
    assert_equal 2, g[:dl].size
    assert_equal 1, g[:flex_dl].size
    assert_equal 2, g[:lb].size
  end
end
