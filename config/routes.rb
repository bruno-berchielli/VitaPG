Rails.application.routes.draw do
  # Google OAuth routes only exist when the provider is configured (see User).
  omniauth_controllers = User.google_auth_configured? ? { omniauth_callbacks: "users/omniauth_callbacks" } : {}
  devise_for :users, skip: %i[sessions registrations passwords], controllers: omniauth_controllers
  devise_scope :user do
    get "login" => "users/sessions#new", as: :new_user_session
    post "login" => "users/sessions#create", as: :user_session
    get "login/verify" => "users/sessions#verify", as: :verify_user_session
    delete "logout" => "users/sessions#destroy", as: :destroy_user_session
  end

  get "up" => "rails/health#show", as: :rails_health_check

  mount MissionControl::Jobs::Engine, at: "/jobs"

  resources :workspaces, only: %i[index new create edit update] do
    member do
      post :switch
    end
    resource :join_request, only: %i[create]
  end
  resources :join_requests, only: [] do
    member do
      post :approve
      post :deny
    end
  end

  namespace :admin do
    resources :users, only: %i[index create edit update] do
      member do
        patch :toggle_superadmin
      end
      resources :memberships, only: :create
    end
    resources :memberships, only: %i[update destroy]
  end

  get "search" => "searches#show", as: :search

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
  resource :profile, only: %i[show update] do
    patch :appearance, action: :update_appearance
  end

  root "dashboard#show"
end
