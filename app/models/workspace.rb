# == Schema Information
#
# Table name: workspaces
# Database name: primary
#
#  id         :integer          not null, primary key
#  name       :string           not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_workspaces_on_slug  (slug) UNIQUE
#
class Workspace < ApplicationRecord
  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships
  has_many :database_connections, dependent: :destroy
  has_many :destinations, dependent: :destroy
  has_many :backup_routines, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9-]+\z/ }

  before_validation :generate_slug, on: :create

  def owners
    users.merge(Membership.owner)
  end

  private

  def generate_slug
    return if slug.present? || name.blank?

    base = name.parameterize
    candidate = base
    suffix = 1
    while Workspace.exists?(slug: candidate)
      suffix += 1
      candidate = "#{base}-#{suffix}"
    end
    self.slug = candidate
  end
end
