# == Schema Information
#
# Table name: users
# Database name: primary
#
#  id                     :integer          not null, primary key
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  name                   :string           default(""), not null
#  preferences            :json             not null
#  remember_created_at    :datetime
#  remember_token         :string
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  superadmin             :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_email                 (email) UNIQUE
#  index_users_on_remember_token        (remember_token)
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#
class User < ApplicationRecord
  # Access is internal-only: no self-registration, no passwords. People sign
  # in with an emailed magic link or Google (when configured); accounts are
  # created by a superadmin, a workspace invite, or Google domain whitelisting.
  devise :rememberable, :trackable
  if ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
    devise :omniauthable, omniauth_providers: [ :google_oauth2 ]
  end

  generates_token_for :magic_login, expires_in: 15.minutes

  has_many :memberships, dependent: :destroy
  has_many :workspaces, through: :memberships
  has_many :join_requests, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true,
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  scope :superadmins, -> { where(superadmin: true) }

  def self.google_auth_configured?
    ENV["GOOGLE_CLIENT_ID"].present? && ENV["GOOGLE_CLIENT_SECRET"].present?
  end

  # Domains allowed to auto-provision accounts through Google sign-in.
  def self.google_allowed_domains
    ENV["GOOGLE_ALLOWED_DOMAINS"].to_s.split(",").map { |d| d.strip.downcase }.reject(&:empty?)
  end

  def locale
    preferences&.dig("locale").presence
  end

  def default_workspace
    workspaces.order(:created_at).first || (superadmin? ? Workspace.order(:created_at).first : nil)
  end

  def accessible_workspaces
    superadmin? ? Workspace.all : workspaces
  end

  def member_of?(workspace)
    memberships.exists?(workspace: workspace)
  end

  def pending_join_request_for(workspace)
    join_requests.pending.find_by(workspace: workspace)
  end
end
