class ActivitiesController < ApplicationController
  skip_before_action :require_authentication

  def index
    @activities = Activity.recent
    @activities = @activities.where(agent_slug: params[:agent]) if params[:agent].present?
    @activities = @activities.by_type(params[:type]) if params[:type].present?
    @activities = @activities.limit(100)
  end
end
