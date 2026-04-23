class NflController < ApplicationController
  skip_before_action :require_authentication

  def index
    @season = Season.find_by(year: 2025, league: "nfl")
    @team_count = Team.nfl.count
    @person_count = Person.count
    @game_count = @season ? Game.joins(slate: :season).where(seasons: { slug: @season.slug }, slates: { sequence: 1 }).count : 0
    @qb_count = Athlete.where(position: "QB").joins(:grades).distinct.count
    @oline_count = Athlete.where(position: %w[LT LG C RG RT OT OG]).joins(:grades).distinct.count
    @wr_count = Athlete.where(position: %w[WR TE]).joins(:grades).distinct.count
    @rb_count = Athlete.where(position: %w[RB FB HB]).joins(:grades).distinct.count
    @def_count = Athlete.where(position: %w[EDGE DE DT NT DL LB ILB OLB MLB CB S FS SS]).joins(:grades).distinct.count
    @pass_rush_count = Athlete.where(position: %w[EDGE DE DT NT]).joins(:grades).distinct.count
    @coverage_count = Athlete.where(position: %w[CB S FS SS]).joins(:grades).distinct.count
    @coach_count = Coach.where(sport: "football").count
    @pass_first_count = @season ? CoachRanking.where(rank_type: "pass_first", season_slug: @season.slug).count : 0
    @prospect_count = Athlete.where(sport: "football").where.not(draft_pick: nil)
                              .joins("INNER JOIN contracts ON contracts.person_slug = athletes.person_slug AND contracts.contract_type = 'draft_pick'")
                              .distinct.count
    @contract_count = Contract.joins(:team).where(teams: { league: "nfl" }).count
    @team_ranking_count = TeamRanking.count
  end
end
