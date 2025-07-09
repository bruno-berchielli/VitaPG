Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  mount MissionControl::Jobs::Engine, at: "/jobs"
  mount Motor::Admin => "/admin"

  get "/auth/google/start", to: "google_auth#start"
  get "/auth/google/callback", to: "google_auth#callback"
end
