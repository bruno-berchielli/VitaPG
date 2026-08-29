class ApplicationController < ActionController::Base
  include CurrentContext
  include LocaleDetection

  allow_browser versions: :modern

  before_action :authenticate_user!
end
