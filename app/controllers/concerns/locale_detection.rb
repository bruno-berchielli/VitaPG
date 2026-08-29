# frozen_string_literal: true

module LocaleDetection
  extend ActiveSupport::Concern

  included do
    before_action :set_locale
  end

  private

  # A user's explicit preference outranks the session pick, which outranks the
  # browser's Accept-Language guess.
  def set_locale
    I18n.locale = user_locale || session_locale || browser_locale || I18n.default_locale
  end

  def user_locale
    locale = current_user&.locale
    locale if supported_locale?(locale)
  end

  def session_locale
    locale = session[:locale].presence
    locale if supported_locale?(locale)
  end

  def browser_locale
    header = request.env["HTTP_ACCEPT_LANGUAGE"]
    return if header.blank?

    supported = I18n.available_locales.map(&:to_s)

    header.split(",").each do |lang|
      locale = lang.split(";").first.to_s.strip
      return locale if supported.include?(locale)

      language_code = locale.split("-").first
      match = supported.find { |l| l == language_code || l.start_with?("#{language_code}-") }
      return match if match
    end

    nil
  end

  def supported_locale?(locale)
    I18n.available_locales.map(&:to_s).include?(locale.to_s)
  end
end
