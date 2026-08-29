# frozen_string_literal: true

# Establishes per-request tenancy. Every domain query must go through
# Current.workspace; controllers never scope by params[:workspace_id].
# Superadmins can enter any workspace and act as managers everywhere.
module CurrentContext
  extend ActiveSupport::Concern

  included do
    before_action :set_current_user
    before_action :set_current_workspace, unless: :devise_controller?
    helper_method :current_workspace, :current_membership, :workspace_manager?
  end

  private

  def set_current_user
    Current.user = current_user
  end

  def set_current_workspace
    return unless current_user

    workspace = current_user.accessible_workspaces.find_by(id: session[:workspace_id]) ||
                current_user.default_workspace

    if workspace.nil?
      redirect_to workspaces_path unless workspace_optional?
      return
    end

    session[:workspace_id] = workspace.id
    Current.workspace = workspace
    Current.membership = current_user.memberships.find_by(workspace: workspace)
  end

  # Screens reachable before the user belongs to any workspace: the directory
  # (to request access), workspace creation and the profile.
  def workspace_optional?
    (controller_name == "workspaces" && %w[index new create].include?(action_name)) ||
      controller_name == "join_requests" ||
      controller_name == "profiles" ||
      controller_name == "locales" ||
      controller_name == "sessions"
  end

  def current_workspace = Current.workspace

  def current_membership = Current.membership

  def workspace_manager?(workspace = Current.workspace)
    return false unless current_user
    return true if current_user.superadmin?

    current_user.memberships.find_by(workspace: workspace)&.manager? || false
  end

  def require_workspace_manager!
    return if workspace_manager?

    redirect_back fallback_location: root_path, alert: t("workspaces.not_authorized")
  end
end
