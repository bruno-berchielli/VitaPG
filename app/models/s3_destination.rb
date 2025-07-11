class S3Destination < Destination
  validates :bucket, :access_key_id, :secret_access_key, :region, presence: true
  validates :client_id, :client_secret, :access_token, absence: true
  validate :ensure_provider_is_s3

  def ensure_provider_is_s3
    errors.add(:provider, "must be 's3'") unless provider == "s3"
  end
end
