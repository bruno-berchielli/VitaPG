# app/services/storage_upload_service.rb
class StorageUploadService
  def initialize(destination)
    @destination = destination
  end

  def upload(file_path)
    case @destination.provider
    when "s3"
      upload_to_s3(file_path)
    when "google_drive"
      upload_to_google_drive(file_path)
    else
      raise "Unknown provider"
    end
  end

  private

  def upload_to_s3(file_path)
    client = Aws::S3::Client.new(
      access_key_id: @destination.access_key_id,
      secret_access_key: @destination.secret_access_key,
      region: @destination.region
    )

    key = File.basename(file_path)

    client.put_object(
      bucket: @destination.bucket,
      key: key,
      body: File.open(file_path)
    )

    "s3://#{@destination.bucket}/#{key}"
  end

  def upload_to_google_drive(file_path)
    # Simplified placeholder; you'd use `google-apis-drive_v3`
    raise NotImplementedError, "Google Drive upload not implemented yet"
  end
end
