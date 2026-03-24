class AgentsController < ApplicationController
  skip_before_action :require_authentication

  def index
    @agents = Agent.all.order(:name)
  end

  def show
    @agent = Agent.find_by(slug: params[:slug])
    return redirect_to agents_path, alert: "Agent not found" unless @agent
    @tasks = @agent.tasks.recent.limit(20)
    @activities = @agent.activities.recent.limit(20)
    @skills = @agent.skills
  end
end
