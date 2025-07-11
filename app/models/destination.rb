# == Schema Information
#
# Table name: destinations
#
#  id                :integer          not null, primary key
#  access_token      :string
#  bucket            :string
#  client_secret     :string
#  credentials_path  :string
#  expires_at        :datetime
#  name              :string
#  provider          :string
#  refresh_token     :string
#  region            :string
#  secret_access_key :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  access_key_id     :string
#  client_id         :string
#  folder_id         :string
#  project_id        :string
#

class Destination < ApplicationRecord
  enum :provider, { s3: "s3", google_drive: "google_drive" }

  has_many :backup_routines, dependent: :nullify

  validates :name, :provider, presence: true
end

class S3Destination < Destination
  validates :bucket, :access_key_id, :secret_access_key, :region, presence: true
  validates :client_id, :client_secret, :access_token, absence: true
  validate :ensure_provider_is_s3

  def ensure_provider_is_s3
    errors.add(:provider, "must be 's3'") unless provider == "s3"
  end
end

class GoogleDriveDestination < Destination
  validates :client_id, :client_secret, :access_token, presence: true
  validates :credentials_path, :bucket, :access_key_id, :secret_access_key, :region, absence: true
  validate :ensure_provider_is_google_drive

  def ensure_provider_is_google_drive
    errors.add(:provider, "must be 'google_drive'") unless provider == "google_drive"
  end
end
