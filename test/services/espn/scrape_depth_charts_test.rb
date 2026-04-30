require "test_helper"

class Espn::ScrapeDepthChartsTest < ActiveSupport::TestCase
  setup do
    @service = Espn::ScrapeDepthCharts.new
    @bills = teams(:buffalo_bills)
    @dolphins = teams(:miami_dolphins)
  end

  # ─── lookup_person ───────────────────────────────────────────────────────────

  test "lookup_person resolves by espn_id" do
    person = Person.create!(first_name: "Lookup", last_name: "Espn", athlete: true)
    athlete = Athlete.create!(person_slug: person.slug, sport: "football", espn_id: "777")

    found_person, found_athlete = @service.send(:lookup_person, "777", "Whatever Name")
    assert_equal person, found_person
    assert_equal athlete, found_athlete
  end

  test "lookup_person falls back to name match when espn_id misses" do
    person = Person.create!(first_name: "Fallback", last_name: "Player", athlete: true)
    Athlete.create!(person_slug: person.slug, sport: "football")

    found_person, found_athlete = @service.send(:lookup_person, nil, "Fallback Player")
    assert_equal person, found_person
    assert_equal person.athlete_profile, found_athlete
  end

  test "lookup_person returns nils when no match" do
    person, athlete = @service.send(:lookup_person, "no-such-id", "Nobody Existing")
    assert_nil person
    assert_nil athlete
  end

  # ─── ensure_active_contract ──────────────────────────────────────────────────

  test "ensure_active_contract creates a Contract when player is new to team" do
    person = Person.create!(first_name: "New", last_name: "Signing", athlete: true)
    athlete = Athlete.create!(person_slug: person.slug, sport: "football")

    assert_difference -> { Contract.count }, 1 do
      @service.send(:ensure_active_contract, person, athlete, @bills.slug, "QB")
    end

    contract = Contract.find_by(person_slug: person.slug, team_slug: @bills.slug)
    assert_equal "active", contract.contract_type
    assert_equal "QB", contract.position
    assert_equal 1, @service.stats[:contracts_created]
  end

  test "ensure_active_contract sets Athlete.team_slug" do
    person = Person.create!(first_name: "Team", last_name: "Update", athlete: true)
    athlete = Athlete.create!(person_slug: person.slug, sport: "football")

    @service.send(:ensure_active_contract, person, athlete, @bills.slug, nil)
    assert_equal @bills.slug, athlete.reload.team_slug
    assert_equal 1, @service.stats[:team_slug_updates]
  end

  test "ensure_active_contract is a no-op when player already on team and team_slug current" do
    person = Person.create!(first_name: "Stable", last_name: "Roster", athlete: true)
    athlete = Athlete.create!(person_slug: person.slug, sport: "football", team_slug: @bills.slug)
    Contract.create!(person_slug: person.slug, team_slug: @bills.slug, contract_type: "active")

    assert_no_difference -> { Contract.count } do
      @service.send(:ensure_active_contract, person, athlete, @bills.slug, "QB")
    end

    assert_equal 0, @service.stats[:contracts_created]
    assert_equal 0, @service.stats[:contracts_revived]
    assert_equal 0, @service.stats[:contracts_expired]
    assert_equal 0, @service.stats[:team_slug_updates]
  end

  test "ensure_active_contract expires stale contracts on other teams" do
    person = Person.create!(first_name: "Traded", last_name: "Player", athlete: true)
    athlete = Athlete.create!(person_slug: person.slug, sport: "football", team_slug: @dolphins.slug)
    old_contract = Contract.create!(person_slug: person.slug, team_slug: @dolphins.slug, contract_type: "active")

    @service.send(:ensure_active_contract, person, athlete, @bills.slug, "QB")

    assert_equal Date.today - 1, old_contract.reload.expires_at
    assert old_contract.expired?
    assert_equal @bills.slug, athlete.reload.team_slug
    assert_equal 1, @service.stats[:contracts_expired]
  end

  test "ensure_active_contract revives an expired contract when player returns" do
    person = Person.create!(first_name: "Returning", last_name: "Vet", athlete: true)
    athlete = Athlete.create!(person_slug: person.slug, sport: "football")
    contract = Contract.create!(person_slug: person.slug, team_slug: @bills.slug,
                                 contract_type: "active", expires_at: Date.today - 30)

    @service.send(:ensure_active_contract, person, athlete, @bills.slug, "QB")

    contract.reload
    assert_nil contract.expires_at
    assert contract.active?
    assert_equal 1, @service.stats[:contracts_revived]
  end

  # ─── DepthChart shell auto-create ────────────────────────────────────────────

  test "scrape_team auto-creates DepthChart shell when missing" do
    DepthChart.where(team_slug: @bills.slug).destroy_all
    refute DepthChart.exists?(team_slug: @bills.slug)

    # fetch_groups will return nil (no real network) but the shell create runs first
    @service.send(:scrape_team, "buf", @bills.slug)

    assert DepthChart.exists?(team_slug: @bills.slug)
    assert_equal 1, @service.stats[:depth_charts_created]
  end

  # ─── apply_row preserves ESPN's verbatim order ───────────────────────────────

  test "apply_row preserves ESPN order even when interleaving new and existing players" do
    # Reproduces the NE Patriots LT bug: ESPN published [Campbell, Hudson, Lomu, Metz]
    # but the old logic bucketed existing entries before new ones, producing
    # [Hudson, Metz, Campbell, Lomu]. With the fix, ESPN's order is preserved.
    chart = DepthChart.find_or_create_by!(team_slug: @bills.slug)

    # Pre-existing: Hudson + Metz both at LT from a previous seed pass
    hudson = Person.create!(first_name: "James", last_name: "Hudson", athlete: true)
    Athlete.create!(person_slug: hudson.slug, sport: "football", espn_id: "h-1")
    Contract.create!(person_slug: hudson.slug, team_slug: @bills.slug, contract_type: "active")
    chart.depth_chart_entries.create!(person_slug: hudson.slug, position: "LT", side: "offense", depth: 1)

    metz = Person.create!(first_name: "Lorenz", last_name: "Metz", athlete: true)
    Athlete.create!(person_slug: metz.slug, sport: "football", espn_id: "m-1")
    Contract.create!(person_slug: metz.slug, team_slug: @bills.slug, contract_type: "active")
    chart.depth_chart_entries.create!(person_slug: metz.slug, position: "LT", side: "offense", depth: 2)

    # Brand-new: Campbell + Lomu have Athletes but no DepthChartEntry yet
    campbell = Person.create!(first_name: "Will", last_name: "Campbell", athlete: true)
    Athlete.create!(person_slug: campbell.slug, sport: "football", espn_id: "c-1")
    lomu = Person.create!(first_name: "Caleb", last_name: "Lomu", athlete: true)
    Athlete.create!(person_slug: lomu.slug, sport: "football", espn_id: "l-1")

    # Mimic ESPN's row format — espn_id is parsed out of href via /id/(\d+)/
    espn_athletes = [
      { "name" => "Will Campbell",      "href" => "/nfl/player/_/id/c-1/" },
      { "name" => "James Hudson",       "href" => "/nfl/player/_/id/h-1/" },
      { "name" => "Caleb Lomu",         "href" => "/nfl/player/_/id/l-1/" },
      { "name" => "Lorenz Metz",        "href" => "/nfl/player/_/id/m-1/" }
    ]

    @service.send(:apply_row, chart, "LT", "offense", espn_athletes, @bills.slug)

    ordered = chart.depth_chart_entries.where(position: "LT").order(:depth).pluck(:person_slug)
    assert_equal [campbell.slug, hudson.slug, lomu.slug, metz.slug], ordered,
                 "ESPN's order [Campbell, Hudson, Lomu, Metz] must be preserved verbatim"
  end

  test "apply_row respects locked entries even when ESPN places someone in the locked depth" do
    chart = DepthChart.find_or_create_by!(team_slug: @bills.slug)

    starter = Person.create!(first_name: "Locked", last_name: "Starter", athlete: true)
    Athlete.create!(person_slug: starter.slug, sport: "football", espn_id: "s-1")
    Contract.create!(person_slug: starter.slug, team_slug: @bills.slug, contract_type: "active")
    chart.depth_chart_entries.create!(person_slug: starter.slug, position: "QB", side: "offense", depth: 1, locked: true)

    backup = Person.create!(first_name: "Espn", last_name: "Newcomer", athlete: true)
    Athlete.create!(person_slug: backup.slug, sport: "football", espn_id: "n-1")

    espn_athletes = [{ "name" => "Espn Newcomer", "href" => "/nfl/player/_/id/n-1/" }]
    @service.send(:apply_row, chart, "QB", "offense", espn_athletes, @bills.slug)

    # Locked starter held depth 1; backup got the next free slot.
    assert_equal starter.slug, chart.depth_chart_entries.find_by(position: "QB", depth: 1).person_slug
    assert_equal backup.slug,  chart.depth_chart_entries.find_by(position: "QB", depth: 2).person_slug
  end
end
