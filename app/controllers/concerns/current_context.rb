# frozen_string_literal: true

# Establishes per-request tenancy. Every domain query must go through
# Current.workspace; controllers never scope by params[:workspace_id].
module CurrentContext
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
    before_action :set_current_workspace, unless: :devise_controller?
    helper_method :current_workspace, :current_membership
  end

  private

  def set_current_user
    Current.user = current_user
  end

  def set_current_workspace
    return unless current_user

    workspace = current_user.workspaces.find_by(id: session[:workspace_id]) || current_user.default_workspace

    if workspace.nil?
      redirect_to new_workspace_path unless workspace_optional?
      return
    end

    session[:workspace_id] = workspace.id
    Current.workspace = workspace
    Current.membership = current_user.memberships.find_by(workspace: workspace)
  end

  # Screens reachable before the user has any workspace (onboarding).
  def workspace_optional?
    controller_name == "workspaces" && %w[new create].include?(action_name)
  end

  def current_workspace = Current.workspace

  def current_membership = Current.membership

  def require_workspace_manager!
    return if current_membership&.manager?

    redirect_back fallback_location: root_path, alert: t("workspaces.not_authorized")
  end
end
