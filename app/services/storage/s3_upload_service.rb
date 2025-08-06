require 'aws-sdk-s3'

module Storage
  class S3UploadService < ApplicationService
    MULTIPART_THRESHOLD = 50 * 1024 * 1024 # 50MB

    attr_reader :destination, :file_path

    def initialize(destination, file_path)
      super()
      @destination = destination
      @file_path = file_path
      @progress_logged = Set.new
    end

    def call
      key = File.basename(file_path)
      size = File.size(file_path)

      if size <= MULTIPART_THRESHOLD
        upload_single_part(key)
      else
        upload_multipart(key, size)
      end

      "s3://#{destination.bucket}/#{key}"
    end

    private

    def s3_client
      @s3_client ||= Aws::S3::Client.new(
        access_key_id: destination.access_key_id,
        secret_access_key: destination.secret_access_key,
        region: destination.region,
        endpoint: destination.endpoint.presence,
        force_path_style: true
      )
    end

    def upload_single_part(key)
      File.open(file_path, 'rb') do |file|
        s3_client.put_object(
          bucket: destination.bucket,
          key:,
          body: file
        )
      end
    end

    def upload_multipart(key, size)
      part_size = MULTIPART_THRESHOLD
      total_parts = (size / part_size.to_f).ceil

      log_info("Starting multipart upload for #{key} (#{total_parts} parts)")
      upload_id = s3_client.create_multipart_upload(bucket: destination.bucket, key: key).upload_id
      parts = []

      File.open(file_path, 'rb') do |file|
        (1..total_parts).each do |part_number|
          file.seek((part_number - 1) * part_size)
          body = file.read(part_size)

          response = s3_client.upload_part(
            bucket: destination.bucket,
            key:,
            upload_id:,
            part_number:,
            body: StringIO.new(body)
          )

          parts << { part_number: part_number, etag: response.etag }
          log_progress(part_number, total_parts)
        end
      end

      s3_client.complete_multipart_upload(
        bucket: destination.bucket,
        key:,
        upload_id:,
        multipart_upload: { parts: parts }
      )

      log_info("Multipart upload complete for #{key}")
    rescue => e
      log_error("Multipart upload failed for #{key}: #{e.class} - #{e.message}")
      s3_client.abort_multipart_upload(bucket: destination.bucket, key: key, upload_id: upload_id) if upload_id
      raise e
    end
  end
end
