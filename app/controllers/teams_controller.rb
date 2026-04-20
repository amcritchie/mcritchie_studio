class TeamsController < ApplicationController
  skip_before_action :require_authentication

  def index
    @teams = Team.includes(:people).order(:name)
  end
end
