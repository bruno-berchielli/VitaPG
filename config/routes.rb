Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount MissionControl::Jobs::Engine, at: "/jobs"
  mount Motor::Admin => '/admin'

  root 'home#index'
end
