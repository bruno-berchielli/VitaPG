require 'open3'

class DatabaseDumpService < ApplicationService
  attr_reader :backup_run, :routine, :connection, :filename, :filepath

  def initialize(backup_run, backup_routine)
    @backup_run = backup_run
    @routine = backup_routine
    @connection = backup_routine.database_connection

    @filename = "backup-#{connection.database_name}-#{backup_run.started_at.to_s.parameterize}.dump"
    @filepath = Rails.root.join("tmp", filename)
  end

  def call
    log_info("Starting DB dump for database: #{connection.database_name}")

    log_info("Executing command: #{dump_command.join(' ')}")

    ENV["PGPASSWORD"] = connection.password
    stdout, stderr, status = Open3.capture3(*dump_command)

    log_info("Command output:\n#{stdout}")
    log_error("Command error output:\n#{stderr}") if stderr.present?

    if status.success?
      log_info("Backup completed successfully")
      log_output(stdout)
      filepath
    else
      log_error("Backup failed with status #{status.exitstatus}")
      log_output(stderr)
      backup_run.update!(status: :failed, finished_at: Time.current)
      raise StandardError, "pg_dump failed: #{stderr}"
    end

  rescue => e
    log_error("Unexpected error: #{e.message}")
    backup_run.update!(status: :failed, finished_at: Time.current)
    raise e

  ensure
    ENV["PGPASSWORD"] = nil
  end

  private

  def dump_command
    cmd = [
      "pg_dump",
      "--host", connection.host,
      "--port", connection.port.to_s,
      "--username", connection.username,
      "--dbname", connection.database_name,
      "--file", filepath.to_s,
      "--format", "custom"
    ]

    cmd << "--no-owner" if routine.no_owner
    cmd << "--no-privileges" if routine.no_privileges

    routine.tables_to_exclude.split(',').each do |table|
      cmd << "--exclude-table=#{table.strip}"
    end

    routine.tables_to_exclude_data.split(',').each do |table|
      cmd << "--exclude-table-data=#{table.strip}"
    end

    cmd
  end
end
