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

    # Build a person_slug → slot label map for any athlete who lands in the
    # team's starting 28 (12 off + 12 def + 4 ST). Depth numbers are dropped —
    # depth is implied by the depth chart's row order. Flex labels derive
    # from the picked player's actual position.
    @starter_labels = {}
    roster = @team.rosters.first
    if roster
      roster.offense_starting_12.each do |slot, pick|
        next unless pick
        @starter_labels[pick.person_slug] = offense_starter_label(slot, pick)
      end
      roster.defense_starting_12.each do |slot, pick|
        next unless pick
        @starter_labels[pick.person_slug] = defense_starter_label(slot, pick)
      end
      roster.special_teams_starting_4.each do |slot, picks|
        picks.each { |p| @starter_labels[p.person_slug] ||= slot.to_s.upcase }
      end
    end
  end

  private

  def offense_starter_label(slot, pick)
    case slot
    when :qb        then "QB"
    when :rb        then "RB"
    when :wr1, :wr2, :wr3 then "WR"
    when :te        then "TE"
    when :flex      then %w[RB FB HB].include?(pick.position) ? "RB" : pick.position
    when :lt, :lg, :c, :rg, :rt then slot.to_s.upcase
    end
  end

  def defense_starter_label(slot, pick)
    case slot
    when :edge1, :edge2 then "E"
    when :dl1, :dl2     then "DL"
    when :dl_flex       then %w[EDGE DE].include?(pick.position) ? "E" : "DL"
    when :lb1, :lb2     then "LB"
    when :ss            then "SS"
    when :fs            then "FS"
    when :cb1, :cb2     then "CB"
    when :flex          then pick.position == "CB" ? "CB" : "S"
    end
  end

  public

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
