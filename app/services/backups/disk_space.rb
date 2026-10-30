# frozen_string_literal: true

module Backups
  # Free space on the filesystem holding a path, read from POSIX `df -Pk`
  # since Ruby has no statvfs binding. Returns nil when it cannot be
  # determined, so callers can treat disk checks as best-effort.
  module DiskSpace
    def self.free_bytes(path)
      result = CommandRunner.run([ "df", "-Pk", path ], timeout: 10)
      return unless result.success?

      Integer(result.stdout.lines.last.split[3]) * 1024
    rescue ArgumentError, TypeError, NoMethodError
      nil
    end
  end
end
