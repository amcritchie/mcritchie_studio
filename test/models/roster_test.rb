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
    assert_nil roster.person_at("K")
  end

  # offense_starting_12 tests

  test "offense_starting_12 returns hash with position groups" do
    roster = rosters(:bills_offseason)
    result = roster.offense_starting_12
    assert_kind_of Hash, result
    assert_equal %i[qb rb wr te oline], result.keys
  end

  test "offense_starting_12 returns correct counts per group" do
    roster = rosters(:bills_offseason)
    result = roster.offense_starting_12
    assert_equal 1, result[:qb].size
    assert_equal 2, result[:rb].size
    assert_equal 3, result[:wr].size
    assert_equal 1, result[:te].size
    assert_equal 5, result[:oline].size
  end

  test "offense_starting_12 totals 12 starters" do
    roster = rosters(:bills_offseason)
    result = roster.offense_starting_12
    total = result.values.sum(&:size)
    assert_equal 12, total
  end

  test "offense_starting_12 picks higher-graded players first" do
    roster = rosters(:bills_offseason)
    result = roster.offense_starting_12
    # WR: shakir (75.0) > coleman (71.3) > samuel (65.8) — all 3 picked, highest first
    wr_grades = result[:wr].map { |s| s.person.athlete_profile.grades.first.overall_grade }
    assert_equal wr_grades, wr_grades.sort.reverse
  end

  test "offense_starting_12 includes multi-depth RBs" do
    roster = rosters(:bills_offseason)
    result = roster.offense_starting_12
    rb_slugs = result[:rb].map(&:person_slug).sort
    assert_includes rb_slugs, "james-cook"
    assert_includes rb_slugs, "ray-davis"
  end

  # defense_starting_12 tests

  test "defense_starting_12 returns hash with position groups" do
    roster = rosters(:bills_offseason)
    result = roster.defense_starting_12
    assert_kind_of Hash, result
    assert_equal %i[edge dl flex_dl lb cb s], result.keys
  end

  test "defense_starting_12 returns correct counts per group" do
    roster = rosters(:bills_offseason)
    result = roster.defense_starting_12
    assert_equal 2, result[:edge].size
    assert_equal 2, result[:dl].size
    assert_equal 1, result[:flex_dl].size
    assert_equal 2, result[:lb].size
    assert_equal 3, result[:cb].size
    assert_equal 2, result[:s].size
  end

  test "defense_starting_12 totals 12 starters" do
    roster = rosters(:bills_offseason)
    result = roster.defense_starting_12
    total = result.values.sum(&:size)
    assert_equal 12, total
  end

  test "defense_starting_12 sorts by grade descending" do
    roster = rosters(:bills_offseason)
    result = roster.defense_starting_12
    # DL: oliver (88.0) > jones (72.5) — 2 fixed DL slots
    dl_grades = result[:dl].map { |s| s.person.athlete_profile.grades.first.overall_grade }
    assert_equal dl_grades, dl_grades.sort.reverse
  end

  test "defense_starting_12 picks both EDGE players" do
    roster = rosters(:bills_offseason)
    result = roster.defense_starting_12
    edge_slugs = result[:edge].map(&:person_slug).sort
    assert_includes edge_slugs, "von-miller"
    assert_includes edge_slugs, "greg-rousseau"
  end

  test "defense_starting_12 picks all 3 CBs" do
    roster = rosters(:bills_offseason)
    result = roster.defense_starting_12
    cb_slugs = result[:cb].map(&:person_slug).sort
    assert_equal %w[christian-benford rasul-douglas taron-johnson], cb_slugs
  end

  # Edge case: empty roster

  test "offense_starting_12 returns empty groups for roster with no spots" do
    roster = rosters(:bills_week1)
    result = roster.offense_starting_12
    assert result.values.all? { |v| v.empty? }
  end

  test "defense_starting_12 returns empty groups for roster with no spots" do
    roster = rosters(:bills_week1)
    result = roster.defense_starting_12
    assert result.values.all? { |v| v.empty? }
  end

  # Flex DL tests

  test "flex_dl picks EDGE player when higher-graded than remaining DTs" do
    roster = rosters(:bills_offseason)
    result = roster.defense_starting_12
    # Epenesa (EDGE 70.0) > Settle (DT 66.0) — flex picks the EDGE
    flex = result[:flex_dl].first
    assert_equal "aj-epenesa", flex.person_slug
    assert_equal "EDGE", flex.position
  end

  test "flex_dl picks DT when higher-graded than remaining EDGEs" do
    roster = rosters(:bills_offseason)
    # Lower Epenesa's grade below Settle's 66.0
    grade = athlete_grades(:epenesa_2025)
    grade.update!(overall_grade: 60.0)

    result = roster.defense_starting_12
    flex = result[:flex_dl].first
    assert_equal "tim-settle", flex.person_slug
    assert_equal "DT", flex.position
  end

  test "flex_dl does not duplicate players already in edge or dl groups" do
    roster = rosters(:bills_offseason)
    result = roster.defense_starting_12
    edge_slugs = result[:edge].map(&:person_slug)
    dl_slugs = result[:dl].map(&:person_slug)
    flex_slugs = result[:flex_dl].map(&:person_slug)
    assert_empty (flex_slugs & edge_slugs), "flex_dl should not contain edge players"
    assert_empty (flex_slugs & dl_slugs), "flex_dl should not contain dl players"
  end

  # OLine guardrail tests

  test "oline includes a center when top 5 by grade have none" do
    roster = rosters(:bills_week1)
    create_oline_spots(roster, [
      { pos: "LT", grade: 80.0 },
      { pos: "LG", grade: 78.0 },
      { pos: "RG", grade: 76.0 },
      { pos: "RT", grade: 74.0 },
      { pos: "G",  grade: 72.0 },
      { pos: "C",  grade: 60.0 }
    ])

    result = roster.offense_starting_12
    oline = result[:oline]
    assert_equal 5, oline.size
    centers = oline.select { |s| s.position == "C" }
    assert_equal 1, centers.size, "OLine must include exactly 1 center"
  end

  test "oline replaces duplicate center with next best non-center" do
    roster = rosters(:bills_week1)
    create_oline_spots(roster, [
      { pos: "C",  grade: 85.0 },
      { pos: "C",  grade: 80.0, depth: 2 },
      { pos: "LT", grade: 78.0 },
      { pos: "LG", grade: 76.0 },
      { pos: "RG", grade: 70.0 },
      { pos: "RT", grade: 65.0 }
    ])

    result = roster.offense_starting_12
    oline = result[:oline]
    assert_equal 5, oline.size
    centers = oline.select { |s| s.position == "C" }
    assert_equal 1, centers.size, "OLine must not have duplicate centers"
    # The higher-graded center (85.0) stays, the lower one (80.0) is replaced
    assert_equal 85.0, centers.first.person.athlete_profile.grades.first.overall_grade
  end

  private

  def create_oline_spots(roster, specs)
    specs.each_with_index do |spec, i|
      slug = "test-ol-#{spec[:pos].downcase}-#{i}"
      person = Person.create!(first_name: "Test", last_name: "OL#{i}", slug: slug, athlete: true)
      athlete = Athlete.create!(person_slug: person.slug, sport: "football", position: spec[:pos], slug: "#{slug}-athlete")
      AthleteGrade.create!(athlete_slug: athlete.slug, season_slug: "2025-nfl", overall_grade: spec[:grade], slug: "#{slug}-grade")
      roster.roster_spots.create!(person_slug: person.slug, position: spec[:pos], side: "offense", depth: spec[:depth] || 1)
    end
  end
end
