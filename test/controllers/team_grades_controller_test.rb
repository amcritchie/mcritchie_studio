require "test_helper"

class TeamGradesControllerTest < ActionDispatch::IntegrationTest
  test "show renders for a known NFL team" do
    bills = teams(:buffalo_bills)
    get nfl_team_grades_path(team_slug: bills.slug)
    assert_response :success
  end

  test "show redirects with alert for an unknown team" do
    get nfl_team_grades_path(team_slug: "no-such-team")
    assert_redirected_to nfl_hub_path
    assert_match(/not found/i, flash[:alert].to_s)
  end

  test "show redirects with alert for a non-NFL team" do
    # Argentina is a FIFA team — controller scopes to league=nfl.
    get nfl_team_grades_path(team_slug: teams(:argentina).slug)
    assert_redirected_to nfl_hub_path
  end

  test "show is publicly accessible (no login required)" do
    bills = teams(:buffalo_bills)
    get nfl_team_grades_path(team_slug: bills.slug)
    assert_response :success
  end
end
