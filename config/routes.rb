Rails.application.routes.draw do
  devise_for :users

  get "up" => "rails/health#show", as: :rails_health_check

  mount MissionControl::Jobs::Engine, at: "/jobs"

  resources :workspaces, only: %i[new create] do
    member do
      post :switch
    end
  end

  resources :database_connections do
    member do
      post :test
    end
  end

  resources :destinations do
    member do
      post :test
    end
  end

  resources :backup_routines do
    member do
      post :run
      patch :toggle
    end
  end

  resources :backup_runs, only: %i[index show] do
    member do
      get :download
    end
  end

  resources :memberships, only: %i[index create update destroy]
  resources :notification_channels, except: :show

  resource :locale, only: :update
  resource :profile, only: %i[show update]

  root "dashboard#show"
end
