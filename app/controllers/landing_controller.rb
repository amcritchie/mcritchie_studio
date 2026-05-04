class LandingController < ApplicationController
  skip_before_action :require_authentication

  def index
  end

  def terms
  end

  def privacy
  end
end
