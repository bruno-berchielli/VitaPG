# frozen_string_literal: true

module Backups
  # Executes pg_dump for a run inside a caller-provided working directory and
  # returns the artifact. Directory-format dumps are tarred into a single
  # artifact so the storage layer only ever deals with one file.
  class DumpExecutor < ApplicationService
    DumpArtifact = Data.define(:path, :size_bytes)

    attr_reader :run, :routine, :connection, :workdir

    def initialize(run, workdir:)
      @run = run
      @routine = run.backup_routine
      @connection = routine.database_connection
      @workdir = workdir
    end

    def call
      command = PgDumpCommand.new(routine, output_path: output_path)

      run.log!(message: "Executing: #{command.to_log_line}")
      if connection.ssh_tunnel?
        run.log!(message: "Opening SSH tunnel via #{connection.ssh_user}@#{connection.ssh_host}")
      end

      result = connection.with_pg_env do |env|
        CommandRunner.run(command.argv, env: env, timeout: dump_timeout)
      end

      raise Backups::Error, "pg_dump timed out after #{dump_timeout}s" if result.timed_out
      raise Backups::Error, "pg_dump failed: #{result.stderr.to_s.last(2000)}" unless result.success?

      run.log!(message: "pg_dump completed")

      artifact_path = routine.format == "directory" ? tar_directory : output_path
      DumpArtifact.new(path: artifact_path, size_bytes: File.size(artifact_path))
    end

    private

    def output_path
      @output_path ||= File.join(workdir, "dump#{PgDumpCommand.new(routine, output_path: nil).file_extension}")
    end

    def tar_directory
      tar_path = File.join(workdir, "dump.tar")
      result = CommandRunner.run([ "tar", "-cf", tar_path, "-C", workdir, "dump" ], timeout: 1800)
      raise Backups::Error, "tar failed: #{result.stderr.to_s.last(500)}" unless result.success?

      tar_path
    end

    def dump_timeout
      Integer(ENV.fetch("VITAPG_DUMP_TIMEOUT_SECONDS", 6 * 3600))
    end
  end
end
