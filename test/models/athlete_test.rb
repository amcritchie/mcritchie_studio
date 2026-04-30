require "test_helper"

class AthleteTest < ActiveSupport::TestCase
  test "slug is generated from person_slug" do
    person = Person.create!(first_name: "Test", last_name: "Player", athlete: true)
    athlete = Athlete.create!(person_slug: person.slug, sport: "football", position: "QB")
    assert_equal "test-player-athlete", athlete.slug
  end

  test "to_param returns slug" do
    athlete = athletes(:messi_athlete)
    assert_equal "lionel-messi-athlete", athlete.to_param
  end

  test "belongs to person via slug" do
    athlete = athletes(:messi_athlete)
    assert_equal people(:messi), athlete.person
  end

  test "person_slug is required" do
    athlete = Athlete.new(person_slug: nil, sport: "football")
    assert_not athlete.valid?
    assert_includes athlete.errors[:person_slug], "can't be blank"
  end

  test "sport is required" do
    athlete = Athlete.new(person_slug: "lionel-messi", sport: nil)
    assert_not athlete.valid?
    assert_includes athlete.errors[:sport], "can't be blank"
  end

  test "person_slug is unique" do
    assert_raises ActiveRecord::RecordInvalid do
      Athlete.create!(person_slug: "lionel-messi", sport: "soccer")
    end
  end

  test "person has_one athlete_profile" do
    person = people(:messi)
    assert_equal athletes(:messi_athlete), person.athlete_profile
  end

  test "draft fields are optional" do
    person = Person.create!(first_name: "No", last_name: "Draft", athlete: true)
    athlete = Athlete.create!(person_slug: person.slug, sport: "soccer", position: "MF")
    assert_nil athlete.draft_year
    assert_nil athlete.draft_round
    assert_nil athlete.draft_pick
  end

  test "team_slug is optional" do
    person = Person.create!(first_name: "Free", last_name: "Agent", athlete: true)
    athlete = Athlete.create!(person_slug: person.slug, sport: "football", position: "QB")
    assert_nil athlete.team_slug
    assert_nil athlete.team
  end

  test "belongs to team via team_slug" do
    person = Person.create!(first_name: "Team", last_name: "Player", athlete: true)
    athlete = Athlete.create!(person_slug: person.slug, sport: "football", position: "QB", team_slug: "buffalo-bills")
    assert_equal teams(:buffalo_bills), athlete.team
  end
end
