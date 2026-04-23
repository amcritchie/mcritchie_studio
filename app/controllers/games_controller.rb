class GamesController < ApplicationController
  skip_before_action :require_authentication

  # GET /games/:year/week/:week
  def week
    @year = params[:year].to_i
    @week = params[:week].to_i

    season = Season.find_by(year: @year, league: "nfl")
    return redirect_to root_path, alert: "Season not found" unless season

    @slate = season.slates.find_by(sequence: @week)
    return redirect_to root_path, alert: "Week not found" unless @slate

    @games = @slate.games
                   .includes(:home_team, :away_team)
                   .order(:kickoff_at)

    @games_by_day = @games.group_by { |g| g.display_day }
  end

  # GET /games/:year/week/:week/:slug
  def show
    @year = params[:year].to_i
    @week = params[:week].to_i

    season = Season.find_by(year: @year, league: "nfl")
    return redirect_to root_path, alert: "Season not found" unless season

    @slate = season.slates.find_by(sequence: @week)
    return redirect_to root_path, alert: "Week not found" unless @slate

    @game = @slate.games.includes(:home_team, :away_team).find_by(slug: params[:slug])
    return redirect_to games_week_path(@year, @week), alert: "Game not found" unless @game

    # Load rosters for this slate (or fall back to offseason)
    roster_includes = { roster_spots: { person: { athlete_profile: :grades } } }

    @home_roster = Roster.includes(roster_includes)
                         .find_by(team_slug: @game.home_team_slug, slate_slug: @slate.slug)
    @home_roster ||= Roster.includes(roster_includes)
                           .find_by(team_slug: @game.home_team_slug, slate_slug: "#{@year}-nfl-offseason")

    @away_roster = Roster.includes(roster_includes)
                         .find_by(team_slug: @game.away_team_slug, slate_slug: @slate.slug)
    @away_roster ||= Roster.includes(roster_includes)
                           .find_by(team_slug: @game.away_team_slug, slate_slug: "#{@year}-nfl-offseason")

    # Load team unit rankings for matchup display
    season = Season.find_by(year: @year, league: "nfl")
    if season
      @home_rankings = TeamRanking.where(team_slug: @game.home_team_slug, season_slug: season.slug, week: nil).index_by(&:rank_type)
      @away_rankings = TeamRanking.where(team_slug: @game.away_team_slug, season_slug: season.slug, week: nil).index_by(&:rank_type)
    else
      @home_rankings = {}
      @away_rankings = {}
    end
  end
end
