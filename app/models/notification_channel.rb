# == Schema Information
#
# Table name: notification_channels
# Database name: primary
#
#  id                :integer          not null, primary key
#  enabled           :boolean          default(TRUE), not null
#  kind              :string           not null
#  name              :string           not null
#  notify_on_failure :boolean          default(TRUE), not null
#  notify_on_success :boolean          default(FALSE), not null
#  recipients        :string
#  signing_secret    :string
#  url               :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  workspace_id      :integer          not null
#
# Indexes
#
#  index_notification_channels_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  workspace_id  (workspace_id => workspaces.id)
#
class NotificationChannel < ApplicationRecord
  belongs_to :workspace

  # Webhook URLs and signing secrets can embed tokens.
  encrypts :url
  encrypts :signing_secret

  enum :kind, { email: "email", webhook: "webhook", slack: "slack" }, prefix: true

  validates :name, :kind, presence: true
  validates :url, presence: true, if: -> { kind_webhook? || kind_slack? }
  validates :recipients, presence: true, if: :kind_email?
  validate :url_must_be_https_or_http

  scope :enabled, -> { where(enabled: true) }

  before_create :generate_signing_secret, if: :kind_webhook?

  def recipient_list
    recipients.to_s.split(",").map(&:strip).reject(&:blank?)
  end

  def notifies?(run)
    return false unless enabled?

    (run.failed? && notify_on_failure?) || (run.completed? && notify_on_success?)
  end

  private

  def generate_signing_secret
    self.signing_secret ||= SecureRandom.hex(32)
  end

  def url_must_be_https_or_http
    return if url.blank?

    uri = URI.parse(url)
    errors.add(:url, :invalid) unless uri.is_a?(URI::HTTP) || uri.is_a?(URI::HTTPS)
  rescue URI::InvalidURIError
    errors.add(:url, :invalid)
  end
end
