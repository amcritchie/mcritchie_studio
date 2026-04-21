class NflController < ApplicationController
  skip_before_action :require_authentication

  def index
    @season = Season.find_by(year: 2025, league: "nfl")
    @team_count = Team.nfl.count
    @person_count = Person.joins(:contracts).merge(Contract.joins(:team).where(teams: { league: "nfl" })).distinct.count
    @game_count = @season ? Game.joins(slate: :season).where(seasons: { slug: @season.slug }, slates: { sequence: 1 }).count : 0
    @qb_count = Athlete.where(position: "QB").joins(:grades).distinct.count
    @oline_count = Athlete.where(position: %w[LT LG C RG RT OT OG]).joins(:grades).distinct.count
  end
end
