class LoginMailer < ApplicationMailer
  def magic_link(user)
    @user = user
    @url = verify_user_session_url(token: user.generate_token_for(:magic_login))

    # No SMTP in development: the link in the log is the way in.
    Rails.logger.info("[LoginMailer] Magic link for #{user.email}: #{@url}") if Rails.env.development?

    mail(to: user.email, subject: t("login_mailer.magic_link.subject"))
  end
end
