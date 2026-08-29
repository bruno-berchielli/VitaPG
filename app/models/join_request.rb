# == Schema Information
#
# Table name: join_requests
# Database name: primary
#
#  id            :integer          not null, primary key
#  decided_at    :datetime
#  status        :string           default("pending"), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  decided_by_id :integer
#  user_id       :integer          not null
#  workspace_id  :integer          not null
#
# Indexes
#
#  index_join_requests_on_decided_by_id             (decided_by_id)
#  index_join_requests_on_user_id                   (user_id)
#  index_join_requests_on_user_id_and_workspace_id  (user_id,workspace_id) UNIQUE
#  index_join_requests_on_workspace_id              (workspace_id)
#
# Foreign Keys
#
#  decided_by_id  (decided_by_id => users.id)
#  user_id        (user_id => users.id)
#  workspace_id   (workspace_id => workspaces.id)
#
class JoinRequest < ApplicationRecord
  belongs_to :user
  belongs_to :workspace
  belongs_to :decided_by, class_name: "User", optional: true

  enum :status, { pending: "pending", approved: "approved", denied: "denied" }, default: :pending

  validates :user_id, uniqueness: { scope: :workspace_id }
  validate :user_not_already_member, on: :create

  scope :awaiting, -> { pending.order(:created_at) }

  def approve!(decider)
    transaction do
      update!(status: :approved, decided_by: decider, decided_at: Time.current)
      workspace.memberships.where(user: user).first_or_create!(role: :member)
    end
  end

  def deny!(decider)
    update!(status: :denied, decided_by: decider, decided_at: Time.current)
  end

  # A denied or approved request can be reopened by asking again.
  def reopen!
    update!(status: :pending, decided_by: nil, decided_at: nil)
  end

  private

  def user_not_already_member
    errors.add(:base, :already_member) if workspace&.memberships&.exists?(user: user)
  end
end
