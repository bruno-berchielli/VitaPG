class S3Destination < Destination
  validates :bucket, :access_key_id, :secret_access_key, :region, presence: true
  validates :client_id, :client_secret, :access_token, absence: true

  attribute :provider, default: :s3

  default_scope { where(provider: :s3) }
end
