class MembershipsController < ApplicationController
  before_action :require_workspace_manager!, except: :index
  before_action :set_membership, only: %i[update destroy]

  def index
    @memberships = Current.workspace.memberships.includes(:user).order("users.name")
    @join_requests = Current.workspace.join_requests.awaiting.includes(:user) if workspace_manager?
  end

  # Invites a person by email. Accounts are passwordless, so inviting an
  # unknown email just creates the user; they sign in with a magic link.
  def create
    user = User.find_by(email: invite_params[:email].to_s.strip.downcase)
    user ||= User.new(
      email: invite_params[:email].to_s.strip.downcase,
      name: invite_params[:name].presence || invite_params[:email].to_s.split("@").first
    )

    unless user.persisted? || user.save
      redirect_to memberships_path, alert: user.errors.full_messages.to_sentence
      return
    end

    membership = Current.workspace.memberships.new(user: user, role: invite_params[:role])

    if membership.save
      LoginMailer.magic_link(user).deliver_later
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
end
