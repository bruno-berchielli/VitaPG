class StorageUploadService < ApplicationService
  attr_reader :destination, :file_path

  def initialize(destination, file_path)
    @destination = destination
    @file_path = file_path
  end

  def call
    case destination.provider
    when "s3"
      upload_to_s3
    when "google_drive"
      upload_to_google_drive
    else
      raise "Unknown provider: #{destination.provider}"
    end
  end

  private

  def upload_to_s3
    client = Aws::S3::Client.new(
      access_key_id: destination.access_key_id,
      secret_access_key: destination.secret_access_key,
      region: destination.region
    )

    key = File.basename(file_path)
    client.put_object(
      bucket: destination.bucket,
      key: key,
      body: File.open(file_path)
    )

    "s3://#{destination.bucket}/#{key}"
  end

  def upload_to_google_drive
    raise NotImplementedError, "Google Drive upload not implemented yet"
  end
end
