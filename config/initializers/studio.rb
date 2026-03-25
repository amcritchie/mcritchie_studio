Studio.configure do |config|
  config.app_name = "McRitchie Studio"
  config.welcome_message = ->(user) { "Welcome to McRitchie Studio, #{user.display_name}!" }
  config.registration_params = [:name, :email, :password, :password_confirmation]
end
