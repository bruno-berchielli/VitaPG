# Self-hosted default: the first account bootstraps the instance, after which
# public signup closes and new people join by invitation (Members screen).
# Set VITAPG_OPEN_SIGNUPS=1 to keep registration open.
class Users::RegistrationsController < Devise::RegistrationsController
  before_action :block_when_closed, only: %i[new create]

  private

  def block_when_closed
    return if ENV["VITAPG_OPEN_SIGNUPS"] == "1"
    return unless User.exists?

    redirect_to new_user_session_path, alert: t("devise.registrations.closed")
  end
end
