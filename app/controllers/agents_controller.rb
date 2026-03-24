class AgentsController < ApplicationController
  skip_before_action :require_authentication

  def index
    @agents = Agent.all.order(:name)
  end

  def show
    @agent = Agent.find_by!(slug: params[:slug])
    @tasks = @agent.tasks.recent.limit(20)
    @activities = @agent.activities.recent.limit(20)
    @skills = @agent.skills
  end
end
