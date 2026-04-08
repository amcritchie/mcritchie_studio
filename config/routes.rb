Rails.application.routes.draw do
  mount ActionCable.server => "/cable"

  get "up" => "rails/health#show", as: :rails_health_check
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root "landing#index"

  get "dashboard", to: "dashboard#index"
  resources :chat, only: [:index, :create]
  resources :schedule, only: [:index]

  Studio.routes(self)

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

  # Expense Tracker
  resources :payment_methods, path: "expenses/payment_methods", param: :slug, except: [:show]
  resources :expense_uploads, path: "expenses/uploads", param: :slug, only: [:index, :new, :create, :show, :destroy] do
    member do
      post :process_file
      post :evaluate
    end
  end
  resources :expense_transactions, path: "expenses/transactions", param: :slug, only: [:index, :show, :update] do
    member do
      post :answer_review
      post :toggle_exclude
    end
    collection do
      get :export
      get :summary
      get :tax_report
    end
  end

  get "docs", to: "docs#index"
  get "docs/*path", to: "docs#show", as: :doc

  # JSON API
  namespace :api do
    namespace :v1 do
      post "auth", to: "auth#create"
      resources :agents, only: [:index, :show, :update], param: :slug
      resources :tasks, only: [:index, :show, :create, :update, :destroy], param: :slug do
        member do
          post :queue
          post :start
          post :complete
          post :fail_task
          post :archive
        end
      end
      resources :activities, only: [:index, :create]
      resources :usages, only: [:index, :create]
    end
  end
end
