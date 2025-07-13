Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount MissionControl::Jobs::Engine, at: "/jobs"
  mount Motor::Admin => "/admin"

  get "/google_auth/start", to: "google_auth#start", as: :google_auth_start
  get "/google_auth/callback", to: "google_auth#callback", as: :google_auth_callback
end
