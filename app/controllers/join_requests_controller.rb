class JoinRequestsController < ApplicationController
  # POST /workspaces/:workspace_id/join_request
  def create
    workspace = Workspace.find(params[:workspace_id])
    request = JoinRequest.find_by(user: current_user, workspace: workspace)

    if request&.pending?
      redirect_to workspaces_path, notice: t(".already_pending")
    elsif request
      request.reopen!
      redirect_to workspaces_path, notice: t(".requested")
    else
      request = JoinRequest.new(user: current_user, workspace: workspace)
      if request.save
        redirect_to workspaces_path, notice: t(".requested")
      else
        redirect_to workspaces_path, alert: request.errors.full_messages.to_sentence
      end
    end
  end

  def approve
    request = JoinRequest.pending.find(params[:id])
    return not_authorized unless workspace_manager?(request.workspace)

    request.approve!(current_user)
    redirect_to memberships_path, notice: t(".approved", name: request.user.name)
  end

  def deny
    request = JoinRequest.pending.find(params[:id])
    return not_authorized unless workspace_manager?(request.workspace)

    request.deny!(current_user)
    redirect_to memberships_path, notice: t(".denied", name: request.user.name)
  end

  private

  def not_authorized
    redirect_back fallback_location: root_path, alert: t("workspaces.not_authorized")
  end
end
