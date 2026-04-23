require "test_helper"

class PeopleControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:alex)
  end

  test "index renders without login" do
    get people_path
    assert_response :success
  end

  test "merge page requires authentication" do
    get merge_people_path
    assert_response :redirect
  end

  test "merge page renders when logged in" do
    log_in_as(@admin)
    get merge_people_path
    assert_response :success
  end

  test "duplicates page requires authentication" do
    get duplicates_people_path
    assert_response :redirect
  end

  test "duplicates page renders when logged in" do
    log_in_as(@admin)
    get duplicates_people_path
    assert_response :success
  end

  test "merge_execute moves contracts and deletes source" do
    log_in_as(@admin)

    # Create two people — keep and merge (unique names to avoid fixture collision)
    keep = Person.create!(first_name: "Terrence", last_name: "Ferguson", athlete: true)
    source = Person.create!(first_name: "Terrance", last_name: "Ferguson", athlete: true)

    # Give source a contract
    team = teams(:argentina) # any team
    Contract.create!(person_slug: source.slug, team_slug: team.slug, position: "TE", contract_type: "active")

    assert_difference "Person.count", -1 do
      post merge_people_path, params: { keep_slug: keep.slug, merge_slug: source.slug }
    end

    assert_redirected_to people_path
    assert_nil Person.find_by(slug: source.slug)

    # Contract moved to keep
    contract = Contract.find_by(person_slug: keep.slug, team_slug: team.slug)
    assert_not_nil contract

    # Alias added
    keep.reload
    assert_includes keep.aliases, "Terrance Ferguson"
  end

  test "merge_execute prevents merging into self" do
    log_in_as(@admin)
    person = people(:messi)
    post merge_people_path, params: { keep_slug: person.slug, merge_slug: person.slug }
    assert_redirected_to merge_people_path
    follow_redirect!
    assert_response :success
  end

  test "merge_execute requires both people" do
    log_in_as(@admin)
    post merge_people_path, params: { keep_slug: "nonexistent", merge_slug: "also-nonexistent" }
    assert_redirected_to merge_people_path
  end

  test "merge_execute re-parents athlete when keep has none" do
    log_in_as(@admin)

    keep = Person.create!(first_name: "Jaxon", last_name: "Testmerge", athlete: true)
    source = Person.create!(first_name: "Jackson", last_name: "Testmerge", athlete: true)
    source_athlete = Athlete.create!(person_slug: source.slug, sport: "football", position: "QB")

    post merge_people_path, params: { keep_slug: keep.slug, merge_slug: source.slug }

    assert_nil Person.find_by(slug: source.slug)
    source_athlete.reload
    assert_equal keep.slug, source_athlete.person_slug
  end
end
