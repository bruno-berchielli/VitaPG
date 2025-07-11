require "google/apis/drive_v3"

module Storage
  class UploadService < ApplicationService
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
      destination.ensure_valid_token!
      client = destination.oauth_client

      service = Google::Apis::DriveV3::DriveService.new
      service.authorization = client

      metadata = {
        name: File.basename(file_path),
        parents: destination.folder_id.present? ? [ destination.folder_id ] : nil
      }.compact

      file = service.create_file(
        metadata,
        upload_source: File.open(file_path),
        content_type: "application/octet-stream"
      )

      file.id
    end
  end
end
