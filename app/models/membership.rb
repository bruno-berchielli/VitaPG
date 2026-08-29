# == Schema Information
#
# Table name: memberships
# Database name: primary
#
#  id           :integer          not null, primary key
#  role         :string           default("member"), not null
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  user_id      :integer          not null
#  workspace_id :integer          not null
#
# Indexes
#
#  index_memberships_on_user_id                   (user_id)
#  index_memberships_on_user_id_and_workspace_id  (user_id,workspace_id) UNIQUE
#  index_memberships_on_workspace_id              (workspace_id)
#
# Foreign Keys
#
#  user_id       (user_id => users.id)
#  workspace_id  (workspace_id => workspaces.id)
#
class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :workspace

  enum :role, { owner: "owner", admin: "admin", member: "member" }, scopes: true, default: :member

  validates :user_id, uniqueness: { scope: :workspace_id }
  validate :keep_at_least_one_owner, on: :update
  before_destroy :prevent_removing_last_owner

  def manager?
    owner? || admin?
  end

  private

  def other_owners?
    workspace.memberships.owner.where.not(id: id).exists?
  end

  def keep_at_least_one_owner
    return unless role_changed? && role_was == "owner"

    errors.add(:role, :last_owner) unless other_owners?
  end

  def prevent_removing_last_owner
    return unless owner?
    return if other_owners?

    errors.add(:base, :last_owner)
    throw :abort
  end
end
