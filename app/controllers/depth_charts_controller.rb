class DepthChartsController < ApplicationController
  skip_before_action :require_authentication, only: [:show]
  before_action :set_team, only: [:show, :reorder]

  POSITION_ORDER = {
    "offense" => %w[QB RB FB WR TE LT LG C RG RT OT OG T G],
    "defense" => %w[EDGE DE DT NT DL LB ILB OLB MLB CB S FS SS],
    "special_teams" => %w[K P LS]
  }.freeze

  def show
    @season = Season.find_by(year: 2025, league: "nfl")
    @chart = @team.depth_chart
    return redirect_to nfl_rosters_path, alert: "No depth chart for #{@team.name}" unless @chart

    grades = AthleteGrade.where(season_slug: @season&.slug)
                         .where(athlete_slug: @chart.depth_chart_entries.joins(person: :athlete_profile).pluck("athletes.slug"))
                         .index_by(&:athlete_slug)
    @grades_by_person = {}
    @chart.depth_chart_entries.includes(person: { athlete_profile: :image_caches }).each do |e|
      ath = e.person.athlete_profile
      @grades_by_person[e.person_slug] = grades[ath.slug] if ath
    end

    @entries_by_side = @chart.depth_chart_entries
                             .includes(person: { athlete_profile: :image_caches })
                             .group_by(&:side)
                             .transform_values do |entries|
      entries.group_by(&:position)
             .sort_by { |pos, _| POSITION_ORDER[entries.first.side]&.index(pos) || 99 }
             .to_h
             .transform_values { |es| es.sort_by(&:depth) }
    end

    # Build a person_slug → slot label map (e.g. "QB", "WR1", "FLX") for any
    # athlete who lands in the team's starting 28 (12 off + 12 def + 4 ST).
    @starter_labels = {}
    roster = @team.rosters.first
    if roster
      offense_labels = { qb: "QB", rb: "RB", wr1: "WR1", wr2: "WR2", wr3: "WR3",
                          te: "TE", flex: "FLX", lt: "LT", lg: "LG", c: "C", rg: "RG", rt: "RT" }
      defense_labels = { edge1: "E1", edge2: "E2", dl1: "DL1", dl2: "DL2", dl_flex: "DLF",
                          lb1: "LB1", lb2: "LB2", ss: "SS", fs: "FS",
                          cb1: "CB1", cb2: "CB2", flex: "NB" }

      roster.offense_starting_12.each do |slot, pick|
        @starter_labels[pick.person_slug] = offense_labels[slot] if pick
      end
      roster.defense_starting_12.each do |slot, pick|
        @starter_labels[pick.person_slug] = defense_labels[slot] if pick
      end
      roster.special_teams_starting_4.each do |slot, picks|
        picks.each { |p| @starter_labels[p.person_slug] ||= slot.to_s.upcase }
      end
    end
  end

  def reorder
    chart = @team.depth_chart
    return render json: { error: "no chart" }, status: :not_found unless chart

    rescue_and_log(target: chart) do
      position = params.require(:position)
      ids      = Array(params.require(:entry_ids))

      ActiveRecord::Base.transaction do
        ids.each_with_index do |id, idx|
          entry = chart.depth_chart_entries.find(id)
          next if entry.locked
          entry.update!(depth: idx + 1)
        end
      end
      render json: { ok: true, position: position }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "entry not found" }, status: :not_found
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def toggle_lock
    entry = DepthChartEntry.find(params[:id])
    rescue_and_log(target: entry) do
      entry.update!(locked: !entry.locked)
      render json: { ok: true, locked: entry.locked }
    end
  rescue ActiveRecord::RecordNotFound
    render json: { error: "entry not found" }, status: :not_found
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_team
    @team = Team.find_by(slug: params[:slug])
    redirect_to nfl_rosters_path, alert: "Team not found" unless @team
  end
end
