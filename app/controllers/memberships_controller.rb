class MembershipsController < ApplicationController
  before_action :require_workspace_manager!, except: :index
  before_action :set_membership, only: %i[update destroy]

  def index
    @memberships = Current.workspace.memberships.includes(:user).order("users.name")
  end

  # Invites a member by email. Unknown emails get an account with a random
  # password plus a reset-password email to choose their own.
  def create
    user = User.find_by(email: invite_params[:email].to_s.downcase.strip)
    user ||= invite_new_user

    if user.errors.any?
      redirect_to memberships_path, alert: user.errors.full_messages.to_sentence
      return
    end

    membership = Current.workspace.memberships.new(user: user, role: invite_params[:role])

    if membership.save
      redirect_to memberships_path, notice: t(".created")
    else
      redirect_to memberships_path, alert: membership.errors.full_messages.to_sentence
    end
  end

  def update
    if @membership.update(role_params)
      redirect_to memberships_path, notice: t(".updated")
    else
      redirect_to memberships_path, alert: @membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    if @membership.user == current_user
      redirect_to memberships_path, alert: t(".cannot_remove_self")
    elsif @membership.destroy
      redirect_to memberships_path, notice: t(".destroyed")
    else
      redirect_to memberships_path, alert: @membership.errors.full_messages.to_sentence
    end
  end

  private

  def set_membership
    @membership = Current.workspace.memberships.find(params[:id])
  end

  def invite_params
    params.expect(membership: %i[email role name])
  end

  def role_params
    params.expect(membership: [ :role ])
  end

  def invite_new_user
    user = User.new(
      email: invite_params[:email].to_s.downcase.strip,
      name: invite_params[:name].presence || invite_params[:email].to_s.split("@").first,
      password: SecureRandom.base58(24)
    )
    user.send_reset_password_instructions if user.save
    user
  end
end
