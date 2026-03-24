class RegistrationsController < ApplicationController
  skip_before_action :require_authentication

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    rescue_and_log(target: @user) do
      @user.save!
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Welcome to McRitchie Studio, #{@user.display_name}!"
    end
  rescue StandardError => e
    render :new, status: :unprocessable_entity
  end

  private

  def user_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end
end
