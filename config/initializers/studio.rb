Studio.configure do |config|
  config.app_name = "McRitchie Studio"
  config.session_key = :studio_user_id
  config.welcome_message = ->(user) { "Welcome to McRitchie Studio, #{user.display_name}!" }
  config.registration_params = [:name, :email, :password, :password_confirmation]
  config.configure_sso_user = ->(user) { user.role = "viewer" }
end
