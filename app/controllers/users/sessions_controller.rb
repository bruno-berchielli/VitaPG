# Passwordless sign-in: the login form takes an email, we send a short-lived
# magic link, and visiting it starts the Devise session.
class Users::SessionsController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_current_workspace

  layout "application"

  def new
    redirect_to root_path if user_signed_in?
  end

  # Always responds the same way so the form can't be used to probe which
  # emails exist.
  def create
    user = User.find_by(email: params[:email].to_s.strip.downcase)
    LoginMailer.magic_link(user).deliver_later if user

    redirect_to new_user_session_path, notice: t(".sent")
  end

  def verify
    user = User.find_by_token_for(:magic_login, params[:token].to_s)

    if user
      user.remember_me = true
      sign_in(user)
      redirect_to root_path, notice: t(".signed_in")
    else
      redirect_to new_user_session_path, alert: t(".invalid")
    end
  end

  def destroy
    sign_out(current_user)
    redirect_to new_user_session_path, notice: t(".signed_out")
  end
end
