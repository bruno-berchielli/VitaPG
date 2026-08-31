# Superadmin management of any user's workspace memberships. Last-owner
# protection lives in the Membership model and applies here too.
class Admin::MembershipsController < ApplicationController
  before_action :require_superadmin!

  def create
    user = User.find(params[:user_id])
    workspace = Workspace.find(membership_params[:workspace_id])
    membership = workspace.memberships.new(user: user, role: membership_params[:role])

    if membership.save
      redirect_to edit_admin_user_path(user), notice: t(".created", workspace: workspace.name)
    else
      redirect_to edit_admin_user_path(user), alert: membership.errors.full_messages.to_sentence
    end
  end

  def update
    membership = Membership.find(params[:id])

    if membership.update(params.expect(membership: [ :role ]))
      redirect_to edit_admin_user_path(membership.user), notice: t(".updated")
    else
      redirect_to edit_admin_user_path(membership.user), alert: membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    membership = Membership.find(params[:id])

    if membership.destroy
      redirect_to edit_admin_user_path(membership.user), notice: t(".destroyed", workspace: membership.workspace.name)
    else
      redirect_to edit_admin_user_path(membership.user), alert: membership.errors.full_messages.to_sentence
    end
  end

  private

  def require_superadmin!
    redirect_to root_path, alert: t("admin.not_authorized") unless current_user&.superadmin?
  end

  def membership_params
    params.expect(membership: %i[workspace_id role])
  end
end
