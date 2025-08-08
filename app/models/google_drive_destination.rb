class GoogleDriveDestination < Destination
  validates :client_id, :client_secret, presence: true
  validates :credentials_path, :bucket, :access_key_id, :secret_access_key, :region, absence: true

  attribute :provider, default: :google_drive

  default_scope { where(provider: :google_drive) }

  def connect_url
    "/google_auth/start?destination_id=#{id}"
  end
end
