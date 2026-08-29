# == Schema Information
#
# Table name: destinations
# Database name: primary
#
#  id                :integer          not null, primary key
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

  # All providers speak the S3 API; the enum drives UI presets (endpoint,
  # region hints) and future non-S3 adapters.
  enum :provider, {
    s3: "s3",
    s3_compatible: "s3_compatible"
  }, default: :s3

  validates :name, :provider, :bucket, :access_key_id, :secret_access_key, presence: true
  validates :region, presence: true, if: :s3?
  validates :endpoint, presence: true, if: :s3_compatible?

  def adapter
    Storage::S3Adapter.new(self)
  end
end
