# frozen_string_literal: true

module Backups
  # Executes pg_dump for a run inside a caller-provided working directory and
  # returns the artifact. Directory-format dumps are tarred into a single
  # artifact so the storage layer only ever deals with one file.
  #
  # While pg_dump runs, a ticker samples the output size to publish live KPIs
  # (bytes written, write rate, current pg_dump activity) on the run.
  class DumpExecutor < ApplicationService
    DumpArtifact = Data.define(:path, :size_bytes)

    PROGRESS_INTERVAL = 5
    HISTORY_LOG_INTERVAL = 300

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
        measure_source_size(env)
        with_progress_ticker do |capture_line|
          CommandRunner.run(command.argv, env: env, timeout: dump_timeout, on_stderr_line: capture_line)
        end
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

    # The raw database size gives context to judge dump progress and, at the
    # end, the effective compression ratio. Best-effort: a failure here must
    # never fail the backup.
    def measure_source_size(env)
      result = CommandRunner.run(
        [ "psql", "--no-psqlrc", "--tuples-only", "--no-align", "--command", "SELECT pg_database_size(current_database())" ],
        env: env, timeout: 15
      )
      size = Integer(result.stdout.to_s.strip) if result.success?
      return unless size&.positive?

      run.update!(source_size_bytes: size)
      run.log!(message: "Source database size: ~#{human_size(size)}")
    rescue ArgumentError, TypeError
      nil
    end

    # Runs the block with a line-capture callback while a background ticker
    # publishes progress every PROGRESS_INTERVAL seconds and appends a history
    # log line every HISTORY_LOG_INTERVAL seconds.
    def with_progress_ticker
      latest_line = nil
      stop = false

      ticker = Thread.new do
        previous_bytes = 0
        previous_at = monotonic
        last_history_at = monotonic

        until stop
          sleep PROGRESS_INTERVAL
          break if stop

          begin
            bytes = dumped_bytes
            now = monotonic
            rate = ((bytes - previous_bytes) / (now - previous_at)).to_i
            run.progress!(bytes: bytes, rate_bps: rate, detail: latest_line&.delete_prefix("pg_dump: "))

            if now - last_history_at >= HISTORY_LOG_INTERVAL
              run.log!(message: "Dump in progress: #{human_size(bytes)} written (#{human_size(rate)}/s)")
              last_history_at = now
            end

            previous_bytes = bytes
            previous_at = now
          rescue
            # Progress reporting must never break the dump.
          end
        end
      end

      yield ->(line) { latest_line = line }
    ensure
      stop = true
      ticker&.join(PROGRESS_INTERVAL + 1)
    end

    def dumped_bytes
      if routine.format == "directory"
        Dir.glob(File.join(output_path, "**", "*")).sum { |f| File.file?(f) ? File.size(f) : 0 }
      else
        File.exist?(output_path) ? File.size(output_path) : 0
      end
    end

    def monotonic
      Process.clock_gettime(Process::CLOCK_MONOTONIC)
    end

    def human_size(bytes)
      ActiveSupport::NumberHelper.number_to_human_size(bytes)
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
