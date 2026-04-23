require "test_helper"

class GamesControllerTest < ActionDispatch::IntegrationTest
  test "week page loads" do
    get games_week_path(2025, 1)
    assert_response :success
    assert_select "h1", /NFL Week 1/
  end

  test "week redirects for missing season" do
    get games_week_path(1999, 1)
    assert_redirected_to root_path
  end

  test "week redirects for missing week" do
    get games_week_path(2025, 99)
    assert_redirected_to root_path
  end

  test "show page loads" do
    game = games(:bills_at_dolphins)
    get game_show_path(2025, 1, game.slug)
    assert_response :success
  end

  test "show redirects for missing game" do
    get game_show_path(2025, 1, "nonexistent-game")
    assert_redirected_to games_week_path(2025, 1)
  end

  test "show does not require authentication" do
    game = games(:bills_at_dolphins)
    get game_show_path(2025, 1, game.slug)
    assert_response :success
  end
end
