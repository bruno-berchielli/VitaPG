# Google sign-in. Existing users always get in; unknown emails are provisioned
# automatically only when their domain is on the GOOGLE_ALLOWED_DOMAINS list.
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def google_oauth2
    auth = request.env["omniauth.auth"]
    email = auth.info.email.to_s.downcase
    user = User.find_by(email: email)
    user ||= provision(email, auth.info.name)

    if user
      sign_in_and_redirect user, event: :authentication
    else
      redirect_to new_user_session_path, alert: t("sessions.google_not_allowed")
    end
  end

  def failure
    redirect_to new_user_session_path, alert: t("sessions.google_failed")
  end

  private

  def provision(email, name)
    domain = email.split("@").last
    return nil unless User.google_allowed_domains.include?(domain)

    User.create!(email: email, name: name.presence || email.split("@").first)
  end
end
