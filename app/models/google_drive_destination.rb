class GoogleDriveDestination < Destination
  validates :client_id, :client_secret, presence: true
  validates :credentials_path, :bucket, :access_key_id, :secret_access_key, :region, absence: true
  validate :ensure_provider_is_google_drive

  def ensure_provider_is_google_drive
    errors.add(:provider, "must be 'google_drive'") unless provider == "google_drive"
  end

  def connect_url
    "/google_auth/start?destination_id=#{id}"
  end
end
