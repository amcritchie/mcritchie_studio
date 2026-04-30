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
end
