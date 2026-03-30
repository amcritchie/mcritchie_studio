class DashboardController < ApplicationController
  skip_before_action :require_authentication

  def index
    @agents = Agent.all.order(:position)
    @task_counts = Task.group(:stage).count
    @recent_activities = Activity.recent.limit(20)
  end
end
