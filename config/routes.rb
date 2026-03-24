Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "dashboard#index"

  # Auth
  get  "login",  to: "sessions#new"
  post "login",  to: "sessions#create"
  get  "logout", to: "sessions#destroy"

  get  "signup", to: "registrations#new"
  post "signup", to: "registrations#create"

  get "auth/:provider/callback", to: "omniauth_callbacks#create"
  get "auth/failure", to: "omniauth_callbacks#failure"

  # HTML
  resources :agents, only: [:index, :show], param: :slug
  resources :tasks, param: :slug do
    member do
      post :queue
      post :start
      post :complete
      post :fail_task
      post :archive
    end
  end
  resources :activities, only: [:index]
  resources :usages, only: [:index]
  resources :error_logs, only: [:index, :show]

  # JSON API
  namespace :api do
    namespace :v1 do
      resources :agents, only: [:index, :show, :update], param: :slug
      resources :tasks, only: [:index, :show, :create, :update], param: :slug do
        member do
          post :queue
          post :start
          post :complete
          post :fail_task
        end
      end
      resources :activities, only: [:index, :create]
      resources :usages, only: [:index, :create]
    end
  end
end
