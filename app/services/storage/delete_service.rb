module Storage
  class DeleteService < ApplicationService
    attr_reader :destination, :file_url

    def initialize(destination, file_url)
      @destination = destination
      @file_url = file_url
    end

    def call
      case destination.provider
      when "s3"
        delete_from_s3
      when "google_drive"
        delete_from_google_drive
      else
        raise "Unsupported provider: #{destination.provider}"
      end
    end

    private

    def delete_from_s3
      uri = URI.parse(file_url)
      key = uri.path.sub(%r{^/}, "") # strip leading slash

      client = Aws::S3::Client.new(
        access_key_id: destination.access_key_id,
        secret_access_key: destination.secret_access_key,
        region: destination.region
      )

      client.delete_object(bucket: destination.bucket, key: key)
    end

    def delete_from_google_drive
      raise NotImplementedError, "Google Drive deletion not yet implemented"
    end
  end
end
