# == Schema Information
#
# Table name: destinations
# Database name: primary
#
#  id                :integer          not null, primary key
#  base_path         :string
#  bucket            :string
#  endpoint          :string
#  name              :string
#  provider          :string
#  region            :string
#  secret_access_key :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  access_key_id     :string
#  workspace_id      :integer          not null
#
# Indexes
#
#  index_destinations_on_workspace_id  (workspace_id)
#
# Foreign Keys
#
#  workspace_id  (workspace_id => workspaces.id)
#
class Destination < ApplicationRecord
  belongs_to :workspace
  has_many :backup_routines, dependent: :restrict_with_error

  encrypts :secret_access_key

  # s3/s3_compatible speak the S3 API; local writes to a directory on the
  # VitaPG server itself (fully offline backups).
  enum :provider, {
    s3: "s3",
    s3_compatible: "s3_compatible",
    local: "local"
  }, default: :s3

  validates :name, :provider, presence: true
  validates :bucket, :access_key_id, :secret_access_key, presence: true, unless: :local?
  validates :region, presence: true, if: :s3?
  validates :endpoint, presence: true, if: :s3_compatible?
  validates :base_path, presence: true, if: :local?
  validate :base_path_must_be_safe, if: :local?

  normalizes :base_path, with: ->(value) { value.presence && File.expand_path(value.strip) }

  def adapter
    local? ? Storage::LocalAdapter.new(self) : Storage::S3Adapter.new(self)
  end

  # Where files land, for list views: bucket for S3, directory for local.
  def location
    local? ? base_path : bucket
  end

  private

  def base_path_must_be_safe
    return if base_path.blank?

    unless base_path.start_with?("/") && base_path != "/"
      errors.add(:base_path, :invalid)
    end
  end
end
