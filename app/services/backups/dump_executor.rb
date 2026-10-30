# frozen_string_literal: true

module Backups
  # Executes pg_dump for a run inside a caller-provided working directory and
  # returns the artifact. Directory-format dumps are tarred into a single
  # artifact so the storage layer only ever deals with one file.
  #
  # While pg_dump runs, a ticker samples the output size to publish live KPIs
  # (bytes written, write rate, current pg_dump activity) on the run.
  #
  # The dump lands on local disk before upload, so free space is guarded
  # twice: up front against the routine's last dump size, and on every tick,
  # killing pg_dump once free space drops below the reserve instead of
  # filling the disk the app (and its SQLite databases) lives on.
  class DumpExecutor < ApplicationService
    DumpArtifact = Data.define(:path, :size_bytes)

    PROGRESS_INTERVAL = 5
    HISTORY_LOG_INTERVAL = 300
    TABLE_LOG_INTERVAL = 2

    attr_reader :run, :routine, :connection, :workdir

    def initialize(run, workdir:)
      @run = run
      @routine = run.backup_routine
      @connection = routine.database_connection
      @workdir = workdir
    end

    def call
      command = PgDumpCommand.new(routine, output_path: output_path)

      ensure_disk_space!

      run.log!(message: "Executing: #{command.to_log_line}")
      if connection.ssh_tunnel?
        run.log!(message: "Opening SSH tunnel via #{connection.ssh_user}@#{connection.ssh_host}")
      end

      result = connection.with_pg_env do |env|
        measure_source_size(env, command)
        with_progress_ticker do |capture_line|
          CommandRunner.run(command.argv, env: env, timeout: dump_timeout, on_stderr_line: capture_line,
                            abort_if: -> { @disk_shortage })
        end
      end

      if result.aborted
        raise Backups::Error, "pg_dump aborted: free disk space dropped to #{human_size(@disk_shortage)} " \
                              "(reserve #{human_size(min_free_disk_bytes)}). #{disk_space_hint}"
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

    # The size of the table data being dumped gives context to judge dump
    # progress and, at the end, the effective compression ratio. Best-effort:
    # a failure here must never fail the backup.
    def measure_source_size(env, command)
      result = CommandRunner.run(
        [ "psql", "--no-psqlrc", "--tuples-only", "--no-align", "--command", command.source_size_sql ],
        env: env, timeout: 30
      )
      size = Integer(result.stdout.to_s.strip) if result.success?
      return unless size&.positive?

      run.update!(source_size_bytes: size)
      run.log!(message: "Source data size: ~#{human_size(size)} (tables in the dump, without indexes)")
    rescue ArgumentError, TypeError
      nil
    end

    # Runs the block with a line-capture callback while a background ticker
    # publishes progress every PROGRESS_INTERVAL seconds and appends a history
    # log line every HISTORY_LOG_INTERVAL seconds.
    def with_progress_ticker
      stop = false

      ticker = Thread.new do
        previous_bytes = 0
        previous_at = monotonic
        last_history_at = monotonic

        until stop
          sleep PROGRESS_INTERVAL
          break if stop

          check_disk_space

          begin
            bytes = dumped_bytes
            now = monotonic
            rate = ((bytes - previous_bytes) / (now - previous_at)).to_i
            run.progress!(bytes: bytes, rate_bps: rate, detail: @latest_line)

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

      yield method(:handle_stderr_line)
    ensure
      stop = true
      ticker&.join(PROGRESS_INTERVAL + 1)
    end

    # Fails before connecting when the work directory cannot hold the routine's
    # last dump plus the reserve. Without a previous dump only the reserve is
    # checked; the per-tick guard covers the rest.
    def ensure_disk_space!
      free = free_disk_bytes
      return unless free

      expected = expected_dump_bytes
      run.log!(message: "Free disk space in work directory: #{human_size(free)}")
      return if free >= expected + min_free_disk_bytes

      needed = expected.positive? ? "~#{human_size(expected)} for the dump (last backup) plus " : ""
      raise Backups::Error, "Not enough disk space: #{human_size(free)} free, #{needed}" \
                            "a #{human_size(min_free_disk_bytes)} reserve needed. #{disk_space_hint}"
    end

    # Directory dumps are tarred next to themselves, so they need twice the room.
    def expected_dump_bytes
      last = routine.runs.completed.where.not(size_bytes: nil).order(finished_at: :desc).pick(:size_bytes).to_i
      routine.format == "directory" ? last * 2 : last
    end

    def check_disk_space
      free = free_disk_bytes
      @disk_shortage = free if free && free < min_free_disk_bytes
    rescue
      # A failed probe must never break the dump.
    end

    def free_disk_bytes
      DiskSpace.free_bytes(workdir)
    end

    def min_free_disk_bytes
      Integer(ENV.fetch("VITAPG_MIN_FREE_DISK_MB", 1024)) * 1024**2
    end

    def disk_space_hint
      "Free up space, exclude large tables from the routine or lower VITAPG_MIN_FREE_DISK_MB."
    end

    def handle_stderr_line(line)
      @latest_line = line.delete_prefix("pg_dump: ")
      log_table_change(@latest_line)
    end

    # One history line per table so the log tells which data is being dumped.
    # Tables shorter than TABLE_LOG_INTERVAL are skipped (the live panel still
    # shows them) so thousands of tiny tables can't flood the log.
    def log_table_change(line)
      table = line[/\Adumping contents of table (.+)\z/, 1]
      return unless table
      return if table == @last_logged_table

      now = monotonic
      return if @last_table_logged_at && now - @last_table_logged_at < TABLE_LOG_INTERVAL

      @last_logged_table = table
      @last_table_logged_at = now
      run.log!(message: "Dumping table #{table}")
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
