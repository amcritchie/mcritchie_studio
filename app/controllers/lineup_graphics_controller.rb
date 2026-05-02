class LineupGraphicsController < ApplicationController
  include LineupLabelsHelper

  layout "lineup_graphic"
  skip_before_action :require_authentication, only: [:show]

  def show
    @team = Team.find_by(slug: params[:slug])
    return redirect_to nfl_rosters_path, alert: "Team not found" unless @team

    @roster = @team.rosters.first
    return redirect_to nfl_rosters_path, alert: "No roster for #{@team.name}" unless @roster

    @offense = @roster.offense_starting_12.map { |slot, pick| [offense_slot_label(slot, pick), pick] }
    @defense = @roster.defense_starting_12.map { |slot, pick| [defense_slot_label(slot, pick), pick] }
    @special = @roster.special_teams_starting_4.flat_map { |slot, picks| picks.map { |p| [slot.to_s.upcase, p] } }
  end
end
