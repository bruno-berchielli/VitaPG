module Storage
  class UploadService < ApplicationService
    attr_reader :destination, :file_path, :backup_run

    def initialize(destination, file_path, backup_run)
      super()
      @destination = destination
      @file_path = file_path
      @backup_run = backup_run
    end

    def call
      case destination.provider
      when "s3"
        S3UploadService.call(destination, file_path)
      when "google_drive"
        raise NotImplementedError, "Google Drive upload not implemented yet"
      else
        raise ArgumentError, "Unsupported provider: #{destination.provider}"
      end
    end
  end
end
