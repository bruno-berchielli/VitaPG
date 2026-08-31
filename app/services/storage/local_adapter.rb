# frozen_string_literal: true

module Storage
  # Storage adapter for a directory on the VitaPG server itself — fully
  # offline backups, no network involved. Every key is resolved strictly
  # under the destination's base_path; anything that escapes it is refused,
  # so retention pruning can only ever touch files inside that directory.
  class LocalAdapter
    CHUNK = 16 * 1024 * 1024

    attr_reader :destination

    def initialize(destination)
      @destination = destination
    end

    # @param path [String] local file path
    # @param key [String] relative key to create under base_path
    # @param on_progress [Proc, nil] called with cumulative bytes copied
    def upload!(path, key, on_progress: nil)
      target = resolve(key)
      FileUtils.mkdir_p(File.dirname(target))

      # Copy to a temp name, fsync, then rename: a crash mid-copy never
      # leaves a file retention could mistake for a finished backup.
      partial = "#{target}.partial"
      copied = 0
      File.open(path, "rb") do |source|
        File.open(partial, "wb") do |out|
          while (chunk = source.read(CHUNK))
            out.write(chunk)
            copied += chunk.bytesize
            on_progress&.call(copied)
          end
          out.fsync
        end
      end
      File.rename(partial, target)
    end

    # Only ever called by retention pruning with keys recorded on BackupRun.
    def delete!(key)
      target = resolve(key)
      File.delete(target) if File.exist?(target)
    end

    # @return [Integer, nil] stored file size, nil when missing
    def head_size(key)
      target = resolve(key)
      File.exist?(target) ? File.size(target) : nil
    end

    # Local files have no URL; BackupRunsController streams them directly.
    def download_url(_key, expires_in: nil)
      nil
    end

    # @return [String] absolute path for a stored key (for send_file)
    def file_path(key)
      resolve(key)
    end

    # Write-free check: the directory must exist and be writable.
    def verify_access!
      base = destination.base_path
      raise Backups::Error, "Directory does not exist: #{base}" unless Dir.exist?(base)
      raise Backups::Error, "Directory is not writable: #{base}" unless File.writable?(base)

      true
    end

    private

    # @raise [Backups::Error] when the key resolves outside base_path
    def resolve(key)
      base = File.expand_path(destination.base_path)
      target = File.expand_path(key.to_s, base)
      unless target.start_with?("#{base}/")
        raise Backups::Error, "Key resolves outside the destination directory: #{key}"
      end

      target
    end
  end
end
