Rails.application.routes.draw do
  devise_for :users
  get "up" => "rails/health#show", as: :rails_health_check

  mount MissionControl::Jobs::Engine, at: "/jobs"

  resources :workspaces, only: %i[new create] do
    member do
      post :switch
    end
  end

  root "home#index"
end
