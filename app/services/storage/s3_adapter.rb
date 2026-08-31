# frozen_string_literal: true

module Storage
  # Storage adapter for S3 and every S3-compatible provider (MinIO, R2,
  # Backblaze B2, Wasabi, DigitalOcean Spaces...). Uses the SDK's managed
  # uploader, which streams from disk with automatic multipart for large files.
  class S3Adapter
    MULTIPART_THRESHOLD = 100 * 1024 * 1024

    attr_reader :destination

    def initialize(destination)
      @destination = destination
    end

    # @param path [String] local file path
    # @param key [String] object key to create
    # @param on_progress [Proc, nil] called with cumulative bytes sent
    def upload!(path, key, on_progress: nil)
      options = {
        bucket: destination.bucket,
        key: key,
        multipart_threshold: MULTIPART_THRESHOLD,
        thread_count: 4
      }
      if on_progress
        options[:progress_callback] = ->(bytes, _totals, _file_size = nil) { on_progress.call(Array(bytes).sum) }
      end

      Aws::S3::TransferManager.new(client: client).upload_file(path, **options)
    end

    # Only ever called by retention pruning with keys recorded on BackupRun.
    def delete!(key)
      object(key).delete
    end

    # @return [Integer, nil] remote object size, nil when missing
    def head_size(key)
      object(key).content_length
    rescue Aws::S3::Errors::NotFound, Aws::S3::Errors::NoSuchKey
      nil
    end

    def download_url(key, expires_in: 15.minutes.to_i)
      object(key).presigned_url(:get, expires_in: expires_in)
    end

    # Write-free connectivity check: HEAD the bucket only.
    def verify_access!
      client.head_bucket(bucket: destination.bucket)
      true
    end

    private

    def object(key)
      Aws::S3::Object.new(destination.bucket, key, client: client)
    end

    def client
      @client ||= Aws::S3::Client.new(
        access_key_id: destination.access_key_id,
        secret_access_key: destination.secret_access_key,
        region: destination.region.presence || "us-east-1",
        endpoint: destination.endpoint.presence,
        force_path_style: destination.s3_compatible?
      )
    end
  end
end
