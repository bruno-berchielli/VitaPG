class LocalesController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :set_current_workspace

  def update
    locale = params[:locale].to_s

    if I18n.available_locales.map(&:to_s).include?(locale)
      session[:locale] = locale
      current_user&.update(preferences: (current_user.preferences || {}).merge("locale" => locale))
    end

    redirect_back_or_to root_path
  end
end
