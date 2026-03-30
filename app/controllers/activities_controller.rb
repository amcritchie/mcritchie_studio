class ActivitiesController < ApplicationController
  skip_before_action :require_authentication

  def index
    @activities = Activity.recent
    agent_filter = params[:agent_slug].presence || params[:agent].presence
    @activities = @activities.where(agent_slug: agent_filter) if agent_filter
    type_filter = params[:activity_type].presence || params[:type].presence
    @activities = @activities.by_type(type_filter) if type_filter
    @activities = @activities.limit(100)
  end
end
