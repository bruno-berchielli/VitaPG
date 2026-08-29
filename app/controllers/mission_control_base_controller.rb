# Job dashboard access requires a signed-in user (self-hosted install: every
# account holder is an operator).
class MissionControlBaseController < ActionController::Base
  include Devise::Controllers::Helpers

  before_action :authenticate_user!
end
