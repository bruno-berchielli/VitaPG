# Instance-level user administration, superadmin only: create and edit
# accounts, grant/revoke superadmin, and manage workspace roles per user.
class Admin::UsersController < ApplicationController
  before_action :require_superadmin!
  before_action :set_user, only: %i[edit update toggle_superadmin]

  def index
    @users = User.order(:name).includes(:memberships)
  end

  def create
    user = User.new(
      email: user_params[:email].to_s.strip.downcase,
      name: user_params[:name].presence || user_params[:email].to_s.split("@").first,
      superadmin: user_params[:superadmin] == "1"
    )

    if user.save
      LoginMailer.magic_link(user).deliver_later
      redirect_to edit_admin_user_path(user), notice: t(".created", email: user.email)
    else
      redirect_to admin_users_path, alert: user.errors.full_messages.to_sentence
    end
  end

  def edit
    @memberships = @user.memberships.includes(:workspace).joins(:workspace).order("workspaces.name")
    @available_workspaces = Workspace.order(:name).where.not(id: @user.workspaces.select(:id))
  end

  def update
    if @user.update(account_params)
      redirect_to edit_admin_user_path(@user), notice: t(".updated")
    else
      redirect_to edit_admin_user_path(@user), alert: @user.errors.full_messages.to_sentence
    end
  end

  def toggle_superadmin
    if @user == current_user
      redirect_back fallback_location: admin_users_path, alert: t(".cannot_change_self")
    elsif @user.superadmin? && User.superadmins.count == 1
      redirect_back fallback_location: admin_users_path, alert: t(".last_superadmin")
    else
      @user.update!(superadmin: !@user.superadmin?)
      redirect_back fallback_location: admin_users_path,
                    notice: @user.superadmin? ? t(".promoted", name: @user.name) : t(".demoted", name: @user.name)
    end
  end

  private

  def require_superadmin!
    redirect_to root_path, alert: t("admin.not_authorized") unless current_user&.superadmin?
  end

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.expect(user: %i[email name superadmin])
  end

  def account_params
    params.expect(user: %i[email name])
  end
end
