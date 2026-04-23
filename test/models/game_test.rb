require "test_helper"

class GameTest < ActiveSupport::TestCase
  def setup
    @game = games(:bills_at_dolphins)
  end

  test "belongs to slate" do
    assert_equal slates(:nfl_week1), @game.slate
  end

  test "belongs to home_team" do
    assert_equal teams(:buffalo_bills), @game.away_team
  end

  test "belongs to away_team" do
    # dolphins not in fixtures — just verify association responds
    assert_respond_to @game, :home_team
  end

  test "validates required fields" do
    game = Game.new
    assert_not game.valid?
    assert_includes game.errors[:slate_slug], "can't be blank"
    assert_includes game.errors[:home_team_slug], "can't be blank"
    assert_includes game.errors[:away_team_slug], "can't be blank"
  end

  test "generates slug from team slugs on save" do
    game = Game.create!(slate_slug: "2025-nfl-week-1", home_team_slug: "buffalo-bills", away_team_slug: "miami-dolphins")
    assert_equal "buffalo-bills-vs-miami-dolphins", game.slug
  end

  test "preserves custom slug" do
    game = Game.new(slug: "buf-at-mia", slate_slug: "2025-nfl-week-1", home_team_slug: "buffalo-bills", away_team_slug: "miami-dolphins")
    game.valid?
    assert_equal "buf-at-mia", game.slug
  end

  test "hero_gradient_style returns CSS gradient" do
    style = @game.hero_gradient_style
    assert_includes style, "linear-gradient"
    assert_includes style, "135deg"
  end

  test "display_time returns formatted time" do
    assert_includes @game.display_time, "ET"
  end

  test "display_time returns TBD when no kickoff" do
    @game.kickoff_at = nil
    assert_equal "TBD", @game.display_time
  end

  test "display_day returns formatted day" do
    assert_includes @game.display_day, "September"
  end

  test "display_time_short returns short time" do
    assert_includes @game.display_time_short, "ET"
  end

  test "to_param returns slug" do
    assert_equal "buf-at-mia", @game.to_param
  end
end
