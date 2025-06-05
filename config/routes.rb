Rails.application.routes.draw do
  mount Motor::Admin => '/motor_admin'
  get "up" => "rails/health#show", as: :rails_health_check

  mount MissionControl::Jobs::Engine, at: "/jobs"
end
